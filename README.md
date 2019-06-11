# Eh::Mailer

![](./logo.png)

Welcome to Eh-Mailer! This gem is a unified interface to send emails to Kafka and then consumed by mail service. It takes care of the transport layer by defining a delivery method for `action-mailer`. In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/eh/mailer`.

To see the gem in action, go to example folder and start the example rails app.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'eh-mailer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install eh-mailer

## Usage

### Rails

This Gem is tested with Rails version 4. and 5.

To use the gem, change action mailer's delivery method to `eh_mailer`

```ruby
# for example, in config/environments/production.rb
config.action_mailer.delivery_method = :eh_mailer
```

The gem accepts 2 kinds of setting params:

1. Your Kafka publish proc


With this option, you should config as below:

```ruby
config.action_mailer.eh_mailer_settings = {
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
config.action_mailer.eh_mailer_settings = {
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
  config.action_mailer.eh_mailer_settings = {
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

## Gem Development

### Versioning

The gem has 2 branches `development` and `master`, which are built for deployment. On development branch, a version with the gem ends with `.dev` is built for testing purpose. On master branch, the gem follows semantic versioning like any other gems.

To update the version:

1. Go to `lib/eh/mailer/verision.rb` and bump the version
2. Also bump the version in `app.json` if on `master`. This is due to historical reasons and some workflows (i.e.: Publish Github Release) are still using it.
3. Provide changes inside CHANGELOG.

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


