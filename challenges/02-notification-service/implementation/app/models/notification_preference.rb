class NotificationPreference < ApplicationRecord
  # Validations
  validates :user_id, presence: true
  validates :channel, presence: true
  validates :notification_type, presence: true
  validates :notification_type, uniqueness: { scope: [:user_id, :channel] }

  # Scopes
  scope :for_user_and_channel, ->(user_id, channel) { where(user_id: user_id, channel: channel) }

  # Public methods
  def enabled?
    return false unless enabled

    # If quiet hours are not fully configured, consider enabled
    return true unless quiet_hours_start && quiet_hours_end && timezone

    # Get current time in user's timezone
    user_time = current_time_in_timezone

    # Return false if within quiet hours, true otherwise
    !within_quiet_hours?(user_time)
  end

  private

  def current_time_in_timezone
    time_zone = ActiveSupport::TimeZone[timezone]
    return Time.current unless time_zone

    Time.current.in_time_zone(time_zone)
  end

  def within_quiet_hours?(user_time)
    start_time = quiet_hours_start
    end_time = quiet_hours_end

    # Extract time components (hour and minute)
    current_hour = user_time.hour
    current_minute = user_time.min
    current_time_of_day = current_hour * 60 + current_minute # minutes since midnight

    # quiet_hours_start and quiet_hours_end are Time objects with only time component
    # Extract hour and minute from them
    start_hour = start_time.hour
    start_minute = start_time.min
    start_time_of_day = start_hour * 60 + start_minute

    end_hour = end_time.hour
    end_minute = end_time.min
    end_time_of_day = end_hour * 60 + end_minute

    # Handle quiet hours that span midnight (e.g., 22:00 - 08:00)
    if start_time_of_day > end_time_of_day
      # Quiet hours span midnight (e.g., 22:00 - 08:00)
      # Current time is within quiet hours if:
      # - It's >= start_time (e.g., >= 22:00) OR
      # - It's < end_time (e.g., < 08:00)
      current_time_of_day >= start_time_of_day || current_time_of_day < end_time_of_day
    else
      # Quiet hours within same day (e.g., 14:00 - 16:00)
      # Current time is within quiet hours if:
      # - It's >= start_time AND < end_time
      current_time_of_day >= start_time_of_day && current_time_of_day < end_time_of_day
    end
  end
end

