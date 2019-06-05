require 'spec_helper'

describe Eh::Mailer::DeliveryMethod do
  let(:mail) do
    Mail.new \
      from: 'luong@handsome.rich',
      subject: 'Hello, world!',
      bcc: 'luong@overpower.invincible',
      cc: 'luong@checkmate.com',
      to: 'luong@lord.lol'
  end
  let(:topic) { 'Mail.Mails.Send' }

  context 'when mailer use a kafka publish method defined by user' do
    let(:mailer) do
      described_class.new(kafka_publish_proc: proc { |message, topic| [message, topic] }, kafka_mail_topic: topic)
    end

    context 'when email is plain text' do
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
        result = mailer.deliver!(mail)
        expect(result.first).to include_json(expected_result)
        expect(result.last).to eq(topic)
      end
    end
  end

  context 'when mailer use a kafka publish method defined by user' do
    let(:fake_kafka_producer) { FakeKafkaProducer.new }
    let(:mailer) do
      described_class.new(kafka_client_producer: fake_kafka_producer, kafka_mail_topic: topic)
    end

    context 'when email is plain text' do
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
        mail.body = FakeKafkaProducer::SECRET_STANDARD_ERROR_TRIGGER
      end

      context 'when raise on delivery option is set' do
        let(:mailer) do
          described_class.new(kafka_client_producer: fake_kafka_producer, kafka_mail_topic: topic)
        end

        let(:logger_instance) { instance_double(Logger) }

        before do
          allow(Logger).to receive(:new).and_return(logger_instance)
          allow(logger_instance).to receive(:error)
        end

        it 'log the error and raise exception' do
          mailer.deliver!(mail)
          expect(logger_instance).to have_received(:error)
        end
      end

      context 'when raise on delivery option is not set' do
        let(:mailer) do
          described_class.new(kafka_client_producer: fake_kafka_producer, raise_on_delivery_error: true, kafka_mail_topic: topic)
        end

        it 'log the error and raise exception' do
          expect { mailer.deliver!(mail) }.to raise_error(StandardError)
        end
      end
    end

    context 'when email is html' do
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

    context 'when there is a friendly name to' do
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

    context 'when email contains custom headers' do
      before do
        mail.headers('X-Luong': 'golden', 'X-Hoa': 'husky')
      end

      it 'deliver message to Kafka' do
        expected_result = {
          header: { 'X-Luong' => 'golden', 'X-Hoa' => 'husky' },
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

    context 'when email is multipart' do
      before do
        mail.content_type = 'multipart/alternative'
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

    context 'when email raises Kafka exception' do
      let(:fake_kafka_producer) { FakeKafkaProducer.new }

      context 'when fallback is set' do
        let(:mailer) do
          described_class.new(
            kafka_mail_topic: topic,
            kafka_client_producer: fake_kafka_producer,
            fallback: {
              fallback_delivery_method: :smtp,
              fallback_delivery_method_settings: {
                :address => 'localhost',
                :port => 25,
                :domain => 'localhost.localdomain',
                :user_name => nil,
                :password => nil,
                :authentication => nil,
                :enable_starttls => nil,
                :enable_starttls_auto => true,
                :openssl_verify_mode => nil,
                :tls => nil,
                :ssl => nil,
                :open_timeout => nil,
                :read_timeout => nil
              }
            }
          )
        end

        before do
          mail.content_type = 'text/plain'
          mail.body = FakeKafkaProducer::SECRET_KAFKA_ERROR_TRIGGER
        end

        it 'use fallback method' do
          mailer.deliver! mail
          message = MockSMTP.deliveries.first
          expect(Mail.new(message).decoded).to eq(FakeKafkaProducer::SECRET_KAFKA_ERROR_TRIGGER)
        end
      end

      context 'when fallback is not set' do
        let(:mailer) do
          described_class.new(
            kafka_client_producer: fake_kafka_producer,
            raise_error_on_delivery: true,
            kafka_mail_topic: topic
          )
        end

        before do
          mail.content_type = 'text/plain'
          mail.body = FakeKafkaProducer::SECRET_KAFKA_ERROR_TRIGGER
        end

        it 'raise an error' do
          expect { mailer.deliver!(mail) }.to raise_error(StandardError)
        end
      end
    end
  end
end
