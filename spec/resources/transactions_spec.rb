# frozen_string_literal: true

RSpec.describe PaystackSdk::Resources::Transactions do
  let(:secret_key) { "sk_test_xxx" }
  let(:connection) { instance_double(Faraday::Connection) }
  let(:transactions) { described_class.new(connection) }

  describe "#initiate" do
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

        response = transactions.initiate(params)

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

        response = transactions.initiate(params)

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be false
        expect(response.error_message).to eq("Invalid email address")
      end
    end

    context "with validation errors" do
      it "raises an error when email is missing" do
        invalid_params = {
          amount: 10000,
          currency: "GHS"
        }

        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::Error, /email/i
        )
      end

      it "raises an error when amount is missing" do
        invalid_params = {
          email: "customer@email.com",
          currency: "GHS"
        }

        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::Error, /amount/i
        )
      end

      it "raises an error when email format is invalid" do
        invalid_params = {
          email: "invalid-email",
          amount: 10000,
          currency: "GHS"
        }

        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::Error, /email format/i
        )
      end

      it "raises an error when amount is not a positive integer" do
        invalid_params = {
          email: "customer@email.com",
          amount: -100,
          currency: "GHS"
        }

        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::Error, /positive integer/i
        )
      end

      it "raises an error when currency format is invalid" do
        invalid_params = {
          email: "customer@email.com",
          amount: 10000,
          currency: "G"
        }

        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::Error, /3-letter ISO code/i
        )
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

    context "with validation errors" do
      it "raises an error when transaction_id is empty" do
        expect { transactions.fetch("") }.to raise_error(
          PaystackSdk::Error, /transaction id cannot be empty/i
        )
      end

      it "raises an error when transaction_id is nil" do
        expect { transactions.fetch(nil) }.to raise_error(
          PaystackSdk::Error, /transaction id cannot be empty/i
        )
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

    context "with validation errors" do
      it "raises an error when reference is empty" do
        expect { transactions.verify(reference: "") }.to raise_error(
          PaystackSdk::Error, /reference cannot be empty/i
        )
      end

      it "raises an error when reference is nil" do
        expect { transactions.verify(reference: nil) }.to raise_error(
          PaystackSdk::Error, /reference cannot be empty/i
        )
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

        allow(connection).to receive(:get).with("/transaction/totals", {}).and_return(faraday_response)

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

        allow(connection).to receive(:get).with("/transaction/totals", {}).and_return(faraday_response)

        response = transactions.totals

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be false
        expect(response.error_message).to eq("Invalid API key")
      end
    end

    context "with validation errors" do
      it "raises an error when date format is invalid" do
        expect { transactions.totals(from: "invalid-date") }.to raise_error(
          PaystackSdk::Error, /invalid from format/i
        )

        expect { transactions.totals(to: "invalid-date") }.to raise_error(
          PaystackSdk::Error, /invalid to format/i
        )
      end

      it "accepts valid date formats" do
        allow(connection).to receive(:get).with("/transaction/totals", {from: "2023-01-01"}).and_return(
          Faraday::Response.new(status: 200, body: {"status" => true, "message" => "Totals retrieved", "data" => {}})
        )

        expect { transactions.totals(from: "2023-01-01") }.not_to raise_error
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

    context "with validation errors" do
      it "raises an error when per_page is not a positive integer" do
        expect { transactions.list(per_page: -10) }.to raise_error(
          PaystackSdk::Error, /per_page must be a positive integer/i
        )
      end

      it "raises an error when page is not a positive integer" do
        expect { transactions.list(page: 0) }.to raise_error(
          PaystackSdk::Error, /page must be a positive integer/i
        )
      end

      it "raises an error when status is not valid" do
        expect { transactions.list(status: "invalid") }.to raise_error(
          PaystackSdk::Error, /status must be one of/i
        )
      end

      it "raises an error when date format is invalid" do
        expect { transactions.list(from: "not-a-date") }.to raise_error(
          PaystackSdk::Error, /invalid from format/i
        )
      end
    end
  end

  describe "#export" do
    context "with successful response" do
      it "exports transactions successfully" do
        response_body = {
          "status" => true,
          "message" => "Export successful",
          "data" => {
            "path" => "https://example.com/exports/file.csv",
            "expiresAt" => "2024-05-20 12:00:00"
          }
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)
        allow(connection).to receive(:get).with("/transaction/export", {}).and_return(faraday_response)

        response = transactions.export

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be true
        expect(response.api_message).to eq("Export successful")
        expect(response.data.path).to eq("https://example.com/exports/file.csv")
        expect(response.data.expiresAt).to eq("2024-05-20 12:00:00")
      end
    end

    context "with filters" do
      it "exports transactions with specified filters" do
        params = {
          from: "2023-01-01",
          to: "2023-12-31",
          status: "success",
          currency: "NGN"
        }

        response_body = {
          "status" => true,
          "message" => "Export successful",
          "data" => {
            "path" => "https://example.com/exports/filtered_file.csv",
            "expiresAt" => "2024-05-20 12:00:00"
          }
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)
        allow(connection).to receive(:get).with("/transaction/export", params).and_return(faraday_response)

        response = transactions.export(**params)

        expect(response.success?).to be true
        expect(response.data.path).to include("filtered_file.csv")
      end
    end

    context "with validation errors" do
      it "raises an error when status is invalid" do
        expect { transactions.export(status: "invalid") }.to raise_error(
          PaystackSdk::Error, /status must be one of/i
        )
      end

      it "raises an error when currency format is invalid" do
        expect { transactions.export(currency: "INVALID") }.to raise_error(
          PaystackSdk::Error, /currency must be a 3-letter ISO code/i
        )
      end

      it "raises an error when amount is not a positive integer" do
        expect { transactions.export(amount: "string") }.to raise_error(
          PaystackSdk::Error, /amount must be a positive integer/i
        )
      end
    end
  end

  describe "#charge_authorization" do
    let(:payload) do
      {
        authorization_code: "AUTH_72btv547",
        email: "customer@email.com",
        amount: 10000
      }
    end

    context "with successful response" do
      it "charges authorization successfully" do
        response_body = {
          "status" => true,
          "message" => "Charge attempted",
          "data" => {
            "amount" => 10000,
            "currency" => "NGN",
            "transaction_date" => "2024-05-15T13:45:12.000Z",
            "status" => "success",
            "reference" => "ref_12345",
            "domain" => "test",
            "authorization" => {
              "authorization_code" => "AUTH_72btv547",
              "bin" => "408408",
              "last4" => "4081",
              "exp_month" => "12",
              "exp_year" => "2025",
              "channel" => "card",
              "card_type" => "visa",
              "bank" => "TEST BANK",
              "country_code" => "NG",
              "brand" => "visa"
            },
            "customer" => {
              "id" => 123,
              "email" => "customer@email.com",
              "name" => "Test Customer"
            }
          }
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)
        allow(connection).to receive(:post).with("/transaction/charge_authorization", payload).and_return(faraday_response)

        response = transactions.charge_authorization(payload)

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be true
        expect(response.api_message).to eq("Charge attempted")
        expect(response.data.amount).to eq(10000)
        expect(response.data.reference).to eq("ref_12345")
        expect(response.data.authorization.authorization_code).to eq("AUTH_72btv547")
        expect(response.data.customer.email).to eq("customer@email.com")
      end
    end

    context "with missing required parameters" do
      it "raises an error when authorization_code is missing" do
        invalid_payload = {
          email: "customer@email.com",
          amount: 10000
        }

        expect { transactions.charge_authorization(invalid_payload) }.to raise_error(
          PaystackSdk::Error, /missing parameter\(s\): authorization_code/i
        )
      end

      it "raises an error when email is missing" do
        invalid_payload = {
          authorization_code: "AUTH_72btv547",
          amount: 10000
        }

        expect { transactions.charge_authorization(invalid_payload) }.to raise_error(
          PaystackSdk::Error, /missing parameter\(s\): email/i
        )
      end

      it "raises an error when amount is missing" do
        invalid_payload = {
          authorization_code: "AUTH_72btv547",
          email: "customer@email.com"
        }

        expect { transactions.charge_authorization(invalid_payload) }.to raise_error(
          PaystackSdk::Error, /missing parameter\(s\): amount/i
        )
      end
    end

    context "with validation errors" do
      it "raises an error when email format is invalid" do
        invalid_payload = {
          authorization_code: "AUTH_72btv547",
          email: "invalid-email",
          amount: 10000
        }

        expect { transactions.charge_authorization(invalid_payload) }.to raise_error(
          PaystackSdk::Error, /invalid email format/i
        )
      end

      it "raises an error when reference format is invalid" do
        invalid_payload = {
          authorization_code: "AUTH_72btv547",
          email: "customer@email.com",
          amount: 10000,
          reference: "invalid reference with spaces"
        }

        expect { transactions.charge_authorization(invalid_payload) }.to raise_error(
          PaystackSdk::Error, /reference can only contain/i
        )
      end
    end
  end

  describe "#partial_debit" do
    let(:payload) do
      {
        authorization_code: "AUTH_72btv547",
        currency: "NGN",
        amount: 5000,
        email: "customer@email.com"
      }
    end

    context "with successful response" do
      it "performs partial debit successfully" do
        response_body = {
          "status" => true,
          "message" => "Charge attempted",
          "data" => {
            "amount" => 5000,
            "currency" => "NGN",
            "transaction_date" => "2024-05-15T14:22:45.000Z",
            "status" => "success",
            "reference" => "ref_partial_12345",
            "domain" => "test",
            "authorization" => {
              "authorization_code" => "AUTH_72btv547",
              "bin" => "408408",
              "last4" => "4081",
              "exp_month" => "12",
              "exp_year" => "2025",
              "channel" => "card",
              "card_type" => "visa",
              "bank" => "TEST BANK",
              "country_code" => "NG",
              "brand" => "visa"
            },
            "customer" => {
              "id" => 123,
              "email" => "customer@email.com",
              "name" => "Test Customer"
            }
          }
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)
        allow(connection).to receive(:post).with("/transaction/partial_debit", payload).and_return(faraday_response)

        response = transactions.partial_debit(payload)

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be true
        expect(response.api_message).to eq("Charge attempted")
        expect(response.data.amount).to eq(5000)
        expect(response.data.currency).to eq("NGN")
        expect(response.data.reference).to eq("ref_partial_12345")
      end
    end

    context "with missing required parameters" do
      it "raises an error when authorization_code is missing" do
        invalid_payload = {
          currency: "NGN",
          amount: 5000,
          email: "customer@email.com"
        }

        expect { transactions.partial_debit(invalid_payload) }.to raise_error(
          PaystackSdk::Error, /missing parameter\(s\): authorization_code/i
        )
      end

      it "raises an error when currency is missing" do
        invalid_payload = {
          authorization_code: "AUTH_72btv547",
          amount: 5000,
          email: "customer@email.com"
        }

        expect { transactions.partial_debit(invalid_payload) }.to raise_error(
          PaystackSdk::Error, /missing parameter\(s\): currency/i
        )
      end
    end

    context "with validation errors" do
      it "raises an error when currency format is invalid" do
        invalid_payload = {
          authorization_code: "AUTH_72btv547",
          currency: "N",
          amount: 5000,
          email: "customer@email.com"
        }

        expect { transactions.partial_debit(invalid_payload) }.to raise_error(
          PaystackSdk::Error, /currency must be a 3-letter ISO code/i
        )
      end

      it "raises an error when amount is zero" do
        invalid_payload = {
          authorization_code: "AUTH_72btv547",
          currency: "NGN",
          amount: 0,
          email: "customer@email.com"
        }

        expect { transactions.partial_debit(invalid_payload) }.to raise_error(
          PaystackSdk::Error, /amount must be a positive integer/i
        )
      end
    end
  end

  describe "#timeline" do
    let(:transaction_id) { "12345" }

    context "with successful response" do
      it "retrieves transaction timeline successfully" do
        response_body = {
          "status" => true,
          "message" => "Timeline retrieved",
          "data" => {
            "history" => [
              {
                "type" => "action",
                "message" => "Initialized transaction",
                "time" => "2024-05-15T10:05:45.000Z"
              },
              {
                "type" => "action",
                "message" => "Customer authentication",
                "time" => "2024-05-15T10:06:12.000Z"
              },
              {
                "type" => "success",
                "message" => "Charge successful",
                "time" => "2024-05-15T10:06:30.000Z"
              }
            ],
            "transaction" => {
              "id" => transaction_id,
              "reference" => "ref_timeline_12345",
              "amount" => 10000,
              "currency" => "NGN",
              "status" => "success"
            }
          }
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)
        allow(connection).to receive(:get).with("/transaction/timeline/#{transaction_id}").and_return(faraday_response)

        response = transactions.timeline(transaction_id)

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be true
        expect(response.api_message).to eq("Timeline retrieved")
        expect(response.data.history.size).to eq(3)
        expect(response.data.history.last.type).to eq("success")
        expect(response.data.transaction.reference).to eq("ref_timeline_12345")
      end
    end

    context "with failed response" do
      it "returns a failed response when transaction not found" do
        response_body = {
          "status" => false,
          "message" => "Transaction not found"
        }

        faraday_response = Faraday::Response.new(status: 404, body: response_body)
        allow(connection).to receive(:get).with("/transaction/timeline/#{transaction_id}").and_return(faraday_response)

        response = transactions.timeline(transaction_id)

        expect(response).to be_a(PaystackSdk::Response)
        expect(response.success?).to be false
        expect(response.error_message).to eq("Transaction not found")
      end
    end

    context "with validation errors" do
      it "raises an error when id_or_reference is empty" do
        expect { transactions.timeline("") }.to raise_error(
          PaystackSdk::Error, /transaction id or reference cannot be empty/i
        )
      end

      it "raises an error when id_or_reference is nil" do
        expect { transactions.timeline(nil) }.to raise_error(
          PaystackSdk::Error, /transaction id or reference cannot be empty/i
        )
      end
    end
  end

  describe "validations module" do
    describe "#validate_email!" do
      it "accepts valid email formats" do
        expect {
          transactions.send(:validate_email!, email: "valid@example.com")
        }.not_to raise_error

        expect {
          transactions.send(:validate_email!, email: "valid+tag@sub.example.com")
        }.not_to raise_error
      end

      it "rejects invalid email formats" do
        expect {
          transactions.send(:validate_email!, email: "invalid")
        }.to raise_error(PaystackSdk::Error)

        expect {
          transactions.send(:validate_email!, email: "invalid@")
        }.to raise_error(PaystackSdk::Error)
      end
    end

    describe "#validate_reference_format!" do
      it "accepts valid reference formats" do
        expect {
          transactions.send(:validate_reference_format!, reference: "valid-ref")
        }.not_to raise_error

        expect {
          transactions.send(:validate_reference_format!, reference: "valid.ref=123")
        }.not_to raise_error
      end

      it "rejects invalid reference formats" do
        expect {
          transactions.send(:validate_reference_format!, reference: "invalid ref with spaces")
        }.to raise_error(PaystackSdk::Error)

        expect {
          transactions.send(:validate_reference_format!, reference: "invalid*char")
        }.to raise_error(PaystackSdk::Error)
      end
    end
  end
end
