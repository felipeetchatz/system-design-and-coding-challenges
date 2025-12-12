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

  def self.find_by_code(short_code)
    return nil if short_code.nil?
    return nil unless short_code.match?(/\A[0-9a-zA-Z]{6}\z/)

    ShortUrl.find_by(short_code: short_code)
  end
end