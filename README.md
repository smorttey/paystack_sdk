# Paystack Ruby SDK: Simplify Payments

The `paystack_sdk` gem provides a simple and intuitive interface for interacting with Paystack's payment gateway API. It allows developers to easily integrate Paystack's payment processing features into their Ruby applications. With support for various endpoints, this SDK simplifies tasks such as initiating transactions, verifying payments, managing customers, and more.

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

## Usage

Here’s a basic example of how to use the `paystack_sdk` gem:

```ruby
require 'paystack_sdk'

# Initialize the SDK with your Paystack secret key
paystack = PaystackSdk::Client.new(api_key: "sk_test_xxx")

# Example: Initialize a payment
params = {email: "customer@email.com", amount: "2300", currency: "USD"}
response = paystack.transactions.initialize_transaction(params)

# Example: Verify a payment
response = paystack.transactions.verify(reference: "transaction_reference")
if paystack.transactions.success?
  puts "Payment verified successfully!"
else
  puts "Payment verification failed: #{response.error_message}"
end

# Note: The `response` object is a hash containing the API response. Use the `#success?`
# method on the relevant resource instance (e.g., `transactions`, `plans`, `subscriptions`)
# to determine if the request was successful.
```

Refer to the [documentation](https://github.com/nanafox/paystack_sdk) for more detailed usage examples and supported endpoints.

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
