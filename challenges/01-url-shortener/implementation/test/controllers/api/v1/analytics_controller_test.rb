require "test_helper"

module Api
  module V1
    class AnalyticsControllerTest < ActionDispatch::IntegrationTest
      include ActiveSupport::Testing::TimeHelpers

      setup do
        Rails.cache.clear
      end

      test "returns analytics data" do
        freeze_time do
          url = "https://www.example.com/test"
          short_url = ShortUrls::Create.call(url)
          
          # Reload from database to ensure fresh data
          short_url.reload
          
          # Clear cache to ensure we get fresh data from database
          Rails.cache.clear
          
          # Ensure the specific cache key is deleted
          cache_key = "short_url:#{short_url.short_code}"
          Rails.cache.delete(cache_key)

          get api_v1_analytics_path(short_url.short_code)

          assert_response :success
          json_response = JSON.parse(response.body)
          
          # Reload from database to verify actual state
          short_url.reload
          
          assert_equal short_url.short_code, json_response["short_code"]
          assert_equal url, json_response["original_url"]
          assert_equal 0, short_url.click_count, "Database click_count should be 0"
          assert_equal 0, json_response["click_count"], "click_count should be 0 for a newly created URL"
          assert_equal short_url.click_count, json_response["click_count"], "API response should match database state"
          assert json_response["created_at"].present?
          assert_nil json_response["last_accessed"]
        end
      end

      test "returns 404 for non-existent code" do
        get api_v1_analytics_path("nonex1")

        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert_equal "Short URL not found", json_response["error"]
      end

      test "returns null for last_accessed if never accessed" do
        freeze_time do
          url = "https://www.example.com/test"
          short_url = ShortUrls::Create.call(url)
          short_url.reload

          get api_v1_analytics_path(short_url.short_code)

          assert_response :success
          json_response = JSON.parse(response.body)
          assert_nil json_response["last_accessed"]
        end
      end
    end
  end
end
