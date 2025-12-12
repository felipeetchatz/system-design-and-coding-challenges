module ShortUrls
  class IncrementClick
    def self.call(short_url)
      new(short_url).call
    end

    def initialize(short_url)
      @short_url = short_url
    end

    def call
      @short_url.increment!(:click_count)
      @short_url.update_column(:last_accessed, Time.current)
    end
  end
end
