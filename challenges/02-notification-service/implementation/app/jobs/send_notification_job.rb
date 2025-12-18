class SendNotificationJob
  include Sidekiq::Job

  TERMINAL_STATUSES = %w[sent delivered failed bounced].freeze

  def perform(notification_id)
    notification = Notification.find_by(notification_id: notification_id)
    return unless notification

    return if TERMINAL_STATUSES.include?(notification.status)

    notification.update!(status: :processing)

    Rails.logger.info("SendNotificationJob started for notification #{notification.notification_id}")
  rescue StandardError => e
    Rails.logger.error("SendNotificationJob error for notification #{notification_id}: #{e.message}")
  end
end


