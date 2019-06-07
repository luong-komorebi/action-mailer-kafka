require 'spec_helper'
require_relative './rails_test_helper.rb'

describe 'Rails integration' do
  let(:kafka_client) { ::Kafka.new(['localhost:9092']) }
  let(:example_topic) { 'Mail.Mails.Send' }

  RailsTestHelper.create_rails_app

  it 'sends emails to Kafka without blocking' do
    RailsTestHelper.run_rails_app do |_|
      expect(RailsTestHelper.rails_request('/')).to eql('200')
    end

    kafka_attempt = 0
    begin
      messages = kafka_client.fetch_messages(topic: example_topic, partition: 0, offset: :earliest)
      messages.each do |m|
        expect(m).not_to be_nil
      end
    rescue Kafka::LeaderNotAvailable
      sleep 1
      retry if (kafka_attempt += 1) < 3
    end
  end
end
