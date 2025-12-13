require "test_helper"

class StructuredLoggerTest < ActiveSupport::TestCase
  setup do
    @original_env = Rails.env
    @original_json_logging = ENV['JSON_LOGGING']
    @logger_output = StringIO.new
    @logger = Logger.new(@logger_output)
    @original_logger = Rails.logger
    ENV.delete('JSON_LOGGING')
    Rails.logger = @logger
  end

  teardown do
    Rails.env = @original_env
    ENV['JSON_LOGGING'] = @original_json_logging
    Rails.logger = @original_logger
  end

  test "info logs with correct structure" do
    StructuredLogger.info(event_type: "test.event", key: "value")
    
    assert_match(/test\.event/, @logger_output.string)
    assert_match(/key/, @logger_output.string)
  end

  test "warn logs with correct level" do
    StructuredLogger.warn(event_type: "test.warning", message: "warning message")
    
    assert_match(/WARN/, @logger_output.string)
    assert_match(/test\.warning/, @logger_output.string)
  end

  test "error logs with correct level" do
    StructuredLogger.error(event_type: "test.error", error: "error message")
    
    assert_match(/ERROR/, @logger_output.string)
    assert_match(/test\.error/, @logger_output.string)
  end

  test "debug logs with correct level" do
    StructuredLogger.debug(event_type: "test.debug", data: "debug data")
    
    assert_match(/DEBUG/, @logger_output.string)
    assert_match(/test\.debug/, @logger_output.string)
  end

  test "includes timestamp in ISO 8601 format" do
    StructuredLogger.info(event_type: "test.timestamp")
    
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/, @logger_output.string)
  end

  test "includes event_type in log" do
    StructuredLogger.info(event_type: "url.created", short_code: "abc123")
    
    assert_match(/url\.created/, @logger_output.string)
  end

  test "sanitizes long URLs by truncating" do
    long_url = "https://example.com/" + "a" * 300
    StructuredLogger.info(event_type: "test.url", original_url: long_url)
    
    assert_match(/example\.com/, @logger_output.string)
    assert_no_match(/#{"a" * 300}/, @logger_output.string)
  end

  test "converts Time objects to ISO 8601" do
    time = Time.current
    StructuredLogger.info(event_type: "test.time", timestamp: time)
    
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/, @logger_output.string)
  end

  test "logs in JSON format in production" do
    Rails.env = ActiveSupport::StringInquirer.new("production")
    
    StructuredLogger.info(event_type: "test.json", key: "value")
    
    json_match = @logger_output.string.match(/\{.*\}/m)
    assert_not_nil json_match, "Output should contain JSON"
    
    parsed = JSON.parse(json_match[0])
    assert_equal "test.json", parsed["event_type"]
    assert_equal "value", parsed["key"]
    assert_equal "INFO", parsed["level"]
  end

  test "logs in human-readable format in development" do
    Rails.env = ActiveSupport::StringInquirer.new("development")
    
    StructuredLogger.info(event_type: "test.readable", key: "value")
    
    assert_match(/test\.readable/, @logger_output.string)
    assert_match(/key=/, @logger_output.string)
    assert_no_match(/^\s*\{/, @logger_output.string)
  end

  test "can force JSON logging with environment variable" do
    Rails.env = ActiveSupport::StringInquirer.new("development")
    ENV['JSON_LOGGING'] = 'true'
    
    StructuredLogger.info(event_type: "test.forced_json", key: "value")
    
    json_match = @logger_output.string.match(/\{.*\}/m)
    assert_not_nil json_match, "Output should contain JSON when JSON_LOGGING=true"
    
    parsed = JSON.parse(json_match[0])
    assert_equal "test.forced_json", parsed["event_type"]
  end

  test "handles multiple data fields" do
    StructuredLogger.info(
      event_type: "test.multiple",
      short_code: "abc123",
      original_url: "https://example.com",
      click_count: 42
    )
    
    output = @logger_output.string
    assert_match(/test\.multiple/, output)
    assert_match(/abc123/, output)
    assert_match(/example\.com/, output)
  end

  test "handles nil values gracefully" do
    StructuredLogger.info(event_type: "test.nil", value: nil)
    
    assert_match(/test\.nil/, @logger_output.string)
  end
end