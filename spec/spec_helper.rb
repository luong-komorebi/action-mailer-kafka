require 'byebug'
require 'bundler/setup'
require 'eh/mailer'
require 'rspec/json_expectations'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.expose_dsl_globally = true
end

class FakeKafkaProducer
  attr_reader :queue

  SECRET_KAFKA_ERROR_TRIGGER = 'raise_kafka_error'.freeze
  SECRET_STANDARD_ERROR_TRIGGER = 'raise_standard_error'.freeze

  def initialize
    @queue = {}
  end

  def produce(package, topic: nil)
    if package.include? SECRET_KAFKA_ERROR_TRIGGER
      raise Kafka::MessageSizeTooLarge, 'Fake Kafka Error'
    end

    if package.include? SECRET_STANDARD_ERROR_TRIGGER
      raise StandardError, 'Fake Standard Error'
    end

    queue[topic] = package
  end

  def deliver_messages; end
end

# Original mockup from ActionMailer
# rubocop:disable Style/ClassVars
class MockSMTP
  def self.deliveries
    @@deliveries
  end

  def self.security
    @@security
  end

  @@deliveries = []
  def initialize
    @@security = nil
  end

  def sendmail(mail, from, to)
    @@deliveries << [mail, from, to]
    'OK'
  end

  def start(*args)
    if block_given?
      yield(self)
    else
      self
    end
  end

  def finish
    true
  end

  def self.clear_deliveries
    @@deliveries = []
  end

  def self.clear_security
    @@security = nil
  end

  def enable_tls(context)
    raise ArgumentError, 'SMTPS and STARTTLS is exclusive' if @@security && @@security != :enable_tls

    @@security = :enable_tls
    context
  end

  def enable_starttls(context = nil)
    raise ArgumentError, 'SMTPS and STARTTLS is exclusive' if @@security == :enable_tls

    @@security = :enable_starttls
    context
  end

  def enable_starttls_auto(context)
    raise ArgumentError, 'SMTPS and STARTTLS is exclusive' if @@security == :enable_tls

    @@security = :enable_starttls_auto
    context
  end
end
# rubocop:enable Style/ClassVars

module Net
  class SMTP
    def self.new(*args)
      MockSMTP.new
    end
  end
end
