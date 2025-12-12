require "test_helper"

module ShortUrls
  class IncrementClickTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::TimeHelpers

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
  end
end
