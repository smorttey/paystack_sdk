# frozen_string_literal: true

require "faraday"
require_relative "paystack_sdk/version"
require_relative "paystack_sdk/client"

module PaystackSdk
  class Error < StandardError; end
end
