module Eh
  module Mailer
    class DeliveryMethod
      MAILER_TOPIC_NAME = 'EmploymentHero.Emails'.freeze
      attr_accessor :message

      def kafka_client
        @kafka_client ||= KafkaWorker.new @params[:kafka_client_producer]
      end

      def initialize(**params)
        @params = params
      end

      def deliver!(mail)
        mail_data = construct_mail_data mail
        kafka_client.publish_message(mail_data, MAILER_TOPIC_NAME)
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
        general_data.merge!construct_mail_header(mail)
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
        if mail.mime_type == 'multipart/alternative'
          {
            text_part: mail.text_part.decoded,
            html_part: mail.html_part.decoded
          }
        else
          { body: mail.body.decoded }
        end
      end
    end
  end
end
