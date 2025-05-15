# Paystack Ruby SDK: Simplify Payments

The `paystack_sdk` gem provides a simple and intuitive interface for interacting with Paystack's payment gateway API. It allows developers to easily integrate Paystack's payment processing features into their Ruby applications. With support for various endpoints, this SDK simplifies tasks such as initiating transactions, verifying payments, managing customers, and more.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Client Initialization](#client-initialization)
  - [Transactions](#transactions)
    - [Initialize a Transaction](#initialize-a-transaction)
    - [Verify a Transaction](#verify-a-transaction)
    - [List Transactions](#list-transactions)
    - [Fetch a Transaction](#fetch-a-transaction)
    - [Get Transaction Totals](#get-transaction-totals)
  - [Response Handling](#response-handling)
    - [Working with Response Objects](#working-with-response-objects)
    - [Accessing the Original Response](#accessing-the-original-response)
    - [Error Handling](#error-handling)
- [Advanced Usage](#advanced-usage)
  - [Environment Variables](#environment-variables)
  - [Direct Resource Instantiation](#direct-resource-instantiation)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'paystack_sdk'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install paystack_sdk
```

## Quick Start

```ruby
require 'paystack_sdk'

# Initialize the client with your secret key
paystack = PaystackSdk::Client.new(secret_key: "sk_test_xxx")

# Initialize a transaction
params = {
  email: "customer@email.com",
  amount: 2300,  # Amount in the smallest currency unit (kobo for NGN)
  currency: "NGN"
}

response = paystack.transactions.initiate(params)

if response.success?
  puts "Visit this URL to complete payment: #{response.authorization_url}"
else
  puts "Error: #{response.error_message}"
end
```

## Usage

### Client Initialization

```ruby
# Initialize with your Paystack secret key
paystack = PaystackSdk::Client.new(secret_key: "sk_test_xxx")

# You can access the connection directly if needed
connection = paystack.connection
```

### Transactions

The SDK provides comprehensive support for Paystack's Transaction API.

#### Initialize a Transaction

```ruby
# Prepare transaction parameters
params = {
  email: "customer@example.com",
  amount: 10000,  # Amount in the smallest currency unit (e.g., kobo, pesewas, cents)
  currency: "GHS",
  callback_url: "https://example.com/callback"
}

# Initialize the transaction
response = paystack.transactions.initiate(params)

if response.success?
  puts "Transaction initialized successfully!"
  puts "Authorization URL: #{response.authorization_url}"
  puts "Access Code: #{response.access_code}"
  puts "Reference: #{response.reference}"
else
  puts "Error: #{response.error_message}"
end
```

#### Verify a Transaction

```ruby
# Verify using transaction reference
response = paystack.transactions.verify(reference: "transaction_reference")

if response.success?
  transaction = response.data
  puts "Transaction verified successfully!"
  puts "Status: #{transaction.status}"
  puts "Amount: #{transaction.amount}"
  puts "Currency: #{transaction.currency}"
  puts "Customer Email: #{transaction.customer.email}"

  # Check specific transaction status
  case transaction.status
  when "success"
    puts "Payment successful!"
  when "pending"
    puts "Payment is pending."
  else
    puts "Current status: #{transaction.status}"
  end
else
  puts "Verification failed: #{response.error_message}"
end
```

#### List Transactions

```ruby
# Get all transactions (default pagination: 50 per page)
response = paystack.transactions.list

# With custom pagination
response = paystack.transactions.list(per_page: 20, page: 2)

# With additional filters
response = paystack.transactions.list(
  per_page: 10,
  page: 1,
  from: "2025-01-01",
  to: "2025-04-30",
  status: "success"
)

if response.success?
  puts "Total transactions: #{response.count}" # response.size is another way

  response.data.each do |transaction|
    puts "ID: #{transaction.id}"
    puts "Reference: #{transaction.reference}"
    puts "Amount: #{transaction.amount}"
    puts "----------------"
  end

  # Get the first transaction
  first_transaction = response.data.first
  puts "First transaction reference: #{first_transaction.reference}"

  # Get the last transaction
  last_transaction = response.data.last
  puts "Last transaction amount: #{last_transaction.amount}"
else
  puts "Error: #{response.error_message}"
end
```

#### Fetch a Transaction

```ruby
# Fetch a specific transaction by ID
transaction_id = "12345"
response = paystack.transactions.fetch(transaction_id)

if response.success?
  transaction = response.data
  puts "Transaction details:"
  puts "ID: #{transaction.id}"
  puts "Reference: #{transaction.reference}"
  puts "Amount: #{transaction.amount}"
  puts "Status: #{transaction.status}"

  # Access customer information
  puts "Customer Email: #{transaction.customer.email}"
  puts "Customer Name: #{transaction.customer.name}"
else
  puts "Error: #{response.error_message}"
end
```

#### Get Transaction Totals

```ruby
# Get transaction volume and success metrics
response = paystack.transactions.totals

if response.success?
  puts "Total Transactions: #{response.data.total_transactions}"
  puts "Total Volume: #{response.data.total_volume}"
  puts "Pending Transfers: #{response.data.pending_transfers}"
else
  puts "Error: #{response.error_message}"
end
```

### Response Handling

#### Working with Response Objects

All API requests return a `PaystackSdk::Response` object that provides easy access to the response data.

```ruby
response = paystack.transactions.initiate(params)

# Check if the request was successful
response.success?  # => true or false

# Access response message
response.api_message  # => "Authorization URL created"

# Access data using dot notation
response.data.authorization_url
response.data.access_code

# Access data directly from the response
response.authorization_url  # Same as response.data.authorization_url

# Access nested data
response.data.customer.email

# For arrays, use array methods
response.data.first  # First item in an array
response.data.last   # Last item in an array
response.data.size   # Size of the array

# Iterate through array data
response.data.each do |item|
  puts item.id
end
```

#### Accessing the Original Response

Sometimes you may need access to the original API response:

```ruby
response = paystack.transactions.list

# Access the original response body
original = response.original_response

# Access metadata from the original response
total_count = original.dig("meta", "total")
current_page = original.dig("meta", "page")
```

#### Error Handling

```ruby
response = paystack.transactions.verify(reference: "invalid_reference")

unless response.success?
  puts "Error: #{response.error_message}"

  # Take action based on the error
  if response.error_message.include?("not found")
    puts "The transaction reference was not found."
  elsif response.error_message.include?("Invalid key")
    puts "API authentication failed. Check your API key."
  end
end
```

## Advanced Usage

### Environment Variables

You can use environment variables to configure the SDK:

```ruby
# Set the PAYSTACK_SECRET_KEY environment variable
ENV["PAYSTACK_SECRET_KEY"] = "sk_test_xxx"

# Then initialize resources without specifying the key
transactions = PaystackSdk::Resources::Transactions.new
```

### Direct Resource Instantiation

For more advanced usage, you can instantiate resource classes directly:

```ruby
# With a secret key
transactions = PaystackSdk::Resources::Transactions.new(secret_key: "sk_test_xxx")

# With an existing Faraday connection
connection = Faraday.new(url: "https://api.paystack.co") do |conn|
  # Configure the connection
end

# The secret key can be omitted if set in an environment
transactions = PaystackSdk::Resources::Transactions.new(connection, secret_key:)
```

For more detailed documentation on specific resources, please refer to the following guides:

- [Transactions](https://paystack.com/docs/api/transaction/)
- [Customers](https://paystack.com/docs/api/customer/)
- [Plans](https://paystack.com/docs/api/plan/)
- [Subscriptions](https://paystack.com/docs/api/subscription/)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run:

```bash
bundle exec rake install
```

To release a new version, update the version number in `version.rb`, and then run:

```bash
bundle exec rake release
```

This will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/nanafox/paystack_sdk](https://github.com/nanafox/paystack_sdk). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/nanafox/paystack_sdk/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PaystackSdk project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/nanafox/paystack_sdk/blob/main/CODE_OF_CONDUCT.md).
