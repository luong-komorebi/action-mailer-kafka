# ActionMailerKafka
[![CircleCI](https://circleci.com/gh/luong-komorebi/action-mailer-kafka/tree/master.svg?style=svg)](https://circleci.com/gh/luong-komorebi/action-mailer-kafka/tree/master) [![Maintainability](https://api.codeclimate.com/v1/badges/4f16e7b6eb2733c52cf4/maintainability)](https://codeclimate.com/github/luong-komorebi/action-mailer-kafka/maintainability) [![codecov](https://codecov.io/gh/luong-komorebi/action-mailer-kafka/branch/master/graph/badge.svg)](https://codecov.io/gh/luong-komorebi/action-mailer-kafka)

<p align="center">
  <img src="./logo.png">
</p>

This gem is a unified interface to send emails to Kafka message queue. It takes care of the transport layer by defining a delivery method for `action-mailer`. 

To see the gem in action, go to example folder and start the example rails app.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'action_mailer_kafka'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install action_mailer_kafka

## Usage

### Rails

This Gem is tested with Rails version 4. and 5.

To use the gem, change action mailer's delivery method to `action_mailer_kafka`

```ruby
# for example, in config/environments/production.rb
config.action_mailer.delivery_method = :action_mailer_kafka
```

#### Kafa settings
The gem accepts 2 kinds of kafka setting params:

1. Your Kafka publish proc


With this option, you should config as below:

```ruby
config.action_mailer.action_mailer_kafka_settings = {
  kafka_mail_topic: 'YourKafkaTopic',
  kafka_publish_proc: proc do |message_data, default_message_topic|
                          YourKafkaClientInstance.publish(message_data, default_message_topic)
                        end
}
```

and the data would go through your publish process.


2. Your kafka client info

With this option, the library will generate a kafka instance for you:

```ruby
config.action_mailer.action_mailer_kafka_settings = {
  kafka_mail_topic: 'YourKafkaTopic',
  kafka_client_info: {
    seed_brokers: ['localhost:9090'],
    logger: logger,
    ssl_ca_cert: File.read('/path/to/cert')
    # For more option on what to pass here, see https://github.com/zendesk/ruby-kafka/blob/master/lib/kafka/client.rb#L20
  }
}
```

Other settings params:
- `raise_on_delivery_error` : a boolean value that decides if this library should raise error.
- `logger` : pass your own logger instance.
- `fallback`: fallback method in case Kafka fails due to message being too big or other errors.
  + `fallback_delivery_method`
  + `fallback_delivery_method_settings`

Example of smtp as a fallback method:
```ruby
  config.action_mailer.action_mailer_kafka_settings = {
    kafka_mail_topic: 'Mail.Mails.Send.Staging',
    kafka_client_info: {
    # .....
    },
    fallback: {
      fallback_delivery_method: :smtp,
      fallback_delivery_method_settings: {
        address: 'smtp.sendgrid.net',
        port: (ENV['SENDGRID_SMTP_PORT'] || 587).to_i,
        authentication: :plain,
        user_name: ENV['SENDGRID_USERNAME'],
        password: ENV['SENDGRID_PASSWORD']
      }
    }
  }
```

#### Service name

Because the email is sent to Kafka may come from a microservice in your system, an additional field to specify that would be useful. By default, if there is no service name added, the gem will ignore the service name. If provided, the serice name would become a value to the `author` field to the kafka message

```ruby
config.action_mailer.action_mailer_kafka_settings = {
  sevice_name: 'local app'
}
```

### Other frameworks

Not tested. But this gem is not tight coupled with Rails. It just needs action-mailer.

### Custom headers

The gem would only accepts custom headers for emails which follow [RFC822](tools.ietf.org/html/rfc822) (which means that a custom header should begin with 'X-'). Other custom headers would not be parsed and sent to Kafka to be consumed.


## Gem Development

### Testing
- To run the test, do ` bundle exec rspec `.
  - To run just the unit tests: ` bundle exec rspec spec/units `
  - To run just the integration tests: ` bundle exec rspec spec/integrations `
- To see the coverage of your codes, run ` COVERAGE=true bundle exec rspec `. If coverage drops below 80%, CI will fail
- To see quality reporter, run ` bundle exec rubycritic -s 90 --suppress-ratings app/ `. If quality score drops below 90, CI will fail
- On CI, the test is run with multiple versions of `mail` and `rails` gems to ensure compatability. If you want to run such tests on your local machine:
  - To run unit tests:
    - First of all, install all dependencies with: ` bundle exec appraisal install `
    - To run the unit tests, run ` bundle exec appraisal rspec spec/units `
  - To run integration tests:
    - First of all, install all dependencies with: ` INTEGRATION_TEST='true' bundle exec appraisal install `
    - To run the unit tests, run ` bundle exec appraisal rspec spec/integrations `
