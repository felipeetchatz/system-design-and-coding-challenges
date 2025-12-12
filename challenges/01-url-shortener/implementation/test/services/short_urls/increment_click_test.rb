require "test_helper"

module ShortUrls
  class IncrementClickTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::TimeHelpers

    setup do
      Rails.cache.clear
    end

    test "increments click_count by 1" do
      url = "https://www.example.com/test"
      short_url = Create.call(url)
      initial_count = short_url.click_count

      IncrementClick.call(short_url)
      short_url.reload

      assert_equal initial_count + 1, short_url.click_count
    end

    test "updates last_accessed" do
      freeze_time do
        url = "https://www.example.com/test"
        short_url = Create.call(url)

        IncrementClick.call(short_url)
        short_url.reload

        assert_not_nil short_url.last_accessed
        assert_equal Time.current, short_url.last_accessed
      end
    end

    test "persists to database" do
      freeze_time do
        url = "https://www.example.com/test"
        short_url = Create.call(url)

        IncrementClick.call(short_url)

        reloaded_short_url = ShortUrl.find(short_url.id)
        assert_equal 1, reloaded_short_url.click_count
        assert_equal Time.current, reloaded_short_url.last_accessed
      end
    end

    test "sets last_accessed to current time" do
      freeze_time do
        url = "https://www.example.com/test"
        short_url = Create.call(url)

        IncrementClick.call(short_url)
        short_url.reload

        assert_equal Time.current, short_url.last_accessed
      end
    end

    test "updates timestamp on each call" do
      url = "https://www.example.com/test"
      short_url = Create.call(url)

      first_access = nil
      freeze_time do
        IncrementClick.call(short_url)
        first_access = short_url.reload.last_accessed
        assert_equal Time.current, first_access
      end

      travel 1.second do
        IncrementClick.call(short_url)
        second_access = short_url.reload.last_accessed
        assert_equal Time.current, second_access
        assert second_access > first_access
      end
    end

    test "updates cache after incrementing click_count" do
      url = "https://www.example.com/test"
      short_url = Create.call(url)
      cache_key = "short_url:#{short_url.short_code}"

      # Ensure cache is empty before test
      Rails.cache.delete(cache_key)

      # Populate cache
      result = Find.call(short_url.short_code)
      assert_not_nil result, "Find.call should return a ShortUrl"
      
      # Verify cache was written
      cached_before = Rails.cache.read(cache_key)
      assert_not_nil cached_before, "Cached object should not be nil after Find.call"
      assert_equal 0, cached_before.click_count

      # Increment click count
      IncrementClick.call(short_url)

      # Cache should be updated with fresh data
      cached_after = Rails.cache.read(cache_key)
      assert_not_nil cached_after, "Cached object should not be nil after increment"
      assert_equal 1, cached_after.click_count
    end

    test "updates cache when click_count crosses threshold" do
      url = "https://www.example.com/test"
      short_url = Create.call(url)
      short_url.update_column(:click_count, 99)
      cache_key = "short_url:#{short_url.short_code}"

      # Ensure cache is empty before test
      Rails.cache.delete(cache_key)

      # Populate cache
      Find.call(short_url.short_code)
      assert Rails.cache.exist?(cache_key), "Cache should exist after Find.call"

      # Increment to cross threshold (99 -> 100)
      IncrementClick.call(short_url)

      # Cache should be updated with fresh data and new TTL
      assert Rails.cache.exist?(cache_key), "Cache should still exist after increment"
      cached_after = Rails.cache.read(cache_key)
      assert_not_nil cached_after, "Cached object should not be nil"
      assert_equal 100, cached_after.click_count
    end
  end
end
