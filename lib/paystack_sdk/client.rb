# frozen_string_literal: true

require_relative "resources/transactions"
require_relative "utils/connection_utils"

module PaystackSdk
  # The `Client` class serves as the main entry point for interacting with the Paystack API.
  # It initializes a connection to the Paystack API and provides access to various resources.
  class Client
    # Include connection utilities
    include Utils::ConnectionUtils

    # @return [Faraday::Connection] The Faraday connection object used for API requests
    attr_reader :connection

    # Initializes a new `Client` instance.
    #
    # @param connection [Faraday::Connection, nil] The Faraday connection object used for API requests.
    #   If nil, a new connection will be created using the default API key.
    # @param secret_key [String, nil] Optional API key to use for creating a new connection.
    #   Only used if connection is nil.
    #
    # @example With an existing connection
    #   connection = Faraday.new(...)
    #   client = PaystackSdk::Client.new(connection)
    #
    # @example With an API key
    #   client = PaystackSdk::Client.new(secret_key: "sk_test_xxx")
    #
    # @example With default connection (requires PAYSTACK_SECRET_KEY environment variable)
    #   client = PaystackSdk::Client.new
    def initialize(connection = nil, secret_key: nil)
      @connection = initialize_connection(connection, secret_key: secret_key)
    end

    # Provides access to the `Transactions` resource.
    #
    # @return [PaystackSdk::Resources::Transactions] An instance of the
    #  `Transactions` resource.
    #
    # @example
    # ```ruby
    #   transactions = client.transactions
    #   response = transactions.initiate(params)
    # ```
    def transactions
      @transactions ||= Resources::Transactions.new(@connection)
    end
  end
end
