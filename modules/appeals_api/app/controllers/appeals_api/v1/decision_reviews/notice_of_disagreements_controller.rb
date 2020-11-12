# frozen_string_literal: true

require 'appeals_api/form_schemas'

class AppealsApi::V1::DecisionReviews::NoticeOfDisagreementsController < AppealsApi::ApplicationController
  include AppealsApi::JsonFormatValidation

  FORM_NUMBER = '10182'

  skip_before_action(:authenticate)
  before_action :validate_json_format, if: -> { request.post? }
  before_action :new_notice_of_disagreement, only: %i[create validate]

  HEADERS = JSON.parse(
    File.read(
      AppealsApi::Engine.root.join('config/schemas/10182_headers.json')
    )
  )['definitions']['nodCreateHeadersRoot']['properties'].keys

  def create
    if @notice_of_disagreement.save
      AppealsApi::NoticeOfDisagreementPdfSubmitJob.perform_async(@notice_of_disagreement.id)
      render_notice_of_disagreement
    else
      render_model_errors
    end
  end

  def validate
    if @notice_of_disagreement.valid?
      render json: {
        data: {
          type: 'noticeOfDisagreementValidation',
          attributes: { status: 'valid' }
        }
      }
    else
      render_model_errors
    end
  end

  def schema
    render json: AppealsApi::JsonSchemaToSwaggerConverter.remove_comments(
      AppealsApi::FormSchemas.new.schema(self.class::FORM_NUMBER)
    )
  end

  private

  def headers
    HEADERS.reduce({}) do |hash, key|
      hash.merge(key => request.headers[key])
    end.compact
  end

  def new_notice_of_disagreement
    @notice_of_disagreement = AppealsApi::NoticeOfDisagreement.new(auth_headers: headers, form_data: @json_body)
  end

  def render_model_errors
    errors = @notice_of_disagreement.errors.to_a.map { |error| { status: 422, detail: error } }
    render json: { errors: errors }, status: 422
  end

  def render_notice_of_disagreement
    render json: AppealsApi::NoticeOfDisagreementSerializer.new(@notice_of_disagreement).serializable_hash
  end
end
