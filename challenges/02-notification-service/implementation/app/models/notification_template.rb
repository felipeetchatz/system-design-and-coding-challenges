class NotificationTemplate < ApplicationRecord
  # Validations
  validates :template_id, presence: true, uniqueness: true
  validates :channel, presence: true
  validates :body, presence: true

  # Scopes
  scope :active, -> { where(active: true) }

  # Public methods
  def render(variables = {})
    required_vars = extract_required_variables
    missing_vars = required_vars - variables.keys.map(&:to_s)

    if missing_vars.any?
      error_message = if missing_vars.size == 1
        "Missing required variable: #{missing_vars.first}"
      else
        "Missing required variables: #{missing_vars.join(', ')}"
      end
      raise ArgumentError, error_message
    end

    result = body.dup
    variables.each do |key, value|
      result.gsub!(/\{\{#{key}\}\}/, value.to_s)
    end
    result
  end

  private

  def extract_required_variables
    body.scan(/\{\{(\w+)\}\}/).flatten.uniq
  end
end

