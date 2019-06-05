module Eh
  module Mailer
    class KafkaWorker
      attr_reader :producer

      def initialize(kafka_client_info: nil, kafka_producer: nil, kafka_publish_proc: nil)
        @kafka_publish_proc = kafka_publish_proc
        if @kafka_publish_proc.nil?
          @kafka_producer = kafka_producer || ::Kafka.new(kafka_client_info).producer
        end
      end

      def publish_message(data, topic)
        if @kafka_publish_proc
          @kafka_publish_proc.call(data, topic)
        else
          @kafka_producer.produce(data, topic: topic)
          @kafka_producer.deliver_messages
        end
      end
    end
  end
end
