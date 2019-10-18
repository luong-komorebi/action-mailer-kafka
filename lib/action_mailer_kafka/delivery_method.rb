module ActionMailerKafka
  class DeliveryMethod
    SUPPORTED_MULTIPART_MIME_TYPES = ['multipart/alternative', 'multipart/mixed', 'multipart/related'].freeze

    attr_accessor :settings

    # settings params allow you to pass in
    # 1. Your Kafka publisher
    # With this option, you pass an instance of Kafka Publisher, which inherit
    # from our ActionMailerKafka::BasesProducer or at least support the method
    # `publish` with the same parameters. After that, your should be as below:
    # config.action_mailer.eh_mailer_settings = {
    #   kafka_mail_topic: 'YourKafkaTopic',
    #   kafka_publisher: PublisherKlass.new
    # }
    # and the data would go through your publisher instance
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
    # 3. There is an environment variable: EH_MAILER_FORCE_FALLBACK that forces every mail
    # delivery to use the fallback method. This environment variable is used to buy
    # you some time to fix the mail service in case of incidents.

    def initialize(**params)
      @settings = params
      # Optional config
      @logger = settings[:logger]
      @raise_on_delivery_error = settings[:raise_on_delivery_error]

      # General configuration
      @service_name = settings[:service_name] || ENV['APP_NAME']
      @mailer_topic_name = settings.fetch(:kafka_mail_topic)
      @kafka_publisher = settings[:kafka_publisher] || ActionMailerKafka::BaseProducer.new(
        logger: @logger, kafka_client_info: settings[:kafka_client_info]
      )

      # Fallback configuration
      @fallback = settings[:fallback]
      if @fallback
        @fallback_delivery_method = Mail::Configuration.instance.lookup_delivery_method(
          @fallback.fetch(:fallback_delivery_method)
        ).new(
          @fallback.fetch(:fallback_delivery_method_settings)
        )
      end
    rescue KeyError => e
      raise RequiredParamsError.new(settings, e.message)
    end

    def deliver!(mail)
      mail_data = construct_mail_as_kafka_message(mail)
      @kafka_publisher.publish(mail_data, construct_message_key, @mailer_topic_name)
    rescue Kafka::Error => e
      error_msg = "Fail to send email into Kafka due to: #{e.message}. Delivered using fallback method"
      @logger&.error(error_msg)
      @fallback_delivery_method.deliver!(mail) if @fallback
      raise KafkaOperationError, error_msg if @raise_on_delivery_error
    rescue StandardError => e
      error_msg = "Fail to send email due to: #{e.message}"
      @logger&.error(error_msg)
      raise ParsingOperationError, error_msg if @raise_on_delivery_error
    end

    private

    def construct_mail_as_kafka_message(mail)
      general_data = {
        subject: mail.subject,
        from: mail.from,
        to: mail.to,
        cc: mail.cc,
        bcc: mail.bcc,
        mime_type: mail.mime_type,
        author: @service_name
      }
      general_data.merge! construct_mail_body(mail)
      general_data.merge! construct_custom_mail_header(mail)
      general_data[:attachments] = construct_attachments mail
      general_data.to_msgpack
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

    def construct_message_key
      # shamelessly copy from https://www.rubydoc.info/github/mikel/mail/Mail%2FUtilities:generate_message_id
      # because some 'mail' version doesn't have this function
      "<#{Mail.random_tag}@#{::Socket.gethostname}.mail>"
    end
  end
end
