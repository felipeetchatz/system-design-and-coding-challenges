module Api
  module V1
    class ShortenController < ApplicationController
      def create
        url = params[:url]

        if url.blank?
          render json: { error: "URL parameter is required" }, status: :bad_request
          return
        end

        short_url = ShortUrls::Create.call(url)

        render json: {
          short_url: short_url_url(short_url.short_code),
          original_url: short_url.original_url,
          created_at: short_url.created_at
        }, status: :created
      rescue ShortUrls::Create::InvalidUrlError
        render json: { error: "Invalid URL" }, status: :bad_request
      end

      private

      def short_url_url(short_code)
        "#{request.base_url}/#{short_code}"
      end
    end
  end
end
