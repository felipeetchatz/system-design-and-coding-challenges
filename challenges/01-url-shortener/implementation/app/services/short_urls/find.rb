module ShortUrls
  class Find
    CACHE_PREFIX = "short_url:"
    REGULAR_TTL = 1.hour
    POPULAR_TTL = 24.hours
    POPULAR_THRESHOLD = 100

    def self.call(short_code)
      new(short_code).call
    end

    def initialize(short_code)
      @short_code = short_code
    end

    def call
      return nil if @short_code.nil?
      return nil unless @short_code.match?(/\A[0-9a-zA-Z]{6}\z/)

      cache_key = "#{CACHE_PREFIX}#{@short_code}"

      # Cache-aside pattern: try cache first
      cached = Rails.cache.read(cache_key)
      return cached if cached

      # Cache miss: fetch from database
      short_url = ShortUrl.find_by(short_code: @short_code)
      return nil unless short_url

      # Determine TTL based on popularity
      ttl = short_url.click_count > POPULAR_THRESHOLD ? POPULAR_TTL : REGULAR_TTL

      # Write to cache
      Rails.cache.write(cache_key, short_url, expires_in: ttl)

      short_url
    end
  end
end



