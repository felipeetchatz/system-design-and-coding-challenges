class RedirectsController < ApplicationController
  def show
    start_time = Time.current
    short_code = params[:short_code]
    
    short_url = ShortUrls::Find.call(short_code)

    if short_url.nil?
      StructuredLogger.warn(
        event_type: "redirect.not_found",
        short_code: short_code,
        ip_address: request_ip,
        user_agent: request_user_agent
      )
      render json: { error: "Short URL not found" }, status: :not_found
      return
    end

    # Save original_url and click_count before IncrementClick
    original_url = short_url.original_url
    click_count_before = short_url.click_count
    
    ShortUrls::IncrementClick.call(short_url)
    
    # Reload to get updated click_count
    short_url.reload
    click_count_after = short_url.click_count
    response_time_ms = ((Time.current - start_time) * 1000).round(2)

    StructuredLogger.info(
      event_type: "redirect.success",
      short_code: short_code,
      original_url_domain: extract_domain(original_url),
      click_count_before: click_count_before,
      click_count_after: click_count_after,
      ip_address: request_ip,
      user_agent: request_user_agent,
      response_time_ms: response_time_ms
    )

    redirect_to original_url, status: :found, allow_other_host: true
  end
end
