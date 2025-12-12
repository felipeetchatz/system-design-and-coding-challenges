require "test_helper"

class ShortUrlTest < ActiveSupport::TestCase
  test "can be created with short_code and original_url" do
    short_url = ShortUrl.new(
      short_code: "abc123",
      original_url: "https://www.example.com/test"
    )

    assert short_url.valid?
    assert short_url.save
  end

  test "requires short_code" do
    short_url = ShortUrl.new(original_url: "https://www.example.com/test")

    assert_not short_url.valid?
    assert_includes short_url.errors[:short_code], "can't be blank"
  end

  test "requires original_url" do
    short_url = ShortUrl.new(short_code: "abc123")

    assert_not short_url.valid?
    assert_includes short_url.errors[:original_url], "can't be blank"
  end

  test "initializes click_count to 0 by default" do
    short_url = ShortUrl.create!(
      short_code: "abc123",
      original_url: "https://www.example.com/test"
    )

    assert_equal 0, short_url.click_count
  end

  test "allows last_accessed to be nil" do
    short_url = ShortUrl.create!(
      short_code: "abc123",
      original_url: "https://www.example.com/test"
    )

    assert_nil short_url.last_accessed
  end

  test "short_code must have exactly 6 characters" do
    short_url = ShortUrl.new(
      short_code: "abc12",  # 5 characters
      original_url: "https://www.example.com/test"
    )

    assert_not short_url.valid?
    assert_includes short_url.errors[:short_code], "is the wrong length (should be 6 characters)"
  end

  test "short_code must be unique" do
    ShortUrl.create!(
      short_code: "abc123",
      original_url: "https://www.example.com/test1"
    )

    duplicate = ShortUrl.new(
      short_code: "abc123",
      original_url: "https://www.example.com/test2"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:short_code], "has already been taken"
  end

  test "short_code must use only Base62 characters" do
    short_url = ShortUrl.new(
      short_code: "abc-12",  # Contains invalid character '-'
      original_url: "https://www.example.com/test"
    )

    assert_not short_url.valid?
    assert_includes short_url.errors[:short_code], "must contain only Base62 characters (0-9, a-z, A-Z)"
  end

  test "original_url must be a valid URL" do
    short_url = ShortUrl.new(
      short_code: "abc123",
      original_url: "not-a-valid-url"
    )

    assert_not short_url.valid?
    assert_includes short_url.errors[:original_url], "must be HTTP or HTTPS"
  end

  test "original_url must be HTTP or HTTPS" do
    short_url = ShortUrl.new(
      short_code: "abc123",
      original_url: "ftp://example.com/file"
    )

    assert_not short_url.valid?
    assert_includes short_url.errors[:original_url], "must be HTTP or HTTPS"
  end
end
