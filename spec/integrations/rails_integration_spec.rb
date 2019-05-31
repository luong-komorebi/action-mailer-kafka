require 'spec_helper'
require_relative './rails_test_helper.rb'

describe 'Rails integration' do
  let(:kafka_client) { ::Kafka.new(seed_brokers: [ENV['KAFKA_BROKERS'] || 'localhost:9092']) }

  RailsTestHelper.create_rails_app

  it 'sends emails to Kafka without blocking' do
    RailsTestHelper.run_rails_app do |_|
      result = RailsTestHelper.rails_request '/'
      expect(result).to eql('OK')
    end
    consumer = kafka_client.consumer(group_id: 'test')
    consumer.subscribe(Eh::Mailer::DeliveryMethod::MAILER_TOPIC_NAME)
    consumer.each_message do |message|
      expect(message).not_to be_nil
      consumer.stop
    end
  end
end
