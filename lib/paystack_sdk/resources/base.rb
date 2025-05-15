# frozen_string_literal: true

require_relative "../response"
require_relative "../client"
require_relative "../validations"

module PaystackSdk
  module Resources
    # The `Base` class serves as a parent class for all resource classes in the SDK.
    # It provides shared functionality, such as handling API responses.
    class Base
      # Include validation methods
      include PaystackSdk::Validations

      # Initializes a new `Base` instance.
      #
      # @param connection [Faraday::Connection, nil] The Faraday connection object used for API requests.
      #   If nil, a new connection will be created using the default API key.
      # @param secret_key [String, nil] Optional API key to use for creating a new connection.
      #   Only used if connection is nil.
      #
      # @example With an existing connection
      #   connection = Faraday.new(...)
      #   resource = PaystackSdk::Resources::SomeResource.new(connection)
      #
      # @example With an API key
      #   resource = PaystackSdk::Resources::SomeResource.new(secret_key: "sk_test_xxx")
      #
      # @example With default connection (requires PAYSTACK_SECRET_KEY environment variable)
      #   resource = PaystackSdk::Resources::SomeResource.new
      def initialize(connection = nil, secret_key: nil)
        @connection = if connection
          connection
        elsif secret_key
          create_connection(secret_key:)
        else
          # Try to get API key from environment variable
          env_secret_key = ENV["PAYSTACK_SECRET_KEY"]
          raise PaystackSdk::Error, "No connection or API key provided" unless env_secret_key

          create_connection(secret_key: env_secret_key)
        end
      end

      private

      # Creates a new Faraday connection with the Paystack API.
      #
      # @param secret_key [String] The secret API key for authenticating with the Paystack API.
      # @return [Faraday::Connection] A configured Faraday connection.
      def create_connection(secret_key:)
        Faraday.new(url: PaystackSdk::Client::BASE_URL) do |conn|
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.headers["Authorization"] = "Bearer #{secret_key}"
          conn.headers["Content-Type"] = "application/json"
          conn.headers["User-Agent"] = "paystack_sdk/#{PaystackSdk::VERSION}"
          conn.adapter Faraday.default_adapter
        end
      end

      # Handles the API response, wrapping it in a Response object.
      #
      # @param response [Faraday::Response] The response object returned by the Faraday connection.
      # @return [PaystackSdk::Response] The parsed response body wrapped in a `PaystackSdk::Response` object.
      # @raise [PaystackSdk::Error] If the response indicates an error.
      def handle_response(response)
        PaystackSdk::Response.new(response)
      end
    end
  end
end
