require 'spec_helper'

describe Eh::Mailer::DeliveryMethod do
  class FakeKafkaProducer
    attr_reader :queue

    def initialize
      @queue = {}
    end

    def produce(package, topic: nil)
      queue[topic] = package
    end

    def deliver_messages; end
  end

  let(:mail) do
    Mail.new \
      from: 'luong@handsome.rich',
      subject: 'Hello, world!',
      bcc: 'luong@overpower.invincible',
      cc: 'luong@checkmate.com',
      to: 'luong@lord.lol'
  end
  let(:topic) { Eh::Mailer::DeliveryMethod::MAILER_TOPIC_NAME }
  let(:fake_kafka_producer) { FakeKafkaProducer.new }
  let(:mailer) do
    described_class.new(kafka_client_producer: fake_kafka_producer)
  end

  context 'email is plain text' do
    before do
      mail.content_type = 'text/plain'
    end

    it 'deliver message to Kafka' do
      expected_result = {
        header: {},
        subject: 'Hello, world!',
        from: ['luong@handsome.rich'],
        to: ['luong@lord.lol'],
        cc: ['luong@checkmate.com'],
        bcc: ['luong@overpower.invincible'],
        mime_type: 'text/plain',
        body: '',
        attachments: []
      }
      mailer.deliver!(mail)
      expect(fake_kafka_producer.queue[topic]).to include_json(expected_result)
    end
  end

  context 'when there is an error' do
    before do
      mail.content_type = 'text/plain'
    end

    context 'raise on delivery option is set' do
      let(:mailer) do
        described_class.new(kafka_client_producer: fake_kafka_producer)
      end

      it 'log the error and raise exception' do
        expect_any_instance_of(Mail::Message).to receive(:subject).and_raise(StandardError, 'some error')
        expect_any_instance_of(Logger).to receive(:error)
        mailer.deliver!(mail)
      end
    end

    context 'raise on delivery option is not set' do
      let(:mailer) do
        described_class.new(kafka_client_producer: fake_kafka_producer, raise_on_delivery_error: true)
      end

      it 'log the error and raise exception' do
        expect_any_instance_of(Mail::Message).to receive(:subject).and_raise(StandardError, 'some error')
        expect { mailer.deliver!(mail) }.to raise_error(StandardError, 'some error')
      end
    end
  end

  context 'email is html' do
    before do
      mail.content_type = 'text/html'
    end

    it 'deliver message to Kafka' do
      expected_result = {
        header: {},
        subject: 'Hello, world!',
        from: ['luong@handsome.rich'],
        to: ['luong@lord.lol'],
        cc: ['luong@checkmate.com'],
        bcc: ['luong@overpower.invincible'],
        mime_type: 'text/html',
        body: '',
        attachments: []
      }
      mailer.deliver!(mail)
      expect(fake_kafka_producer.queue[topic]).to include_json(expected_result)
    end
  end

  context 'there is a friendly name to' do
    before do
      mail.to = 'Luong Shiba <luong@shiba.inu>'
    end

    it 'deliver message to Kafka' do
      expected_result = {
        header: {},
        subject: 'Hello, world!',
        from: ['luong@handsome.rich'],
        to: ['luong@shiba.inu'],
        cc: ['luong@checkmate.com'],
        bcc: ['luong@overpower.invincible'],
        body: '',
        attachments: []
      }
      mailer.deliver!(mail)
      expect(fake_kafka_producer.queue[topic]).to include_json(expected_result)
    end
  end

  context 'email contains headers' do
    before do
      mail['headers'] = { 'X-Luong' => 'dog' }
    end

    it 'deliver message to Kafka' do
      expected_result = {
        header: { 'X-Luong' => 'dog' },
        subject: 'Hello, world!',
        from: ['luong@handsome.rich'],
        to: ['luong@lord.lol'],
        cc: ['luong@checkmate.com'],
        bcc: ['luong@overpower.invincible'],
        body: '',
        attachments: []
      }
      mailer.deliver!(mail)
      expect(fake_kafka_producer.queue[topic]).to include_json(expected_result)
    end
  end

  context 'email is multipart' do
    before do
      mail.content_type 'multipart/alternative'
      mail.part do |part|
        part.text_part = Mail::Part.new do
          content_type 'text/plain'
          body 'Luong dep trai.'
        end
        part.html_part = Mail::Part.new do
          content_type 'text/html'
          body 'Luong <b>dep trai</b>.'
        end
      end
    end

    it 'deliver message to Kafka' do
      expected_result = {
        subject: 'Hello, world!',
        from: ['luong@handsome.rich'],
        to: ['luong@lord.lol'],
        cc: ['luong@checkmate.com'],
        bcc: ['luong@overpower.invincible'],
        mime_type: 'multipart/alternative',
        html_part: 'Luong <b>dep trai</b>.',
        text_part: 'Luong dep trai.',
        attachments: []
      }
      mailer.deliver!(mail)
      expect(fake_kafka_producer.queue[topic]).to include_json(expected_result)
    end
  end
end
