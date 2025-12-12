class ShortUrlService
    class InvalidUrlError < StandardError; end
  
    def self.create(original_url)
      raise InvalidUrlError, "Invalid URL" unless UrlValidator.valid?(original_url)
  
      short_code = ShortCodeGenerator.generate
      
      ShortUrl.create!(
        short_code: short_code,
        original_url: original_url,
        click_count: 0
      )
    end
end