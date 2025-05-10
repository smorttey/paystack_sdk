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

    it "initializes a transaction successfully" do
      response_body = {status: true, data: {authorization_url: "https://paystack.com/transaction/123"}}
      response_double = instance_double(Faraday::Response, success?: true, body: response_body)

      allow(connection).to receive(:post).with("/transaction/initialize", params).and_return(response_double)

      response = transactions.initialize_transaction(params)

      expect(response[:status]).to be true
      expect(response[:data][:authorization_url]).to eq("https://paystack.com/transaction/123")
    end
  end

  describe "#fetch" do
    let(:transaction_id) { "12345" }

    it "fetches a transaction successfully" do
      response_body = {status: true, data: {id: transaction_id, amount: 10000, currency: "GHS"}}
      response_double = instance_double(Faraday::Response, success?: true, body: response_body)

      allow(connection).to receive(:get).with("/transaction/#{transaction_id}").and_return(response_double)

      response = transactions.fetch(transaction_id)

      expect(response[:status]).to be true
      expect(response[:data][:id]).to eq(transaction_id)
      expect(response[:data][:amount]).to eq(10000)
      expect(response[:data][:currency]).to eq("GHS")
    end
  end

  describe "#verify" do
    let(:transaction_reference) { "txn_ref_12345" }

    it "verifies a transaction successfully" do
      response_body = {status: true, data: {reference: transaction_reference, status: "success"}}
      response_double = instance_double(Faraday::Response, success?: true, body: response_body)

      allow(connection).to receive(:get).with("/transaction/verify/#{transaction_reference}").and_return(response_double)

      response = transactions.verify(reference: transaction_reference)

      expect(response[:status]).to be true
      expect(response[:data][:reference]).to eq(transaction_reference)
      expect(response[:data][:status]).to eq("success")
    end
  end

  describe "#totals" do
    it "retrieves transaction totals successfully" do
      response_body = {
        status: true,
        data: {total_transactions: 100, total_volume: 500000, pending_transfers: 20000}
      }
      response_double = instance_double(Faraday::Response, success?: true, body: response_body)

      allow(connection).to receive(:get).with("/transaction/totals").and_return(response_double)

      response = transactions.totals

      expect(response[:status]).to be true
      expect(response[:data][:total_transactions]).to eq(100)
      expect(response[:data][:total_volume]).to eq(500000)
      expect(response[:data][:pending_transfers]).to eq(20000)
    end
  end
end
