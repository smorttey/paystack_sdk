# frozen_string_literal: true

require_relative "base"

module PaystackSdk
  module Resources
    # The `Transactions` class provides methods for interacting with the Paystack Transactions API.
    # It allows you to initialize transactions, verify payments, list transactions, and fetch transaction details.
    class Transactions < PaystackSdk::Resources::Base
      # Initializes a new transaction.
      #
      # @param payload [Hash] The payload containing transaction details (e.g., email, amount, currency).
      # @return [Hash] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the payload is invalid or the API request fails.
      #
      # @example
      #   payload = { email: "customer@email.com", amount: 10000, currency: "GHS" }
      #   response = transactions.initialize_transaction(payload)
      def initialize_transaction(payload)
        raise PaystackSdk::Error, "Invalid payload" unless payload.is_a?(Hash)
        response = @connection.post("/transaction/initialize", payload)
        handle_response(response)
      end

      # Verifies a transaction using its reference.
      #
      # @param reference [String] The unique reference for the transaction.
      # @return [Hash] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #   response = transactions.verify("transaction_reference")
      def verify(reference:)
        response = @connection.get("/transaction/verify/#{reference}")
        handle_response(response)
      end

      # Lists all transactions.
      #
      # @return [Hash] The response from the Paystack API containing a list of transactions.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #   response = transactions.list
      def list
        response = @connection.get("/transaction")
        handle_response(response)
      end

      # Fetches details of a single transaction by its ID.
      #
      # @param id [Integer] The ID of the transaction to fetch.
      # @return [Hash] The response from the Paystack API containing transaction details.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #   response = transactions.fetch("transaction_id")
      def fetch(id)
        response = @connection.get("/transaction/#{id}")
        handle_response(response)
      end

      # Fetches the totals of all transactions.
      #
      # @return [Hash] The response from the Paystack API containing transaction totals.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #  response = transactions.totals
      def totals
        response = @connection.get("/transaction/totals")
        handle_response(response)
      end
    end
  end
end
