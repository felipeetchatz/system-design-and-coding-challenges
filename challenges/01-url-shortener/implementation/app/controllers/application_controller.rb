class ApplicationController < ActionController::API
  private

  def request_ip
    request.remote_ip || request.ip
  end

  def request_user_agent
    request.user_agent
  end

  def extract_domain(url)
    return nil if url.blank?
    URI.parse(url).host rescue url[0..50] # Fallback se não conseguir parsear
  end
end
