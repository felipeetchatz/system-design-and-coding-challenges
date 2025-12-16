class Notification < ApplicationRecord
  # Validations
  validates :user_id, presence: true
  validates :channel, presence: true
  validates :template_id, presence: true
  validates :status, presence: true

  # Enums
  enum :status, {
    queued: 'queued',
    processing: 'processing',
    sent: 'sent',
    delivered: 'delivered',
    failed: 'failed',
    bounced: 'bounced'
  }

  enum :priority, {
    urgent: 'urgent',
    normal: 'normal',
    low: 'low'
  }

  enum :channel, {
    email: 'email',
    sms: 'sms',
    push: 'push',
    in_app: 'in_app'
  }

  # Default values (retry_count and max_retries are set in migration)
  # Set default status and priority before validation
  after_initialize :set_defaults, if: :new_record?

  # Generate unique notification_id before create
  before_create :generate_notification_id
  before_create :set_queued_at

  private

  def set_defaults
    self.status ||= 'queued'
    self.priority ||= 'normal'
  end

  def generate_notification_id
    self.notification_id ||= SecureRandom.uuid
  end

  def set_queued_at
    # queued_at é obrigatório, sempre definir na criação
    self.queued_at ||= Time.current
  end
end
