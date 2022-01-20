# frozen_string_literal: true

require 'lgy/aws_uploader'
require 'lgy/configuration'
require 'common/client/base'

module LGY
  class Service < Common::Client::Base
    include Common::Client::Concerns::Monitoring
    include SentryLogging
    configuration LGY::Configuration
    STATSD_KEY_PREFIX = 'api.lgy'
    SENTRY_TAG = { team: 'vfs-ebenefits' }.freeze

    def initialize(edipi:, icn:)
      @edipi = edipi
      @icn = icn
    end

    def coe_status
      if get_determination.body['status'] == 'ELIGIBLE' && get_application.status == 404
        'eligible'
      elsif get_determination.body['status'] == 'UNABLE_TO_DETERMINE_AUTOMATICALLY' && get_application.status == 404
        'unable-to-determine-eligibility'
      elsif get_determination.body['status'] == 'ELIGIBLE' && get_application.status == 200
        'available'
      elsif get_determination.body['status'] == 'NOT_ELIGIBLE'
        'ineligible'
      elsif get_determination.body['status'] == 'PENDING' && get_application.status == 404
        # need confirmation from LGY on this
        'pending'
      elsif get_determination.body['status'] == 'PENDING' && get_application.body['status'] == 'SUBMITTED'
        'pending'
      elsif get_determination.body['status'] == 'PENDING' && get_application.body['status'] == 'RETURNED'
        'pending-upload'
      end
    end

    def get_determination
      @get_determination ||= with_monitoring do
        perform(
          :get,
          "#{end_point}/determination",
          { 'edipi' => @edipi, 'icn' => @icn },
          request_headers
        )
      end
    end

    def get_application
      @get_application ||= with_monitoring do
        perform(
          :get,
          "#{end_point}/application",
          { 'edipi' => @edipi, 'icn' => @icn },
          request_headers
        )
      end
    rescue Common::Client::Errors::ClientError => e
      # if the Veteran is automatically approved, LGY will return a 404 (no application exists)
      return e if e.status == 404

      raise e
    end

    def get_coe_file
      with_monitoring do
        perform(
          :get,
          "#{end_point}/documents/coe/file",
          { 'edipi' => @edipi, 'icn' => @icn },
          request_headers.merge(pdf_headers)
        )
      end
    rescue Common::Client::Errors::ClientError => e
      # a 404 is expected if no COE is available
      return e if e.status == 404

      raise e
    end

    def coe_url
      response = get_coe_file
      # return if 404

      folder = 'tmp/lgy_coe'
      FileUtils.mkdir_p(folder)
      filename = "#{folder}/#{DateTime.now.strftime('%Q')}.pdf"
      File.open(filename, 'wb') do |f|
        f.write(response.body)
      end

      coe_url = LGY::AwsUploader.get_s3_link(filename)
      File.delete(filename)

      coe_url
    end

    def request_headers
      {
        Authorization: "api-key { \"appId\":\"#{Settings.lgy.app_id}\", \"apiKey\": \"#{Settings.lgy.api_key}\"}"
      }
    end

    def pdf_headers
      {
        'Accept' => 'application/octet-stream', 'Content-Type' => 'application/octet-stream'
      }
    end

    private

    def end_point
      "#{Settings.lgy.base_url}/eligibility-manager/api/eligibility"
    end
  end
end
