class RedirectsController < ApplicationController
  def show
    short_url = ShortUrls::Find.call(params[:short_code])

    if short_url.nil?
      render json: { error: "Short URL not found" }, status: :not_found
      return
    end

    ShortUrls::IncrementClick.call(short_url)

    redirect_to short_url.original_url, status: :found
  end
end
