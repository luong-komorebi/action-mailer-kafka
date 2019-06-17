module Eh
  module Mailer
    class DeliveryMethod
      SUPPORTED_MULTIPART_MIME_TYPES = ['multipart/alternative', 'multipart/mixed', 'multipart/related'].freeze
      attr_accessor :message, :settings
      attr_reader :mailer_topic_name, :kafka_client, :kafka_publish_proc

      # settings params allow you to pass in
      # 1. Your Kafka publish proc
      # With this option, you should config as below:
      # config.action_mailer.eh_mailer_settings = {
      #   kafka_mail_topic: 'YourKafkaTopic',
      #   kafka_publish_proc: proc do |message_data, default_message_topic|
      #                           YourKafkaClientInstance.publish(message_data,
      #                                                           default_message_topic)
      #                         end
      # }
      #
      # and the data would go through your publish process
      #
      # 2. Your kafka client info
      # With this option, the library will generate a kafka instance for you:
      # config.action_mailer.eh_mailer_settings = {
      #   kafka_mail_topic: 'YourKafkaTopic',
      #   kafka_client_info: {
      #     seed_brokers: ['localhost:9090'],
      #     logger: logger,
      #     ssl_ca_cert: '/path/to/cert'
      #     # For more option on what to pass here, see https://github.com/zendesk/ruby-kafka/blob/master/lib/kafka/client.rb#L20
      #   }
      # }
      #
      # Other settings params:
      #   - raise_on_delivery_error
      #   - logger
      #   - fallback
      #     + fallback_delivery_method
      #     + fallback_delivery_method_settings
      #   }

      def initialize(**params)
        @settings = params
        @mailer_topic_name = @settings.fetch(:kafka_mail_topic)
        if @settings[:fallback]
          @fallback_delivery_method = Mail::Configuration.instance.lookup_delivery_method(
            @settings[:fallback].fetch(:fallback_delivery_method)
          ).new(
            @settings[:fallback].fetch(:fallback_delivery_method_settings)
          )
        end
        if @settings[:kafka_publish_proc]
          @kafka_publish_proc = @settings[:kafka_publish_proc]
        else
          @kafka_client = ::Kafka.new(@settings.fetch(:kafka_client_info))
          @kafka_publish_proc = proc { |data, topic|
            kafka_client.deliver_message(data, topic: topic)
          }
        end
      rescue KeyError => e
        raise RequiredParamsError.new(params, e.message)
      end

      def logger
        @settings[:logger] || Logger.new(STDOUT)
      end

      def deliver!(mail)
        mail_data = construct_mail_data mail
        kafka_publish_proc.call(mail_data, mailer_topic_name)
      rescue Kafka::Error => e
        error_msg = "Fail to send email into Kafka due to: #{e.message}. Delivered using fallback method"
        logger.error(error_msg)
        @fallback_delivery_method.deliver!(mail) if @settings[:fallback]
        raise KafkaOperationError, error_msg if @settings[:raise_on_delivery_error]
      rescue StandardError => e
        error_msg = "Fail to send email due to: #{e.message}"
        logger.error(error_msg)
        raise ParsingOperationError, error_msg if @settings[:raise_on_delivery_error]
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
        result = { custom_headers: {} }
        mail.header_fields.each do |h|
          header_name = h.name
          # header_value = h.unparsed_value
          # Ideally header values should not be parsed and sent directly to the mail service
          # However, Field #unparsed_value is not available on Mail Gem version 2.5 and before
          # here header.value got its value parsed, so a string should be expected
          # even if you create a custom header with a hash
          header_value = h.value
          if h.field.is_a?(::Mail::OptionalField) && header_name.start_with?('X-')
            result[:custom_headers][header_name] = header_value
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
