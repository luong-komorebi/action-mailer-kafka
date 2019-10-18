require 'msgpack'
MessagePack::DefaultFactory.register_type(
  -1,
  Time,
  packer: MessagePack::Time::Packer
)

require 'delegate' # https://github.com/zendesk/ruby-kafka/pull/768
require 'kafka'
require 'mail'
require 'action_mailer_kafka/error'
require 'action_mailer_kafka/railtie' if defined? Rails
require 'action_mailer_kafka/base_producer'
require 'action_mailer_kafka/delivery_method'
require 'action_mailer_kafka/version'

module ActionMailerKafka
end
