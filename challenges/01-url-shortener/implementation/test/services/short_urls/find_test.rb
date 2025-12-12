require "test_helper"

module ShortUrls
  class FindTest < ActiveSupport::TestCase
    test "returns ShortUrl for valid code" do
      url = "https://www.example.com/test"
      created_short_url = Create.call(url)

      found_short_url = Find.call(created_short_url.short_code)

      assert_not_nil found_short_url
      assert_equal created_short_url.id, found_short_url.id
      assert_equal created_short_url.original_url, found_short_url.original_url
    end

    test "returns nil for non-existent code" do
      non_existent_code = "nonex1"

      result = Find.call(non_existent_code)

      assert_nil result
    end

    test "returns nil for invalid code" do
      invalid_code = "abc-12"

      result = Find.call(invalid_code)

      assert_nil result
    end
  end
end
