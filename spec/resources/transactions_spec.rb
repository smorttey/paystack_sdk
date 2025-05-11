# frozen_string_literal: true

RSpec.describe PaystackSdk::Resources::Transactions do
  let(:api_key) { "sk_test_xxx" }
  let(:connection) { instance_double(Faraday::Connection) }
  let(:transactions) { described_class.new(connection) }

  describe "#initialize_transaction" do
    let(:params) do
      {
        email: "customer@email.com",
        amount: 10000,
        currency: "GHS"
      }
    end

    context "with successful response" do
      it "initializes a transaction successfully" do
        response_body = {
          "status" => true,
          "message" => "Authorization URL created",
          "data" => {
            "authorization_url" => "https://paystack.com/transaction/123",
            "access_code" => "access_code_123",
            "reference" => "ref_123"
          }
        }

        # Create a proper Faraday response
        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        # Mock connection to return the Faraday response
        allow(connection).to receive(:post).with("/transaction/initialize", params).and_return(faraday_response)

        response = transactions.initialize_transaction(params)

        # Test the response wrapper
        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be true
        expect(response.api_message).to eq("Authorization URL created")

        # Test the dynamic method generation
        expect(response.data).to respond_to(:authorization_url)
        expect(response.data).to respond_to(:access_code)
        expect(response.data).to respond_to(:reference)

        # Test the actual values
        expect(response.data.authorization_url).to eq("https://paystack.com/transaction/123")
        expect(response.data.access_code).to eq("access_code_123")
        expect(response.data.reference).to eq("ref_123")
      end
    end

    context "with failed response" do
      it "returns a failed response with error message" do
        response_body = {
          "status" => false,
          "message" => "Invalid email address"
        }

        # Create a failed Faraday response
        faraday_response = Faraday::Response.new(status: 400, body: response_body)

        allow(connection).to receive(:post).with("/transaction/initialize", params).and_return(faraday_response)

        response = transactions.initialize_transaction(params)

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be false
        expect(response.error_message).to eq("Invalid email address")
      end
    end
  end

  describe "#fetch" do
    let(:transaction_id) { "12345" }

    context "with successful response" do
      it "fetches a transaction successfully" do
        response_body = {
          "status" => true,
          "message" => "Transaction retrieved",
          "data" => {
            "id" => transaction_id,
            "amount" => 10000,
            "currency" => "GHS",
            "customer" => {
              "email" => "customer@email.com",
              "name" => "John Doe"
            }
          }
        }

        # Create a proper Faraday response
        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        allow(connection).to receive(:get).with("/transaction/#{transaction_id}").and_return(faraday_response)

        response = transactions.fetch(transaction_id)

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be true
        expect(response.api_message).to eq("Transaction retrieved")

        # Test data access
        expect(response.data.id).to eq(transaction_id)
        expect(response.data.amount).to eq(10000)
        expect(response.data.currency).to eq("GHS")

        # Test nested data access
        expect(response.data.customer.email).to eq("customer@email.com")
        expect(response.data.customer.name).to eq("John Doe")
      end
    end

    context "with failed response" do
      it "returns a failed response when transaction not found" do
        response_body = {
          "status" => false,
          "message" => "Transaction not found"
        }

        # Create a failed Faraday response
        faraday_response = Faraday::Response.new(status: 404, body: response_body)

        allow(connection).to receive(:get).with("/transaction/#{transaction_id}").and_return(faraday_response)

        response = transactions.fetch(transaction_id)

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be false
        expect(response.error_message).to eq("Transaction not found")
      end
    end
  end

  describe "#verify" do
    let(:transaction_reference) { "txn_ref_12345" }

    context "with successful response" do
      it "verifies a transaction successfully" do
        response_body = {
          "status" => true,
          "message" => "Verification successful",
          "data" => {
            "reference" => transaction_reference,
            "status" => "success",
            "amount" => 10000,
            "customer" => {
              "id" => 123,
              "email" => "customer@email.com"
            }
          }
        }

        # Create a proper Faraday response
        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        allow(connection).to receive(:get).with("/transaction/verify/#{transaction_reference}").and_return(faraday_response)

        response = transactions.verify(reference: transaction_reference)

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be true
        expect(response.api_message).to eq("Verification successful")

        expect(response.data.reference).to eq(transaction_reference)
        expect(response.data.status).to eq("success")
        expect(response.data.amount).to eq(10000)

        expect(response.data.customer.id).to eq(123)
        expect(response.data.customer.email).to eq("customer@email.com")
      end
    end

    context "with failed response" do
      it "returns a failed response when reference not found" do
        response_body = {
          "status" => false,
          "message" => "Transaction reference not found"
        }

        # Create a failed Faraday response
        faraday_response = Faraday::Response.new(status: 404, body: response_body)

        allow(connection).to receive(:get).with("/transaction/verify/#{transaction_reference}").and_return(faraday_response)

        response = transactions.verify(reference: transaction_reference)

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be false
        expect(response.error_message).to eq("Transaction reference not found")
      end
    end
  end

  describe "#totals" do
    context "with successful response" do
      it "retrieves transaction totals successfully" do
        response_body = {
          "status" => true,
          "message" => "Totals retrieved",
          "data" => {
            "total_transactions" => 100,
            "total_volume" => 500000,
            "pending_transfers" => 20000
          }
        }

        # Create a proper Faraday response
        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        allow(connection).to receive(:get).with("/transaction/totals").and_return(faraday_response)

        response = transactions.totals

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be true
        expect(response.api_message).to eq("Totals retrieved")

        expect(response.data.total_transactions).to eq(100)
        expect(response.data.total_volume).to eq(500000)
        expect(response.data.pending_transfers).to eq(20000)
      end
    end

    context "with failed response" do
      it "returns a failed response when authentication fails" do
        response_body = {
          "status" => false,
          "message" => "Invalid API key"
        }

        # Create a failed Faraday response
        faraday_response = Faraday::Response.new(status: 401, body: response_body)

        allow(connection).to receive(:get).with("/transaction/totals").and_return(faraday_response)

        response = transactions.totals

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be false
        expect(response.error_message).to eq("Invalid API key")
      end
    end
  end

  describe "#list" do
    context "with successful response" do
      it "lists transactions successfully" do
        response_body = {
          "status" => true,
          "message" => "Transactions retrieved",
          "data" => [
            {
              "id" => "txn_1",
              "reference" => "ref_1",
              "amount" => 10000,
              "currency" => "GHS"
            },
            {
              "id" => "txn_2",
              "reference" => "ref_2",
              "amount" => 20000,
              "currency" => "GHS"
            }
          ],
          "meta" => {
            "total" => 2,
            "page" => 1
          }
        }

        # Create a proper Faraday response
        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        allow(connection).to receive(:get).with("/transaction", {perPage: 50, page: 1}).and_return(faraday_response)

        response = transactions.list

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be true
        expect(response.api_message).to eq("Transactions retrieved")

        expect(response.data.size).to eq(2)
        expect(response.data.first.id).to eq("txn_1")
        expect(response.data.last.amount).to eq(20000)

        expect(response.original_response.dig("meta", "total")).to eq(2)
        expect(response.original_response.dig("meta", "page")).to eq(1)
      end
    end

    context "with empty response" do
      it "handles empty transaction list" do
        response_body = {
          "status" => true,
          "message" => "No transactions found",
          "data" => [],
          "meta" => {
            "total" => 0,
            "page" => 1
          }
        }

        # Create a proper Faraday response
        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        allow(connection).to receive(:get).with("/transaction", {perPage: 50, page: 1}).and_return(faraday_response)

        response = transactions.list

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be true
        expect(response.api_message).to eq("No transactions found")
        expect(response.data).to be_empty
        expect(response.data.size).to eq(0)
      end
    end
  end
end
