# frozen_string_literal: true

require_relative "resources/transactions"

module PaystackSdk
  # The `Client` class serves as the main entry point for interacting with the Paystack API.
  # It initializes a connection to the Paystack API and provides access to various resources.
  class Client
    # The base URL for the Paystack API.
    BASE_URL = "https://api.paystack.co"

    # Initializes a new `Client` instance.
    #
    # @param api_key [String] The secret API key for authenticating with the Paystack API.
    #
    # @example
    #   client = PaystackSdk::Client.new(api_key: "sk_test_xxx")
    def initialize(api_key:)
      @connection = Faraday.new(url: BASE_URL) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.headers["Authorization"] = "Bearer #{api_key}"
        conn.headers["Content-Type"] = "application/json"
        conn.headers["User-Agent"] = "paystack_sdk/#{PaystackSdk::VERSION}"
        conn.adapter Faraday.default_adapter
      end
    end

    # Provides access to the `Transactions` resource.
    #
    # @return [PaystackSdk::Resources::Transactions] An instance of the
    #  `Transactions` resource.
    #
    # @example
    #   transactions = client.transactions
    #   response = transactions.initialize_transaction(params)
    def transactions
      @transactions ||= Resources::Transactions.new(@connection)
    end
  end
end
