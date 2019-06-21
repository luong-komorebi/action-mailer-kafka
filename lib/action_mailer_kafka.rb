require 'json'
require 'kafka'
require 'mail'
require 'action_mailer_kafka/error'
require 'action_mailer_kafka/railtie' if defined? Rails
require 'action_mailer_kafka/delivery_method'
require 'action_mailer_kafka/version'

module ActionMailerKafka
end
