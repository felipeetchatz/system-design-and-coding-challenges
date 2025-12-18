class PreferenceService
  CACHE_TTL = 1.hour.to_i

  def initialize(redis: nil)
    @redis = redis
  end

  def allowed?(user_id, channel, notification_type)
     if redis
      key = cache_key(user_id, channel, notification_type)
      cached = redis.get(key)
      return cached == 'true' if cached
    end

    preference = NotificationPreference
                 .for_user_and_channel(user_id, channel)
                 .find_by(notification_type: notification_type)

    allowed = preference ? preference.enabled? : true

    redis&.setex(key, CACHE_TTL, allowed.to_s)

    allowed
  end

  def invalidate_cache(user_id, channel, notification_type)
    return unless redis

    redis.del(cache_key(user_id, channel, notification_type))
  end

  private

  attr_reader :redis

  def cache_key(user_id, channel, notification_type)
    "pref:#{user_id}:#{channel}:#{notification_type}"
  end
end

