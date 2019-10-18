module ActionMailerKafka
  class BaseProducer
    DELIVERY_INTERVAL = 30 # trigger a delivery half a min
    BUFFER_SIZE = 20 # trigger a delivery when buffered 20 emails
    MAX_RETRIES = 2
    RETRY_BACKOFF = 5

    def initialize(
      kafka_client_info:,
      transactional_id: Socket.gethostname,
      logger: nil
    )
      @logger = logger
      kafka_client = ::Kafka.new(kafka_client_info)
      @kafka_async_producer = kafka_client.async_producer(
        delivery_threshold: BUFFER_SIZE,
        delivery_interval: DELIVERY_INTERVAL,
        max_retries: MAX_RETRIES,
        retry_backoff: RETRY_BACKOFF,
        idempotent: true,
        required_acks: :all,
        transactional_id: transactional_id
      )
    end

    def publish(data, message_key, topic)
      @kafka_async_producer.produce(data, key: message_key, topic: topic)
      @kafka_async_producer.deliver_messages
    rescue Kafka::DeliveryFailed => e
      @logger&.error("Fail to deliver some kafka messages: #{e}")
    end
  end
end
