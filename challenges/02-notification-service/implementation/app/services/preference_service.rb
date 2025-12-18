class PreferenceService
  def allowed?(user_id, channel, notification_type)
    preference = NotificationPreference
                  .for_user_and_channel(user_id, channel)
                  .find_by(notification_type: notification_type)

    return true unless preference

    preference.enabled?
  end
end


