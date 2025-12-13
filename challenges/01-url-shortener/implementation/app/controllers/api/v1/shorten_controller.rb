module Api
  module V1
    class ShortenController < ApplicationController
      def create
        url = params[:url]

        if url.blank?
          StructuredLogger.warn(
            event_type: "shorten.validation_error",
            error_reason: "missing_param",
            url_domain: extract_domain(url),
            ip_address: request_ip
          )
          render json: { error: "URL parameter is required" }, status: :bad_request
          return
        end

        short_url = ShortUrls::Create.call(url)

        StructuredLogger.info(
          event_type: "shorten.created",
          short_code: short_url.short_code,
          original_url_domain: extract_domain(short_url.original_url),
          ip_address: request_ip
        )

        render json: {
          short_url: short_url_url(short_url.short_code),
          original_url: short_url.original_url,
          created_at: short_url.created_at
        }, status: :created
      rescue ShortUrls::Create::InvalidUrlError => e
        StructuredLogger.warn(
          event_type: "shorten.validation_error",
          error_reason: "invalid_url",
          url_domain: extract_domain(url),
          ip_address: request_ip
        )
        render json: { error: "Invalid URL" }, status: :bad_request
      end

      private

      def short_url_url(short_code)
        "#{request.base_url}/#{short_code}"
      end
    end
  end
end
