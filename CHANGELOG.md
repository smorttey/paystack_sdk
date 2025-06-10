# [Unreleased]

## [0.1.0] - 2025-06-10

### Added

- Customers resource with full CRUD operations (create, list, fetch, update)
- Customer validation and risk action management features
- Customer authorization deactivation functionality
- Comprehensive documentation for Customers API in README

### Changed

- Improved test consistency by standardizing response body format using string keys with hashrocket notation (`=>`) across all test specifications
- Enhanced error handling specificity in tests by using appropriate error classes (`InvalidValueError`, `InvalidFormatError`, `MissingParamError`) instead of generic `Error` class

### Improved

- Better test coverage and reliability with consistent response format handling
- More precise error validation ensuring proper exception types are raised for different validation failures
- Enhanced documentation with comprehensive examples for all customer operations

## [0.0.5] - 2025-05-15

### Added

- Connection utilities module for improved API connection handling and management
- Enhanced connection configuration and error handling capabilities

## [0.0.4] - 2025-05-15

### Added

- Enhanced transaction resource validations with comprehensive parameter checking
- New transaction methods: `charge_authorization` and `partial_debit`
- Flexible `list` method accepting additional parameters for advanced API requests

### Changed

- Updated SDK authentication to use `secret_key` instead of `api_key` for consistency with Paystack documentation
- Improved transaction method names for better clarity and consistency
- Enhanced README documentation with comprehensive usage examples

### Improved

- Better validation error messages and handling
- More robust parameter validation across all transaction methods

## [0.0.3] - 2025-05-13

### Changed

- Renamed `#initialize_transaction` method to `#initiate` for better clarity and consistency with Paystack API
- Updated .gitignore to exclude Gemfile.lock from version control

### Fixed

- Corrected typos in README documentation regarding original API response handling

## [0.0.2] - 2025-05-11

### Added

- Comprehensive Response class for Paystack API response handling with dynamic attribute access
- Enhanced response object capabilities with better data access patterns
- Improved debugging support for development

### Changed

- Refactored transaction specs to utilize PaystackSdk::Response for better consistency
- Removed redundant success? method in favor of centralized Response handling
- Enhanced documentation clarity on original API response handling

### Improved

- Better response handling architecture across all SDK components
- More intuitive API for accessing response data and metadata

## [0.0.1] - 2025-05-10

### Added

- Initial release of Paystack Ruby SDK
- Basic transaction operations (initiate, verify)
- Foundational SDK architecture with modular design
- Comprehensive error handling framework
- Basic client initialization and configuration
- Initial documentation and usage examples
