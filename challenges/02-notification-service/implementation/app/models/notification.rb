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

  # Scopes
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_channel, ->(channel) { where(channel: channel) }
  scope :by_status, ->(status) { where(status: status) }
  scope :scheduled, -> { where.not(scheduled_at: nil) }

  # Public methods
  def update_status(new_status)
    self.status = new_status
    set_status_timestamp(new_status)
    save!
  end

  def can_retry?
    retry_count < max_retries
  end

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

  def set_status_timestamp(status)
    case status
    when 'sent'
      self.sent_at = Time.current
    when 'delivered'
      self.delivered_at = Time.current
    when 'failed'
      self.failed_at = Time.current
    end
  end
end
