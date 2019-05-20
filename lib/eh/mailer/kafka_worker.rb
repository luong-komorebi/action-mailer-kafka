module Eh
  module Mailer
    class KafkaWorker
      attr_reader :producer

      def initialize(kafka_producer: nil, kafka_publish_method: nil)
        @kafka_publish_method = kafka_publish_method
        if @kafka_publish_method.nil?
          @kafka_producer = kafka_producer || ::Kafka.new(kafka_client_info).producer
        end
      end

      def kafka_client_info
        logger = Logger.new(STDOUT)
        logger.level = (ENV['LOG_LEVEL'] || Logger::INFO).to_i
        kafka_broker = ENV['KAFKA_BROKERS'] || 'localhost:9092'
        info = {
          seed_brokers: kafka_broker.to_s.split(','),
          logger: logger
        }
        if !ENV['KAFKA_CA_FILE'].nil?
          info.merge!(
            ssl_ca_cert: File.read(ENV['KAFKA_CA_FILE']),
            ssl_client_cert: File.read(ENV['KAFKA_CERT_FILE']),
            ssl_client_cert_key: File.read(ENV['KAFKA_CERT_KEY_FILE'])
          )
        elsif !ENV['KAFKA_CA'].nil?
          info.merge!(
            ssl_ca_cert: ENV['KAFKA_CA'],
            ssl_client_cert: ENV['KAFKA_CERT'],
            ssl_client_cert_key: ENV['KAFKA_CERT_KEY']
          )
        end
        info
      end

      def _publish_message(data, topic)
        if @kafka_publish_method
          @kafka_publish_method.call(data, topic)
        else
          @kafka_producer.produce(data, topic: topic)
          @kafka_producer.deliver_messages
        end
      end
    end
  end
end
