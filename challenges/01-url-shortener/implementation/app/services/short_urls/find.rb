module ShortUrls
  class Find
    def self.call(short_code)
      new(short_code).call
    end

    def initialize(short_code)
      @short_code = short_code
    end

    def call
      return nil if @short_code.nil?
      return nil unless @short_code.match?(/\A[0-9a-zA-Z]{6}\z/)

      ShortUrl.find_by(short_code: @short_code)
    end
  end
end
