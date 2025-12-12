require "test_helper"

class UrlValidatorTest < ActiveSupport::TestCase
  test "valid? returns true for valid HTTP URLs" do
    assert UrlValidator.valid?("http://www.example.com")
    assert UrlValidator.valid?("http://example.com/path/to/page")
    assert UrlValidator.valid?("http://subdomain.example.com:8080/path?query=value")
  end

  test "valid? returns true for valid HTTPS URLs" do
    assert UrlValidator.valid?("https://www.example.com")
    assert UrlValidator.valid?("https://example.com/path/to/page")
    assert UrlValidator.valid?("https://subdomain.example.com:8080/path?query=value#fragment")
  end

  test "valid? returns false for invalid URLs" do
    assert_not UrlValidator.valid?("http://")
    assert_not UrlValidator.valid?("https://")
    assert_not UrlValidator.valid?("http://.com")
    assert_not UrlValidator.valid?("https://invalid..domain.com")
  end

  test "valid? returns false for non-URL strings" do
    assert_not UrlValidator.valid?("not a url")
    assert_not UrlValidator.valid?("just some text")
    assert_not UrlValidator.valid?("")
    assert_not UrlValidator.valid?(nil)
  end

  test "valid? returns false for FTP protocol" do
    assert_not UrlValidator.valid?("ftp://example.com/file.txt")
    assert_not UrlValidator.valid?("ftps://example.com/file.txt")
  end

  test "valid? returns false for other protocols" do
    assert_not UrlValidator.valid?("file:///path/to/file")
    assert_not UrlValidator.valid?("mailto:user@example.com")
    assert_not UrlValidator.valid?("tel:+1234567890")
    assert_not UrlValidator.valid?("javascript:alert('xss')")
  end

  test "valid? returns false for URLs without protocol" do
    assert_not UrlValidator.valid?("www.example.com")
    assert_not UrlValidator.valid?("example.com/path")
    assert_not UrlValidator.valid?("//example.com/path")
  end

  test "valid? returns false for URLs longer than 2048 characters" do
    # "https://example.com" = 19 characters
    # Need more than 2048 total, so path needs to be > 2029
    long_path = "/" + "a" * 2030
    long_url = "https://example.com#{long_path}"
    
    assert long_url.length > 2048
    assert_not UrlValidator.valid?(long_url)
  end

  test "valid? returns true for URLs up to 2048 characters" do
    # Exactly 2048 characters
    # "https://example.com" = 19 characters
    # Need 2048 - 19 = 2029 more characters
    long_path = "/" + "a" * 2028  # 1 (/) + 2028 (a's) + 19 (https://example.com) = 2048
    long_url = "https://example.com#{long_path}"
    
    assert_equal 2048, long_url.length
    assert UrlValidator.valid?(long_url)
    
    # Less than 2048 characters
    shorter_url = "https://example.com/path"
    assert shorter_url.length < 2048
    assert UrlValidator.valid?(shorter_url)
  end
end
