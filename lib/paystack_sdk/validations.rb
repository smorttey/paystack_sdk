# frozen_string_literal: true

module PaystackSdk
  # The Validations module provides shared validation methods for Paystack SDK resources.
  # It includes methods for validating common parameters like references, amounts, dates, etc.
  #
  # This module is intended to be included in resource classes to provide consistent
  # parameter validation before making API calls.
  module Validations
    # Validates that input is a hash.
    #
    # @param input [Object] The input to validate
    # @param name [String] Name of the parameter for error messages
    # @raise [PaystackSdk::Error] If input is not a hash
    def validate_hash!(input:, name: "Payload")
      raise PaystackSdk::Error, "#{name} must be a hash" unless input.is_a?(Hash)
    end

    # Validates that required parameters are present in a payload.
    #
    # @param payload [Hash] The payload to validate
    # @param required_params [Array<Symbol>] List of required parameter keys
    # @param operation_name [String] Name of the operation for error messages
    # @raise [PaystackSdk::Error] If any required parameters are missing
    def validate_required_params!(payload:, required_params:, operation_name: "Operation")
      missing_params = required_params.select do |param|
        !payload.key?(param) && !payload.key?(param.to_s)
      end

      unless missing_params.empty?
        missing_list = missing_params.map(&:to_s).join(", ")
        raise PaystackSdk::Error, "#{operation_name} requires these missing parameter(s): #{missing_list}"
      end
    end

    # Validates that a value is present (not nil or empty).
    #
    # @param value [Object] The value to validate
    # @param name [String] Name of the parameter for error messages
    # @raise [PaystackSdk::Error] If value is nil or empty
    def validate_presence!(value:, name: "Parameter")
      if value.nil? || (value.respond_to?(:empty?) && value.empty?)
        raise PaystackSdk::Error, "#{name} cannot be empty"
      end
    end

    # Validates that a number is a positive integer.
    #
    # @param value [Object] The value to validate
    # @param name [String] Name of the parameter for error messages
    # @param allow_nil [Boolean] Whether nil values are allowed
    # @raise [PaystackSdk::Error] If value is not a positive integer (and not nil if allow_nil is true)
    def validate_positive_integer!(value:, name: "Parameter", allow_nil: true)
      if value.nil?
        raise PaystackSdk::Error, "#{name} cannot be nil" unless allow_nil
      elsif !value.is_a?(Integer) || value < 1
        raise PaystackSdk::Error, "#{name} must be a positive integer"
      end
    end

    # Validates a transaction reference format.
    #
    # @param reference [String] The reference to validate
    # @param name [String] Name of the parameter for error messages
    # @raise [PaystackSdk::Error] If reference format is invalid
    def validate_reference_format!(reference:, name: "Reference")
      unless reference.to_s.match?(/^[a-zA-Z0-9._=-]+$/)
        raise PaystackSdk::Error, "#{name} can only contain alphanumeric characters and the following: -, ., ="
      end
    end

    # Validates a date string format.
    #
    # @param date_str [String] The date string to validate
    # @param name [String] Name of the parameter for error messages
    # @param allow_nil [Boolean] Whether nil values are allowed
    # @raise [PaystackSdk::Error] If date format is invalid
    def validate_date_format!(date_str:, name: "Date", allow_nil: true)
      if date_str.nil?
        raise PaystackSdk::Error, "#{name} cannot be nil" unless allow_nil
        return
      end

      begin
        Date.parse(date_str.to_s)
      rescue Date::Error
        raise PaystackSdk::Error, "Invalid #{name.downcase} format. Use format: YYYY-MM-DD or ISO8601"
      end
    end

    # Validates that a value is within an allowed set of values.
    #
    # @param value [Object] The value to validate
    # @param allowed_values [Array] List of allowed values
    # @param name [String] Name of the parameter for error messages
    # @param allow_nil [Boolean] Whether nil values are allowed
    # @param case_sensitive [Boolean] Whether the comparison is case-sensitive
    # @raise [PaystackSdk::Error] If value is not in the allowed set
    def validate_inclusion!(value:, allowed_values:, name: "Parameter", allow_nil: true, case_sensitive: false)
      if value.nil?
        raise PaystackSdk::Error, "#{name} cannot be nil" unless allow_nil
        return
      end

      check_value = case_sensitive ? value.to_s : value.to_s.downcase
      check_allowed = case_sensitive ? allowed_values : allowed_values.map(&:downcase)

      unless check_allowed.include?(check_value)
        allowed_list = allowed_values.join("', '")
        raise PaystackSdk::Error, "#{name} must be one of: '#{allowed_list}'"
      end
    end

    # Validates an email format.
    #
    # @param email [String] The email to validate
    # @param name [String] Name of the parameter for error messages
    # @param allow_nil [Boolean] Whether nil values are allowed
    # @raise [PaystackSdk::Error] If email format is invalid
    def validate_email!(email:, name: "Email", allow_nil: false)
      if email.nil?
        raise PaystackSdk::Error, "#{name} cannot be nil" unless allow_nil
        return
      end

      unless email.to_s.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
        raise PaystackSdk::Error, "Invalid #{name.downcase} format"
      end
    end

    # Validates a currency code format.
    #
    # @param currency [String] The currency code to validate
    # @param name [String] Name of the parameter for error messages
    # @param allow_nil [Boolean] Whether nil values are allowed
    # @raise [PaystackSdk::Error] If currency format is invalid
    def validate_currency!(currency:, name: "Currency", allow_nil: true)
      if currency.nil?
        raise PaystackSdk::Error, "#{name} cannot be nil" unless allow_nil
        return
      end

      unless currency.to_s.match?(/\A[A-Z]{3}\z/)
        raise PaystackSdk::Error, "#{name} must be a 3-letter ISO code (e.g., NGN, USD, GHS)"
      end
    end

    # Validates multiple fields at once.
    #
    # @param payload [Hash] The payload containing fields to validate
    # @param validations [Hash] Mapping of field names to validation options
    # @raise [PaystackSdk::Error] If any validation fails
    #
    # @example
    # ```ruby
    #   validate_fields!(
    #     payload: params,
    #     validations: {
    #       email: { type: :email, required: true },
    #       amount: { type: :positive_integer, required: true },
    #       currency: { type: :currency, required: false },
    #       reference: { type: :reference, required: false }
    #     }
    #   )
    # ```
    def validate_fields!(payload:, validations:)
      # First check required fields
      required_fields = validations.select { |_, opts| opts[:required] }.keys
      validate_required_params!(payload: payload, required_params: required_fields) unless required_fields.empty?

      # Then validate each field
      validations.each do |field, options|
        value = payload[field] || payload[field.to_s]
        next if value.nil? && !options[:required]

        case options[:type]
        when :email
          validate_email!(email: value, name: field.to_s.capitalize, allow_nil: !options[:required])
        when :positive_integer
          validate_positive_integer!(value: value, name: field.to_s, allow_nil: !options[:required])
        when :reference
          validate_reference_format!(reference: value, name: field.to_s) if value
        when :date
          validate_date_format!(date_str: value, name: field.to_s, allow_nil: !options[:required])
        when :currency
          validate_currency!(currency: value, name: field.to_s, allow_nil: !options[:required])
        when :inclusion
          if value
            validate_inclusion!(
              value: value,
              allowed_values: options[:allowed_values],
              name: field.to_s,
              allow_nil: !options[:required],
              case_sensitive: options[:case_sensitive]
            )
          end
        end
      end
    end
  end
end
