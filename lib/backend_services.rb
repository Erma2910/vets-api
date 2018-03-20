# frozen_string_literal: true

class BackendServices
  def self.all
    constants.map do |const|
      val = const_get const
      next unless val.is_a?(String)
      val
    end.compact
  end

  GI_BILL_STATUS = 'gibs'

  FACILITIES = 'facilities'
  HCA = 'hca'
  EDUCATION_BENEFITS = 'edu-benefits'
  EVSS_CLAIMS = 'evss-claims'
  APPEALS_STATUS = 'appeals-status'
  USER_PROFILE = 'user-profile'
  ID_CARD = 'id-card'
  IDENTITY_PROOFED = 'identity-proofed'

  # MHV services
  RX = 'rx'
  MESSAGING = 'messaging'
  HEALTH_RECORDS = 'health-records'
  MHV_BASED_SERVICES = [RX, MESSAGING, HEALTH_RECORDS].freeze

  # Core Form Features
  SAVE_IN_PROGRESS = 'form-save-in-progress'
  FORM_PREFILL = 'form-prefill'
end
