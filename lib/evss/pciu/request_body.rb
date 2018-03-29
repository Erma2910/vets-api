# frozen_string_literal: true

module EVSS
  module PCIU
    class RequestBody
      attr_reader :request_attrs, :pciu_key, :date_attr

      def initialize(request_attrs, pciu_key:, date_attr: 'effective_date')
        @request_attrs = request_attrs
        @pciu_key = pciu_key
        @date_attr = date_attr
      end

      def set
        set_effective_date
        remove_empty_attrs
        convert_to_json
      end

      private

      def set_effective_date
        request_attrs.tap { |instance| instance[date_attr] = DateTime.now.utc }
      end

      def remove_empty_attrs
        request_attrs.tap { |instance| instance.as_json.delete_if { |_k, v| v.blank? } }
      end

      def convert_to_json
        {
          pciu_key => Hash[
            request_attrs.as_json.map { |k, v| [k.camelize(:lower), v] }
          ]
        }.to_json
      end
    end
  end
end
