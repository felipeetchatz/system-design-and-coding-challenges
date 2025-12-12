require "test_helper"

module ShortUrls
  class IncrementClickTest < ActiveSupport::TestCase
    test "increments click_count by 1" do
      url = "https://www.example.com/test"
      short_url = Create.call(url)
      initial_count = short_url.click_count

      IncrementClick.call(short_url)
      short_url.reload

      assert_equal initial_count + 1, short_url.click_count
    end

    test "updates last_accessed" do
      url = "https://www.example.com/test"
      short_url = Create.call(url)

      IncrementClick.call(short_url)
      short_url.reload

      assert_not_nil short_url.last_accessed
      assert_in_delta Time.current, short_url.last_accessed, 1.second
    end

    test "persists to database" do
      url = "https://www.example.com/test"
      short_url = Create.call(url)

      IncrementClick.call(short_url)

      reloaded_short_url = ShortUrl.find(short_url.id)
      assert_equal 1, reloaded_short_url.click_count
      assert_not_nil reloaded_short_url.last_accessed
    end

    test "sets last_accessed to current time" do
      url = "https://www.example.com/test"
      short_url = Create.call(url)

      before_time = Time.current
      IncrementClick.call(short_url)
      after_time = Time.current
      short_url.reload

      assert short_url.last_accessed >= before_time
      assert short_url.last_accessed <= after_time
    end

    test "updates timestamp on each call" do
      url = "https://www.example.com/test"
      short_url = Create.call(url)

      IncrementClick.call(short_url)
      first_access = short_url.reload.last_accessed

      sleep(0.1) # Small delay to ensure different timestamps

      IncrementClick.call(short_url)
      second_access = short_url.reload.last_accessed

      assert second_access > first_access
    end
  end
end
