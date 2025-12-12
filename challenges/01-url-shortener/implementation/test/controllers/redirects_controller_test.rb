require "test_helper"

class RedirectsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  test "redirects to original_url with 302" do
    url = "https://www.example.com/test"
    short_url = ShortUrls::Create.call(url)

    get "/#{short_url.short_code}"

    assert_response :found
    assert_redirected_to url
  end

  test "returns 404 for non-existent code" do
    get "/nonex1"

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Short URL not found", json_response["error"]
  end

  test "increments click_count" do
    url = "https://www.example.com/test"
    short_url = ShortUrls::Create.call(url)
    initial_count = short_url.click_count

    get "/#{short_url.short_code}"

    short_url.reload
    assert_equal initial_count + 1, short_url.click_count
  end

  test "updates last_accessed" do
    freeze_time do
      url = "https://www.example.com/test"
      short_url = ShortUrls::Create.call(url)

      get "/#{short_url.short_code}"

      short_url.reload
      assert_equal Time.current, short_url.last_accessed
    end
  end
end
