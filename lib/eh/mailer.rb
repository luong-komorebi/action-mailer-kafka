require 'eh/mailer/version'
require 'eh/mailer/railtie' if defined? Rails
require 'json'
require 'kafka'
require_relative './kafka_worker'

module Eh
  module Mailer
    class DeliveryMethod
      MAILER_TOPIC_NAME = 'EmploymentHero.Emails'.freeze
      attr_accessor :message

      def kafka_client
        @kafka_client ||= KafkaWorker.new(@params[:kafka_client])
      end

      def initialize(**params)
        @params = params
      end

      def deliver!(mail)
        mail_data = mail.to_json
        if @params[:kafka_publish_method]
          package_data = { message: mail_data, topic: MAILER_TOPIC_NAME }
          kafka_client.send(@params[:kafka_publish_method], package_data)
        else
          kafka_client._publish_message(mail_data, MAILER_TOPIC_NAME)
        end
      end
    end
  end
end
