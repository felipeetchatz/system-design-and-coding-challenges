module Api
  module V1
    class AnalyticsController < ApplicationController
      def show
        short_code = params[:short_code]
        short_url = ShortUrls::Find.call(short_code)

        if short_url.nil?
          StructuredLogger.warn(
            event_type: "analytics.not_found",
            short_code: short_code,
            ip_address: request_ip
          )
          render json: { error: "Short URL not found" }, status: :not_found
          return
        end

        StructuredLogger.info(
          event_type: "analytics.queried",
          short_code: short_code,
          ip_address: request_ip
        )

        render json: {
          short_code: short_url.short_code,
          original_url: short_url.original_url,
          click_count: short_url.click_count,
          created_at: short_url.created_at,
          last_accessed: short_url.last_accessed
        }
      end
    end
  end
end
