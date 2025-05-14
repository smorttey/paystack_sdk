# frozen_string_literal: true

require_relative "base"

module PaystackSdk
  module Resources
    # The `Transactions` class provides methods for interacting with the Paystack
    #  Transactions API.
    # It allows you to initialize transactions, verify payments, list transactions, and fetch transaction details.
    # The Transactions class provides methods to interact with the Paystack API for managing transactions.
    # It includes functionalities for initializing, verifying, listing, fetching, and retrieving transaction totals.
    #
    # Example usage:
    # ```ruby
    #   transactions = PaystackSdk::Resources::Transactions.new(secret_key:)
    #
    #   # Initialize a transaction
    #   payload = { email: "customer@email.com", amount: 10000, currency: "GHS" }
    #   response = transactions.initialize_transaction(payload)
    #   if response.success?
    #     puts "Transaction initialized successfully."
    #     puts "Authorization URL: #{response.data.authorization_url}"
    #   else
    #     puts "Error initializing transaction: #{response.error_message}"
    #   end
    #
    #   # Verify a transaction
    #   response = transactions.verify(reference: "transaction_reference")
    #
    #   # List transactions
    #   response = transactions.list(per_page: 50, page: 1)
    #
    #   # Fetch a single transaction
    #   response = transactions.fetch(transaction_id: 12345)
    #
    #   # Get transaction totals
    #   response = transactions.totals
    # ```
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
      def initiate(payload)
        raise PaystackSdk::Error, "Payload must be a hash" unless payload.is_a?(Hash)
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
      # @param per_page [Integer] Number of records per page (default: 50)
      # @param page [Integer] Page number to retrieve (default: 1)
      # @return [PaystackSdk::Response] The response from the Paystack API containing a
      # list of transactions.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #   response = transactions.list(per_page: 20, page: 2)
      def list(per_page: 50, page: 1, **params)
        response = @connection.get("/transaction", {perPage: per_page, page: page}.merge(params))
        handle_response(response)
      end

      # Fetches details of a single transaction by its ID.
      #
      # @param transaction_id [Integer] The ID of the transaction to fetch.
      # @return [Hash] The response from the Paystack API containing transaction details.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #   response = transactions.fetch("transaction_id")
      def fetch(transaction_id)
        response = @connection.get("/transaction/#{transaction_id}")
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
