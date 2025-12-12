class UrlValidator
  MAX_URL_LENGTH = 2048

  def self.valid?(url)
    return false if url.nil? || url.empty?
    return false if url.length > MAX_URL_LENGTH

    uri = URI.parse(url)
    return false unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    
    # Must have a valid host
    host = uri.host
    return false if host.nil? || host.empty?
    
    # Additional host validation: reject invalid patterns
    return false if host.start_with?(".") # Starts with dot
    return false if host.include?("..") # Contains double dots
    return false if host.end_with?(".") # Ends with dot
    
    true
  rescue URI::InvalidURIError, ArgumentError
    false
  end
end
