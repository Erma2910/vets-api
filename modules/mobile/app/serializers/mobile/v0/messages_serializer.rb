# frozen_string_literal: true

module Mobile
  module V0
    class MessagesSerializer < ActiveModel::Serializer
      attribute :id

      attribute(:message_id) { object.id }
      attribute :category
      attribute :subject
      attribute :body
      attribute :attachment
      attribute :sent_date
      attribute :sender_id
      attribute :sender_name
      attribute :recipient_id
      attribute :recipient_name
      attribute :read_receipt
      attribute :triage_group_name
      attribute :proxy_sender_name

      link(:self) { Mobile::UrlHelper.new.v0_message_url(object.id) }
    end
  end
end
