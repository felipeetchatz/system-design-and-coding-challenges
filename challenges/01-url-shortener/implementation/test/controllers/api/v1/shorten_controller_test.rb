require "test_helper"

module Api
  module V1
    class ShortenControllerTest < ActionDispatch::IntegrationTest
      test "creates short URL successfully" do
        post api_v1_shorten_path, params: { url: "https://www.example.com/test" }

        assert_response :created
        json_response = JSON.parse(response.body)
        assert json_response["short_url"].present?
        assert_equal "https://www.example.com/test", json_response["original_url"]
        assert json_response["created_at"].present?
      end

      test "returns JSON with short_url, original_url, created_at" do
        post api_v1_shorten_path, params: { url: "https://www.example.com/test" }

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_includes json_response.keys, "short_url"
        assert_includes json_response.keys, "original_url"
        assert_includes json_response.keys, "created_at"
      end

      test "returns 400 for invalid URL" do
        post api_v1_shorten_path, params: { url: "not-a-valid-url" }

        assert_response :bad_request
        json_response = JSON.parse(response.body)
        assert_equal "Invalid URL", json_response["error"]
      end

      test "returns 400 for missing parameter" do
        post api_v1_shorten_path, params: {}

        assert_response :bad_request
        json_response = JSON.parse(response.body)
        assert_equal "URL parameter is required", json_response["error"]
      end
    end
  end
end
