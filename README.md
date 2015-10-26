Spree GoPay Integration
=====================

[![Gem Version](https://badge.fury.io/rb/spree_gopay_integration.svg)](https://badge.fury.io/rb/spree_gopay_integration)

Spree extension for integration with GoPay payment gateway.

https://www.platebnibrana.cz/

Installation
------------

Add spree_gopay_integration to your Gemfile:

```ruby
gem 'spree_gopay_integration'
```

Bundle your dependencies:

```shell
bundle
```

Configuration
------------

Add following code to your initializers and modify with your credentials.

```Ruby
SpreeGopayIntegration.configure do |config|
    config.environment = :test # :test or :production
    config.goid = "0000000000"
    config.client_id = "0000000000"
    config.client_secret = "aaaaaaaa"
end
```
After this just add payment method in spree administration as usual, everything will then work as expected.

Testing
-------

No tests :( Pull request are welcome.
