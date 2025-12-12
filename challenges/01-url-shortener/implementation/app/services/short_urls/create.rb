module ShortUrls
  class Create
    class InvalidUrlError < StandardError; end

    def self.call(original_url)
      new(original_url).call
    end

    def initialize(original_url)
      @original_url = original_url
    end

    def call
      raise InvalidUrlError, "Invalid URL" unless UrlValidator.valid?(@original_url)

      short_code = ShortCodeGenerator.generate

      ShortUrl.create!(
        short_code: short_code,
        original_url: @original_url,
        click_count: 0
      )
    end
  end
end
