# Eh::Mailer

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

## Development

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
