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
      before do
        allow(connection).to receive(:post)
          .with("/transaction/initialize", params)
          .and_return(Faraday::Response.new(status: 200, body: {
            "status" => true,
            "message" => "Authorization URL created",
            "data" => {
              "authorization_url" => "https://checkout.paystack.com/abc123",
              "access_code" => "access_code_123",
              "reference" => "ref_123"
            }
          }))
      end

      it "initializes a transaction" do
        response = transactions.initiate(params)
        expect(response.success?).to be true

        expect(response.data.authorization_url).to eq("https://checkout.paystack.com/abc123")
        expect(response.authorization_url).to eq("https://checkout.paystack.com/abc123")
      end
    end

    context "with failed response" do
      before do
        allow(connection).to receive(:post)
          .with("/transaction/initialize", params)
          .and_return(Faraday::Response.new(status: 400, body: {
            "status" => false,
            "message" => "Transaction initialization failed"
          }))
      end

      it "raises an APIError" do
        expect { transactions.initiate(params) }.to raise_error(PaystackSdk::APIError)
      end
    end

    context "with validation errors" do
      it "raises MissingParamError when email is missing" do
        invalid_params = params.except(:email)
        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: email"
        )
      end

      it "raises MissingParamError when amount is missing" do
        invalid_params = params.except(:amount)
        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: amount"
        )
      end

      it "raises InvalidFormatError when email format is invalid" do
        invalid_params = params.merge(email: "invalid-email")
        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::InvalidFormatError,
          "Invalid format for Email. Expected format: valid email address"
        )
      end

      it "raises InvalidFormatError when currency format is invalid" do
        invalid_params = params.merge(currency: "INVALID")
        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::InvalidFormatError,
          "Invalid format for currency. Expected format: 3-letter ISO code (e.g., NGN, USD, GHS)"
        )
      end
    end
  end

  describe "#verify" do
    let(:reference) { "ref_123" }

    context "with successful response" do
      before do
        allow(connection).to receive(:get)
          .with("/transaction/verify/#{reference}")
          .and_return(Faraday::Response.new(status: 200, body: {
            "status" => true,
            "message" => "Transaction verified",
            "data" => {
              "reference" => reference,
              "status" => true,
              "amount" => 10000
            }
          }))
      end

      it "verifies a transaction" do
        response = transactions.verify(reference: reference)
        expect(response.success?).to be true
        expect(response.status).to be true
      end
    end

    context "with not found error" do
      before do
        allow(connection).to receive(:get)
          .with("/transaction/verify/#{reference}")
          .and_return(Faraday::Response.new(status: 404, body: {
            "status" => false,
            "message" => "Transaction reference not found.",
            "meta" => {
              "nextStep" => "Ensure that you're passing the reference of a transaction that exists on this integration"
            },
            "type" => "validation_error",
            "code" => "transaction_not_found"
          }))
      end

      it "raises ResourceNotFoundError" do
        expect { transactions.verify(reference: reference) }.to raise_error(
          PaystackSdk::ResourceNotFoundError,
          /Transaction reference not found/
        )
      end
    end

    context "with validation errors" do
      it "raises MissingParamError when reference is missing" do
        expect { transactions.verify(reference: nil) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: Reference"
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
      before do
        allow(connection).to receive(:post)
          .with("/transaction/charge_authorization", payload)
          .and_return(Faraday::Response.new(status: 200, body: {
            "status" => true,
            "message" => "Charge attempted",
            "data" => {
              "amount" => 35247,
              "currency" => "NGN",
              "transaction_date" => "2024-08-22T10:53:49.000Z",
              "status" => "success",
              "reference" => "0m7frfnr47ezyxl",
              "domain" => "test",
              "metadata" => "",
              "gateway_response" => "Approved",
              "message" => nil,
              "channel" => "card",
              "ip_address" => nil,
              "log" => nil,
              "fees" => 10247,
              "authorization" => {
                "authorization_code" => "AUTH_uh8bcl3zbn",
                "bin" => "408408",
                "last4" => "4081",
                "exp_month" => "12",
                "exp_year" => "2030",
                "channel" => "card",
                "card_type" => "visa ",
                "bank" => "TEST BANK",
                "country_code" => "NG",
                "brand" => "visa",
                "reusable" => true,
                "signature" => "SIG_yEXu7dLBeqG0kU7g95Ke",
                "account_name" => nil
              },
              "customer" => {
                "id" => 181873746,
                "first_name" => nil,
                "last_name" => nil,
                "email" => "customer@email.com",
                "customer_code" => "CUS_1rkzaqsv4rrhqo6",
                "phone" => nil,
                "metadata" => {
                  "custom_fields" => [
                    {
                      "display_name" => "Customer email",
                      "variable_name" => "customer_email",
                      "value" => "new@email.com"
                    }
                  ]
                },
                "risk_action" => "default",
                "international_format_phone" => nil
              },
              "plan" => nil,
              "id" => 4099490251
            }
          }))
      end

      it "charges the authorization" do
        response = transactions.charge_authorization(payload)

        expect(response.success?).to be true
        expect(response.status).to be "success"
        expect(response.api_message).to eq("Charge attempted")
        expect(response.amount).to eq(35247)
        expect(response.reference).to eq("0m7frfnr47ezyxl")
        expect(response.authorization.authorization_code).to eq("AUTH_uh8bcl3zbn")
        expect(response.customer.email).to eq("customer@email.com")
      end
    end

    context "with validation errors" do
      it "raises MissingParamError when authorization_code is missing" do
        invalid_payload = payload.except(:authorization_code)
        expect { transactions.charge_authorization(invalid_payload) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: authorization_code"
        )
      end

      it "raises MissingParamError when email is missing" do
        invalid_payload = payload.except(:email)
        expect { transactions.charge_authorization(invalid_payload) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: email"
        )
      end

      it "raises MissingParamError when amount is missing" do
        invalid_payload = payload.except(:amount)
        expect { transactions.charge_authorization(invalid_payload) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: amount"
        )
      end
    end
  end

  describe "#partial_debit" do
    let(:payload) do
      {
        authorization_code: "AUTH_72btv547",
        currency: "NGN",
        amount: 10000,
        email: "customer@email.com"
      }
    end

    context "with successful response" do
      before do
        allow(connection).to receive(:post)
          .with("/transaction/partial_debit", payload)
          .and_return(Faraday::Response.new(status: 200, body: {
            "status" => true,
            "message" => "Debit successful",
            "data" => {
              "reference" => "ref_123",
              "status" => "success",
              "amount" => 10000
            }
          }))
      end

      it "performs a partial debit" do
        response = transactions.partial_debit(payload)
        expect(response.success?).to be true
        expect(response.status).to eq("success")
      end
    end

    context "with validation errors" do
      it "raises MissingParamError when authorization_code is missing" do
        invalid_payload = payload.except(:authorization_code)
        expect { transactions.partial_debit(invalid_payload) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: authorization_code"
        )
      end

      it "raises InvalidFormatError when currency format is invalid" do
        invalid_payload = payload.merge(currency: "INVALID")
        expect { transactions.partial_debit(invalid_payload) }.to raise_error(
          PaystackSdk::InvalidFormatError,
          "Invalid format for currency. Expected format: 3-letter ISO code (e.g., NGN, USD, GHS)"
        )
      end
    end
  end
end
