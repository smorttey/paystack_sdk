module PaystackSdk
  # The Response class provides a wrapper around Paystack API responses.
  # It offers convenient access to response data through dot notation and
  # supports both direct attribute access and hash/array-like operations.
  #
  # Features:
  # - Dynamic attribute access via dot notation (response.data.attribute)
  # - Hash-like access (response[:key])
  # - Array-like access for list responses (response[0])
  # - Iteration support (response.each)
  # - Automatic handling of nested data structures
  #
  # @example Basic usage
  # ```ruby
  #   response = PaystackSdk::Response.new(api_response)
  #
  #   # Check if request was successful
  #   if response.success?
  #     # Access data using dot notation
  #     puts response.data.authorization_url
  #     puts response.data.reference
  #
  #     # Or directly from response
  #     puts response.authorization_url
  #   else
  #     puts "Error: #{response.error_message}"
  #   end
  #
  # @example Working with list responses
  #   response = transactions.list
  #
  #   # Iterate through items
  #   response.data.each do |transaction|
  #     puts transaction.amount
  #     puts transaction.reference
  #   end
  #
  #   # Access by index
  #   first_transaction = response.data[0] # => same as `response.first`
  #   puts first_transaction.customer.email
  #   ```
  class Response
    # @return [String, nil] Error message if the request failed
    attr_reader :error_message

    # @return [String, nil] API message from the response
    attr_reader :api_message

    # @return [Hash, Array, Object] The underlying data
    attr_reader :raw_data

    # Initializes a new Response object
    #
    # @param response [Faraday::Response, Hash, Array] The raw API response or data
    def initialize(response)
      if response.is_a?(Faraday::Response)
        # Handle direct Faraday response
        @success = response.success?
        @body = response.body
        @api_message = extract_api_message(@body)
        @raw_data = extract_data_from_body(@body)

        unless @success
          @error_message = @api_message || "Paystack API Error"
        end
      elsif response.is_a?(Response)
        # If we're wrapping a Response object, just copy its data
        @success = response.success
        @error_message = response.error_message
        @api_message = response.api_message
        @raw_data = response.raw_data
      else
        # For direct data (Hash, Array, etc.)
        @success = true
        @raw_data = response
      end
    end

    # Returns a Response object for the data
    # This enables chained access like response.data.key
    #
    # @return [Response] self, to enable chaining
    def data
      self
    end

    # Check if the response was successful
    #
    # @return [Boolean] true if the API request was successful
    def success?
      @success
    end

    # Returns the original response body
    # This is useful for debugging or accessing raw data
    #
    # @return [Hash, Array] The original response body
    def original_response
      @body
    end

    # Access hash values via methods (dot notation)
    # Allows accessing data attributes directly: response.attribute_name
    #
    # @param method_name [Symbol] The attribute name to access
    # @param args [Array] Method arguments (unused)
    # @param block [Proc] Method block (unused)
    # @return [Object, Response] The attribute value, wrapped in Response if it's a complex type
    def method_missing(method_name, *args, &block)
      if @raw_data.is_a?(Hash) && (@raw_data.key?(method_name) || @raw_data.key?(method_name.to_s))
        value = @raw_data[method_name] || @raw_data[method_name.to_s]
        wrap_value(value)
      elsif @raw_data.is_a?(Array) && @raw_data.respond_to?(method_name)
        result = @raw_data.send(method_name, *args, &block)
        wrap_value(result)
      else
        super
      end
    end

    # Check if the object responds to a method
    #
    # @param method_name [Symbol] The method name
    # @param include_private [Boolean] Whether to include private methods
    # @return [Boolean] Whether the method is supported
    def respond_to_missing?(method_name, include_private = false)
      (@raw_data.is_a?(Hash) && (@raw_data.key?(method_name) || @raw_data.key?(method_name.to_s))) ||
        (@raw_data.is_a?(Array) && @raw_data.respond_to?(method_name)) ||
        super
    end

    # Access data via hash/array notation
    #
    # @param key [Object] The key or index to access
    # @return [Object, Response] The value for the given key or index
    def [](key)
      return nil unless @raw_data

      if @raw_data.is_a?(Hash)
        value = @raw_data[key.is_a?(String) ? key.to_sym : key]
        wrap_value(value)
      elsif @raw_data.is_a?(Array) && key.is_a?(Integer)
        wrap_value(@raw_data[key])
      end
    end

    # Check if key exists in hash
    #
    # @param key [Symbol, String] The key to check
    # @return [Boolean] Whether the key exists
    def key?(key)
      @raw_data.is_a?(Hash) && @raw_data.key?(key.is_a?(String) ? key.to_sym : key)
    end

    # Iterate through hash entries or array items
    #
    # @yield [key, value] For hashes, passes each key-value pair
    # @yield [value] For arrays, passes each item
    # @return [Response, Enumerator] Self for chaining or Enumerator if no block given
    def each(&block)
      return enum_for(:each) unless block_given?

      if @raw_data.is_a?(Hash)
        @raw_data.each { |k, v| yield k, wrap_value(v) }
      elsif @raw_data.is_a?(Array)
        @raw_data.each { |item| yield wrap_value(item) }
      end
      self
    end

    # Standard array methods, delegated to the raw data
    # @!method size
    #   @return [Integer] The number of items
    # @!method length
    #   @return [Integer] The number of items
    # @!method count
    #   @return [Integer] The number of items
    # @!method empty?
    #   @return [Boolean] Whether the collection is empty
    [:size, :length, :count, :empty?].each do |method_name|
      define_method(method_name) do
        @raw_data.send(method_name) if @raw_data.respond_to?(method_name)
      end
    end

    # Special array methods that return wrapped values
    # @!method first
    #   @return [Object, Response] The first item, wrapped if necessary
    # @!method last
    #   @return [Object, Response] The last item, wrapped if necessary
    [:first, :last].each do |method_name|
      define_method(method_name) do
        return nil unless @raw_data.is_a?(Array)
        wrap_value(@raw_data.send(method_name))
      end
    end

    private

    # Extract API message from response body
    #
    # @param body [Hash] The response body
    # @return [String, nil] The API message
    def extract_api_message(body)
      body["message"] || body[:message] if body.is_a?(Hash)
    end

    # Extract data from response body
    #
    # @param body [Hash, Array] The response body
    # @return [Hash, Array, Object] The data portion of the response
    def extract_data_from_body(body)
      if body.is_a?(Hash)
        body["data"] || body[:data] || body
      else
        body
      end
    end

    # Wrap value in Response if needed
    #
    # @param value [Object] The value to wrap
    # @return [Object, Response] The wrapped value
    def wrap_value(value)
      case value
      when Response
        # Already wrapped
        value
      when Hash, Array
        # Create a new Response with the value
        Response.new(value)
      else
        # Return primitives as-is
        value
      end
    end
  end
end
