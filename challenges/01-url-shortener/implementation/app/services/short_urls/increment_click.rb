module ShortUrls
  class IncrementClick
    CACHE_PREFIX = "short_url:"
    REGULAR_TTL = 1.hour
    POPULAR_TTL = 24.hours
    POPULAR_THRESHOLD = 100

    def self.call(short_url)
      new(short_url).call
    end

    def initialize(short_url)
      @short_url = short_url
    end

    def call
      @short_url.increment!(:click_count)
      @short_url.update_column(:last_accessed, Time.current)

      # Update cache with fresh data and correct TTL
      cache_key = "#{CACHE_PREFIX}#{@short_url.short_code}"
      ttl = @short_url.click_count > POPULAR_THRESHOLD ? POPULAR_TTL : REGULAR_TTL
      Rails.cache.write(cache_key, @short_url.reload, expires_in: ttl)
    end
  end
end
