class NotificationValidator
  VALID_CHANNELS = %w[email sms push in_app].freeze

  ValidationResult = Struct.new(:valid?, :errors) do
    def initialize(valid:, errors: [])
      super(valid, errors)
    end
  end

  def validate(attributes)
    errors = []

    validate_user_id(attributes[:user_id], errors)
    validate_template_id(attributes[:template_id], errors)
    validate_channel(attributes[:channel], errors)
    validate_variables(attributes[:variables], errors) if attributes.key?(:variables)

    ValidationResult.new(valid: errors.empty?, errors: errors)
  end

  private

  def validate_user_id(user_id, errors)
    if user_id.nil? || user_id.to_s.strip.empty?
      errors << "user_id can't be blank"
    end
  end

  def validate_template_id(template_id, errors)
    if template_id.nil? || template_id.to_s.strip.empty?
      errors << "template_id can't be blank"
    end
  end

  def validate_channel(channel, errors)
    if channel.nil? || channel.to_s.strip.empty?
      errors << "channel can't be blank"
    elsif !VALID_CHANNELS.include?(channel.to_s)
      errors << 'channel must be one of: email, sms, push, in_app'
    end
  end

  def validate_variables(variables, errors)
    return if variables.nil?

    unless variables.is_a?(Hash)
      errors << 'variables must be a hash'
    end
  end
end

