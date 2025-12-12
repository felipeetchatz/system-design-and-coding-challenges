class ShortUrl < ApplicationRecord
    validates :short_code, presence: true,
                           length: { is: 6 },
                           uniqueness: true,
                           format: { with: /\A[0-9a-zA-Z]{6}\z/, message: "must contain only Base62 characters (0-9, a-z, A-Z)" }
    
    validates :original_url, presence: true,
                             format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be HTTP or HTTPS" }
end