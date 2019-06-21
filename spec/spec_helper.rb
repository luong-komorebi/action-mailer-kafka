require 'byebug'
require 'bundler/setup'
require 'action_mailer_kafka'
require 'rspec/json_expectations'

# Setup coverage report
require 'simplecov'
SimpleCov.start if ENV['COVERAGE']
puts 'SimpleCov started successfully!'

SimpleCov.at_exit do
  SimpleCov.result.format!
end

SimpleCov.minimum_coverage 80

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
  end
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.expose_dsl_globally = true
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
