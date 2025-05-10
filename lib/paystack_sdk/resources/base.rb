module PaystackSdk
  module Resources
    # The `Base` class serves as a parent class for all resource classes in the SDK.
    # It provides shared functionality, such as handling API responses.
    class Base
      # Initializes a new `Base` instance.
      #
      # @param connection [Faraday::Connection] The Faraday connection object used for API requests.
      def initialize(connection)
        @connection = connection
      end

      # Checks if the last API response was successful.
      #
      # @return [Boolean] `true` if the last API response was successful, otherwise `false`.
      def success?
        @api_response&.success? || false
      end

      private

      # Handles the API response, raising an error if the response is unsuccessful.
      #
      # @param response [Faraday::Response] The response object returned by the Faraday connection.
      # @return [Hash] The parsed response body if the request was successful.
      # @raise [PaystackSdk::Error] If the response indicates an error.
      def handle_response(response)
        @api_response ||= response

        if response.success?
          response.body
        else
          error_message = response.body.is_a?(Hash) ? response.body["message"] : "Paystack API Error"
          raise PaystackSdk::Error, error_message
        end
      end
    end
  end
end
