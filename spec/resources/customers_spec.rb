# frozen_string_literal: true

RSpec.describe PaystackSdk::Resources::Customers do
  let(:secret_key) { "sk_test_xxx" }
  let(:connection) { instance_double(Faraday::Connection) }
  let(:customers) { described_class.new(connection) }

  describe "#create" do
    let(:params) do
      {
        email: "customer@email.com",
        first_name: "Zero",
        last_name: "Sum",
        phone: "+2348123456789"
      }
    end

    context "with successful response" do
      it "creates a customer successfully" do
        response_body = {
          "status" => true,
          "message" => "Customer created",
          "data" => {
            "email" => "customer@email.com",
            "integration" => 100032,
            "domain" => "test",
            "customer_code" => "CUS_xnxdt6s1zg1f4nx",
            "id" => 1173,
            "identified" => false,
            "identifications" => nil,
            "createdAt" => "2016-03-29T20:03:09.584Z",
            "updatedAt" => "2016-03-29T20:03:09.584Z"
          }
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        expect(connection).to receive(:post)
          .with("customer", params)
          .and_return(faraday_response)

        response = customers.create(params)

        expect(response).to be_a(PaystackSdk::Response)
        expect(response).to be_success
        expect(response.customer_code).to eq("CUS_xnxdt6s1zg1f4nx")
      end
    end

    context "with failed response" do
      it "returns a failed response with error message" do
        response_body = {
          "status" => false,
          "message" => "Invalid email address"
        }

        faraday_response = Faraday::Response.new(status: 400, body: response_body)

        expect(connection).to receive(:post)
          .with("customer", params)
          .and_return(faraday_response)

        response = customers.create(params)

        expect(response).not_to be_success
        expect(response.error_message).to eq("Invalid email address")
      end
    end

    context "with validation errors" do
      it "raises an error when email is missing" do
        invalid_params = params.reject { |k| k == :email }
        expect { customers.create(invalid_params) }
          .to raise_error(PaystackSdk::Error, /email/i)
      end

      it "raises an error when email format is invalid" do
        invalid_params = params.merge(email: "invalid-email")
        expect { customers.create(invalid_params) }
          .to raise_error(PaystackSdk::Error, /email format/i)
      end
    end
  end

  describe "#list" do
    context "with successful response" do
      it "lists customers successfully" do
        response_body = {
          "status" => true,
          "message" => "Customers retrieved",
          "data" => [
            {
              "integration" => 463433,
              "first_name" => "Zero",
              "last_name" => "Sum",
              "email" => "customer@email.com",
              "phone" => nil,
              "metadata" => nil,
              "domain" => "test",
              "customer_code" => "CUS_xr58yrr2ujlft9k",
              "id" => 84312,
              "createdAt" => "2020-07-15T13:46:39.000Z",
              "updatedAt" => "2020-07-15T13:46:39.000Z"
            }
          ]
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        expect(connection).to receive(:get)
          .with("customer", {page: 1, perPage: 50})
          .and_return(faraday_response)

        response = customers.list

        expect(response).to be_success
        expect(response.data.first.customer_code).to eq("CUS_xr58yrr2ujlft9k")
      end
    end
  end

  describe "#fetch" do
    let(:email_or_code) { "CUS_xr58yrr2ujlft9k" }

    context "with successful response" do
      it "fetches a customer successfully" do
        response_body = {
          "status" => true,
          "message" => "Customer retrieved",
          "data" => {
            "integration" => 463433,
            "first_name" => "Zero",
            "last_name" => "Sum",
            "email" => "customer@email.com",
            "phone" => nil,
            "metadata" => nil,
            "domain" => "test",
            "customer_code" => "CUS_xr58yrr2ujlft9k",
            "id" => 84312,
            "createdAt" => "2020-07-15T13:46:39.000Z",
            "updatedAt" => "2020-07-15T13:46:39.000Z"
          }
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        expect(connection).to receive(:get)
          .with("customer/#{email_or_code}")
          .and_return(faraday_response)

        response = customers.fetch(email_or_code)

        expect(response).to be_success
        expect(response.customer_code).to eq("CUS_xr58yrr2ujlft9k")
      end
    end

    context "with validation errors" do
      it "raises an error when email_or_code is nil" do
        expect { customers.fetch(nil) }
          .to raise_error(PaystackSdk::Error, /cannot be empty/i)
      end

      it "raises an error when email_or_code is empty" do
        expect { customers.fetch("") }
          .to raise_error(PaystackSdk::Error, /cannot be empty/i)
      end
    end
  end

  describe "#update" do
    let(:code) { "CUS_xr58yrr2ujlft9k" }
    let(:params) do
      {
        first_name: "John",
        last_name: "Doe",
        phone: "+2348123456789"
      }
    end

    context "with successful response" do
      it "updates a customer successfully" do
        response_body = {
          "status" => true,
          "message" => "Customer updated",
          "data" => {
            "integration" => 463433,
            "first_name" => "John",
            "last_name" => "Doe",
            "email" => "customer@email.com",
            "phone" => "+2348123456789",
            "metadata" => nil,
            "domain" => "test",
            "customer_code" => "CUS_xr58yrr2ujlft9k",
            "id" => 84312,
            "createdAt" => "2020-07-15T13:46:39.000Z",
            "updatedAt" => "2020-07-15T13:46:39.000Z"
          }
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        expect(connection).to receive(:put)
          .with("customer/#{code}", params)
          .and_return(faraday_response)

        response = customers.update(code, params)

        expect(response).to be_success
        expect(response.first_name).to eq("John")
        expect(response.last_name).to eq("Doe")
      end
    end

    context "with validation errors" do
      it "raises an error when code is nil" do
        expect { customers.update(nil, params) }
          .to raise_error(PaystackSdk::Error, /cannot be empty/i)
      end

      it "raises an error when code is empty" do
        expect { customers.update("", params) }
          .to raise_error(PaystackSdk::Error, /cannot be empty/i)
      end
    end
  end

  describe "#validate" do
    let(:code) { "CUS_xr58yrr2ujlft9k" }
    let(:params) do
      {
        country: "NG",
        type: "bank_account",
        account_number: "0123456789",
        bvn: "20012345677",
        bank_code: "007",
        first_name: "John",
        last_name: "Doe"
      }
    end

    context "with successful response" do
      it "validates a customer successfully" do
        response_body = {
          "status" => true,
          "message" => "Customer Identification in progress"
        }

        faraday_response = Faraday::Response.new(status: 202, body: response_body)

        expect(connection).to receive(:post)
          .with("customer/#{code}/identification", params)
          .and_return(faraday_response)

        response = customers.validate(code, params)

        expect(response).to be_success
        expect(response.message).to eq("Customer Identification in progress")
      end
    end

    context "with validation errors" do
      it "raises an error when required parameters are missing" do
        invalid_params = params.reject { |k| k == :type }
        expect { customers.validate(code, invalid_params) }
          .to raise_error(PaystackSdk::Error, /type/i)
      end

      it "raises an error when code is nil" do
        expect { customers.validate(nil, params) }
          .to raise_error(PaystackSdk::Error, /cannot be empty/i)
      end
    end
  end

  describe "#set_risk_action" do
    let(:params) do
      {
        customer: "CUS_xr58yrr2ujlft9k",
        risk_action: "allow"
      }
    end

    context "with successful response" do
      it "sets risk action successfully" do
        response_body = {
          "status" => true,
          "message" => "Customer updated",
          "data" => {
            "customer_code" => "CUS_xr58yrr2ujlft9k",
            "risk_action" => "allow"
          }
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        expect(connection).to receive(:post)
          .with("customer/set_risk_action", params)
          .and_return(faraday_response)

        response = customers.set_risk_action(params)

        expect(response).to be_success
        expect(response.risk_action).to eq("allow")
      end
    end

    context "with validation errors" do
      it "raises an error when customer is missing" do
        invalid_params = params.reject { |k| k == :customer }
        expect { customers.set_risk_action(invalid_params) }
          .to raise_error(PaystackSdk::Error, /customer/i)
      end

      it "raises an error when risk_action is invalid" do
        invalid_params = params.merge(risk_action: "invalid")
        expect { customers.set_risk_action(invalid_params) }
          .to raise_error(PaystackSdk::Error, /risk_action/i)
      end
    end
  end

  describe "#deactivate_authorization" do
    let(:params) do
      {
        authorization_code: "AUTH_72btv547"
      }
    end

    context "with successful response" do
      it "deactivates authorization successfully" do
        response_body = {
          "status" => true,
          "message" => "Authorization has been deactivated"
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        expect(connection).to receive(:post)
          .with("customer/deactivate_authorization", params)
          .and_return(faraday_response)

        response = customers.deactivate_authorization(params)

        expect(response).to be_success
        expect(response.message).to eq("Authorization has been deactivated")
      end
    end

    context "with validation errors" do
      it "raises an error when authorization_code is missing" do
        expect { customers.deactivate_authorization({}) }
          .to raise_error(PaystackSdk::Error, /authorization_code/i)
      end
    end
  end
end
