require "test_helper"

class ShortUrlServiceTest < ActiveSupport::TestCase
  test "creates and persists a valid ShortUrl" do
    url = "https://www.example.com/test"
    short_url = ShortUrlService.create(url)

    assert short_url.persisted?
    assert short_url.valid?
    assert_equal url, short_url.original_url
  end

  test "generates a unique short_code" do
    url = "https://www.example.com/test"
    short_url = ShortUrlService.create(url)

    assert_not_nil short_url.short_code
    assert_equal 6, short_url.short_code.length
  end

  test "saves original_url correctly" do
    url = "https://www.example.com/path/to/page"
    short_url = ShortUrlService.create(url)

    assert_equal url, short_url.original_url
  end

  test "initializes click_count as 0" do
    url = "https://www.example.com/test"
    short_url = ShortUrlService.create(url)

    assert_equal 0, short_url.click_count
  end

  test "generates short_code using Base62 format" do
    url = "https://www.example.com/test"
    
    short_url = ShortUrlService.create(url)
    
    assert_not_nil short_url.short_code
    assert_equal 6, short_url.short_code.length
    assert_match(/^[0-9a-zA-Z]{6}$/, short_url.short_code)
  end

  test "generates unique codes for different URLs" do
    url1 = "https://www.example.com/test1"
    url2 = "https://www.example.com/test2"
    
    short_url1 = ShortUrlService.create(url1)
    short_url2 = ShortUrlService.create(url2)
    
    assert_not_equal short_url1.short_code, short_url2.short_code
  end

  test "generates exactly 6-character codes" do
    url = "https://www.example.com/test"
    short_url = ShortUrlService.create(url)

    assert_equal 6, short_url.short_code.length
  end

  test "accepts valid URLs" do
    valid_url = "https://www.example.com/test"
    
    short_url = ShortUrlService.create(valid_url)
    assert short_url.persisted?
  end

  test "raises InvalidUrlError for invalid URL" do
    invalid_url = "not-a-valid-url"
    
    assert_raises(ShortUrlService::InvalidUrlError) do
      ShortUrlService.create(invalid_url)
    end
  end

  test "raises InvalidUrlError for URL exceeding maximum length" do
    long_url = "https://example.com/" + "a" * 2040
    
    assert long_url.length > 2048
    assert_raises(ShortUrlService::InvalidUrlError) do
      ShortUrlService.create(long_url)
    end
  end

  test "find_by_code returns ShortUrl for valid code" do
    url = "https://www.example.com/test"
    created_short_url = ShortUrlService.create(url)
    
    found_short_url = ShortUrlService.find_by_code(created_short_url.short_code)
    
    assert_not_nil found_short_url
    assert_equal created_short_url.id, found_short_url.id
    assert_equal created_short_url.original_url, found_short_url.original_url
  end

  test "find_by_code returns nil for non-existent code" do
    non_existent_code = "nonex1"
    
    result = ShortUrlService.find_by_code(non_existent_code)
    
    assert_nil result
  end

  test "find_by_code returns nil for invalid code" do
    invalid_code = "abc-12"
    
    result = ShortUrlService.find_by_code(invalid_code)
    
    assert_nil result
  end
end
