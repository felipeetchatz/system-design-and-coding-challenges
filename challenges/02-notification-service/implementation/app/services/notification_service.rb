class NotificationService
  class ValidationError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super("Invalid notification attributes: #{errors.join(', ')}")
    end
  end

  def initialize(validator: NotificationValidator.new)
    @validator = validator
  end

  def create(attributes)
    validation_result = @validator.validate(attributes)

    unless validation_result.valid?
      raise ValidationError.new(validation_result.errors)
    end

    Notification.create!(
      user_id: attributes[:user_id],
      channel: attributes[:channel],
      template_id: attributes[:template_id],
      variables: attributes[:variables],
      priority: attributes[:priority],
      scheduled_at: attributes[:scheduled_at]
    )
  end

  private

  attr_reader :validator
end


