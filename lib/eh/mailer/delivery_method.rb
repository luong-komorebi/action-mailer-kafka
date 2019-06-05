module Eh
  module Mailer
    class DeliveryMethod
      SUPPORTED_MULTIPART_MIME_TYPES = ['multipart/alternative', 'multipart/mixed', 'multipart/related'].freeze
      attr_accessor :message, :settings
      attr_reader :mailer_topic_name

      # settings params allow you to pass in
      # 1. Your Kafka publish proc
      # With this option, you should config as below:
      # config.action_mailer.eh_mailer_settings = {
      #   kafka_publish_proc: proc do |message_data, default_message_topic|
      #                           YourKafkaClientInstance.publish(message_data,
      #                                                           default_message_topic)
      #                         end
      # }
      #
      # and the data would go through your publish process
      #
      # 2. Your Ruby Kafka Producer or use the predefined one
      # config.action_mailer.eh_mailer_settings = {
      #   kafka_mail_topic: 'YourKafkaTopic',
      #   kafka_client_producer: YourKafkaClientInstance.producer
      #   # With this option the kafka worker would be initiated or
      #   # it could reused one producer that is defined by you
      #   # Other settings params:
      #   # - raise_on_delivery_error
      #   # - logger
      #   # - fallback
      #   # + fallback_delivery_method
      #   # + fallback_delivery_method_settings
      #   }

      def initialize(**params)
        @settings = params
        if @settings[:kafka_mail_topic].empty?
          raise StandardError, 'No kafka topic specify'
        end

        @mailer_topic_name = @settings[:kafka_mail_topic]
        if @settings[:fallback]
          @fallback_delivery_method = Mail::Configuration.instance.lookup_delivery_method(
            @settings[:fallback][:fallback_delivery_method]
          ).new(
            @settings[:fallback][:fallback_delivery_method_settings]
          )
        end
      end

      def kafka_client
        @kafka_client ||= KafkaWorker.new \
          kafka_producer: @settings[:kafka_client_producer],
          kafka_publish_proc: @settings[:kafka_publish_proc]
      end

      def logger
        @settings[:logger] || Logger.new(STDOUT)
      end

      def deliver!(mail)
        mail_data = construct_mail_data mail
        kafka_client.publish_message(mail_data, mailer_topic_name)
      rescue Kafka::Error => e
        raise if @settings[:raise_on_delivery_error]

        @fallback_delivery_method.deliver!(mail)
        logger.error("Fail to send email into Kafka due to: #{e.message}. Delivered using fallback method")
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
        general_data.merge! construct_custom_mail_header(mail)
        general_data[:attachments] = construct_attachments mail
        general_data.to_json
      end

      def construct_custom_mail_header(mail)
        result = { header: {} }
        mail.header_fields.each do |h|
          if h.field.is_a?(::Mail::OptionalField)
            result[:header][h.name] = h.value
          end
        end
        result
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
        if SUPPORTED_MULTIPART_MIME_TYPES.include?(mail.mime_type)
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
