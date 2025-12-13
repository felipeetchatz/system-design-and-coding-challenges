class StructuredLogger
  MAX_URL_LENGTH = 200

  def self.info(**data)
    log(:info, **data)
  end

  def self.warn(**data)
    log(:warn, **data)
  end

  def self.error(**data)
    log(:error, **data)
  end

  def self.debug(**data)
    log(:debug, **data)
  end

  private

  def self.log(level, **data)
    raise ArgumentError, "event_type is required" unless data.key?(:event_type)
    
    log_data = prepare_log_data(level, **data)
    
    if use_json_format?
      Rails.logger.public_send(level, log_data.to_json)
    else
      Rails.logger.public_send(level, format_human_readable(log_data))
    end
  rescue JSON::GeneratorError => e
    Rails.logger.error("Failed to serialize log data: #{e.message}")
    Rails.logger.public_send(level, format_human_readable(log_data))
  end

  def self.prepare_log_data(level, **data)
    {
      timestamp: Time.current.utc.iso8601(3),
      level: level.to_s.upcase,
      **sanitize_data(data)
    }
  end

  def self.sanitize_data(data)
    # Filter sensitive parameters using Rails' filter_parameters
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered_data = filter.filter(data)
    
    filtered_data.transform_values do |value|
      case value
      when Time, ActiveSupport::TimeWithZone
        value.utc.iso8601(3)
      when String
        sanitize_string(value)
      else
        value
      end
    end
  end

  def self.sanitize_string(str)
    return str if str.nil?
    return str if str.length <= MAX_URL_LENGTH
    
    # Truncate long URLs/strings
    str[0, MAX_URL_LENGTH] + "..."
  end

  def self.format_human_readable(data)
    parts = []
    parts << "[#{data[:timestamp]}]"
    parts << "[#{data[:level]}]"
    parts << "event_type=#{data[:event_type]}"
    
    data.except(:timestamp, :level, :event_type).each do |key, value|
      parts << "#{key}=#{value}"
    end
    
    parts.join(" ")
  end

  def self.use_json_format?
    Rails.env.production? || ENV['JSON_LOGGING'] == 'true'
  end
end