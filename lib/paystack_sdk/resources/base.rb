# frozen_string_literal: true

require_relative "../response"

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

      private

      # Handles the API response, raising an error if the response is unsuccessful.
      #
      # @param response [Faraday::Response] The response object returned by the Faraday connection.
      # @return [PaystackSdk::Response] The parsed response body wrapped in a `PaystackSdk::Response` object if the request was successful.
      # @raise [PaystackSdk::Error] If the response indicates an error.
      def handle_response(response)
        PaystackSdk::Response.new(response)
      end
    end
  end
end
