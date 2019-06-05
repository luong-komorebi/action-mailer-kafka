require 'spec_helper'

describe Eh::Mailer::KafkaWorker do
  let(:fake_data) { { 'some_data': 1 } }
  let(:fake_topic) { 'some_topic' }

  describe '#publish_message' do
    context 'when given kafka client info' do
      let(:kafka_client_info) do
        { seed_brokers: ['localhost:9090'] }
      end

      let(:fake_kafka) { instance_double('FakeKafka', producer: FakeKafkaProducer.new) }

      before do
        allow(Kafka).to receive(:new).with(kafka_client_info).and_return(fake_kafka)
      end

      it 'send message using kafka producer' do
        described_class.new(
          kafka_client_info: kafka_client_info
        ).publish_message(fake_data, fake_topic)
        expect(Kafka).to have_received(:new).with(kafka_client_info)
        expect(fake_kafka.producer.queue[fake_topic]).to eq(fake_data)
      end
    end

    context 'when given kafka producer' do
      let(:kafka_producer) { FakeKafkaProducer.new }

      it 'send message using kafka producer' do
        described_class.new(
          kafka_producer: kafka_producer
        ).publish_message(fake_data, fake_topic)
        expect(kafka_producer.queue[fake_topic]).to eq(fake_data)
      end
    end

    context 'when given kafka publish process' do
      let(:kafka_publish_proc) do
        proc { |message, topic| [message, topic] }
      end

      it 'send message using kafka producer' do
        result = described_class.new(
          kafka_publish_proc: kafka_publish_proc
        ).publish_message(fake_data, fake_topic)
        expect(result).to eq([fake_data, fake_topic])
      end
    end
  end
end
