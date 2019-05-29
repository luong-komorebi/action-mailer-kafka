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

- To run the test, do ` bundle exec rspec `
- To see the coverage of your codes, run ` COVERAGE=true bundle exec rspec `. If coverage drops below 80%, CI will fail
- To see quality reporter, run ` bundle exec rubycritic -s 90 --suppress-ratings app/ `. If quality score drops below 90, CI will fail

