# frozen_string_literal: true

FactoryBot.define do
  factory :code_container, class: 'SignIn::CodeContainer' do
    code_challenge { Base64.urlsafe_encode64(SecureRandom.hex) }
    code { SecureRandom.hex }
    user_verification_id { create(:user_verification).id }
  end
end
