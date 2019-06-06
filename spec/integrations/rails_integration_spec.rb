require 'spec_helper'
require_relative './rails_test_helper.rb'

describe 'Rails integration' do
  let(:kafka_client) { ::Kafka.new(['localhost:9092']) }
  let(:example_topic) { 'Mail.Mails.Send' }

  RailsTestHelper.create_rails_app

  it 'sends emails to Kafka without blocking' do
    result = nil
    RailsTestHelper.run_rails_app do |_|
      result = RailsTestHelper.rails_request '/'
    end

    expect(result).to eql('OK')
    consumer = kafka_client.consumer(group_id: 'test')
    consumer.subscribe(example_topic)
    consumer.each_message do |message|
      expect(message).not_to be_nil
      consumer.stop
    end
  end
end
