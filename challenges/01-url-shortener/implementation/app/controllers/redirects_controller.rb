class RedirectsController < ApplicationController
  def show
    short_url = ShortUrls::Find.call(params[:short_code])

    if short_url.nil?
      render json: { error: "Short URL not found" }, status: :not_found
      return
    end

    # Save original_url before IncrementClick (object may be from cache)
    original_url = short_url.original_url
    
    ShortUrls::IncrementClick.call(short_url)

    redirect_to original_url, status: :found, allow_other_host: true
  end
end
