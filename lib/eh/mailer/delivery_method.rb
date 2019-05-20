module Eh
  module Mailer
    class DeliveryMethod
      MAILER_TOPIC_NAME = 'EmploymentHero.Emails'.freeze
      attr_accessor :message, :settings

      def kafka_client
        @kafka_client ||= KafkaWorker.new \
          kafka_producer: @settings[:kafka_client_producer],
          kafka_publish_method: @settings[:kafka_publish_method]
      end

      def logger
        @settings[:logger] || Logger.new(STDOUT)
      end

      # settings params allow you to pass in
      # 1. Your Kafka publish method
      # With this option, you should config as below:
      # config.action_mailer.eh-mailer_settings = {
      #   kafka_publish_method: proc do |message_data, default_message_topic|
      #                           YourKafkaClientInstance.publish(message_data, default_message_topic)
      #                         end
      # }
      # and the data would go through your publish method
      # 2. Your Ruby Kafka Producer or use the
      # predefined one
      # config.action_mailer.eh-mailer_settings = {
      #   kafka_client_producer: YourKafkaClientInstance.producer
      #   With this option the kafka worker would be initiated or it could reused one producer that is defined by you

      def initialize(**params)
        @settings = params
      end

      def deliver!(mail)
        mail_data = construct_mail_data mail
        kafka_client._publish_message(mail_data, MAILER_TOPIC_NAME)
      rescue StandardError => e
        raise if @settings[:raise_on_delivery_error]

        logger.error("Fail to send email due to: #{e.message}")
      end

      private

      def construct_mail_data(mail)
        general_data = {
          subject: mail.subject,
          from: mail.from,
          to: mail.to,
          cc: mail.cc,
          bcc: mail.bcc,
          mime_type: mail.mime_type
        }
        general_data.merge! construct_mail_body(mail)
        general_data.merge! construct_mail_header(mail)
        general_data[:attachments] = construct_attachments mail
        general_data.to_json
      end

      def construct_mail_header(mail)
        if mail['headers']
          { header: mail['headers'].unparsed_value }
        else
          { header: {} }
        end
      end

      def construct_attachments(mail)
        mail.attachments.map { |part| convert_attachment part }
      end

      def convert_attachment(part)
        {
          content: Base64.strict_encode64(part.body.decoded),
          type: part.mime_type,
          filename: part.filename
        }
      end

      def construct_mail_body(mail)
        if ['multipart/alternative', 'multipart/mixed', 'multipart/related'].include?(mail.mime_type)
          {
            text_part: mail.text_part&.decoded,
            html_part: mail.html_part&.decoded
          }
        else
          { body: mail.body&.decoded }
        end
      end
    end
  end
end
