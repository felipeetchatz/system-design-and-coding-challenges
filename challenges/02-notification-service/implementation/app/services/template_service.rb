class TemplateService
  CACHE_TTL = 24.hours.to_i

  def initialize(redis: nil)
    @redis = redis
  end

  def load(template_id)
    if redis
      key = cache_key(template_id)
      cached = redis.get(key)

      if cached
        attributes = JSON.parse(cached)
        return NotificationTemplate.new(attributes)
      end
    end

    template = NotificationTemplate.find_by!(template_id: template_id)

    if redis
      key = cache_key(template_id)
      redis.setex(key, CACHE_TTL, template.attributes.to_json)
    end

    template
  end

  def render(template_id, variables = {})
    template = load(template_id)
    template.render(variables)
  end

  private

  attr_reader :redis

  def cache_key(template_id)
    "template:#{template_id}"
  end
end


