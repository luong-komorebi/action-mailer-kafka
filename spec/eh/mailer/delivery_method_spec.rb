require 'spec_helper'

describe Eh::Mailer::DeliveryMethod do
  class FakeKafka
    attr_reader :queue

    def initialize
      @queue = {}
    end

    def publish(package, topic)
      queue[topic] = package
    end
  end

  let(:mail) do
    Mail.new(
      to: 'test@luong.com',
      from: 'luong@handsome.rich',
      subject: 'Hello, world!',
      bcc: 'luong@overpower.invincible',
      cc: 'luong@checkmate.com',
      to: 'luong@lord.lol'
    )
  end
  let(:topic) { Eh::Mailer::DeliveryMethod::MAILER_TOPIC_NAME }
  let(:mailer) {
    described_class.new(kafka_client: FakeKafka.new, kafka_publish_method: :publish)
  }

  context 'email is plain text' do
    before do
      mail.content_type = 'text/plain'
    end

    it 'deliver message to Kafka' do
      mailer.deliver!(mail)
      expect(FakeKafka.queue[topic]).to eq({

      })
    end
  end

  context 'email is html' do
    before do
      mail.content_type = 'text/html'
    end
  end
end
