module ActionMailerKafka
  class Error < StandardError
  end

  class RequiredParamsError < Error
    def initialize(settings_params, msg)
      super("Some required settings are missing: #{msg}. Original config: #{settings_params}")
    end
  end

  class KafkaOperationError < Error
  end

  class ParsingOperationError < Error
  end
end
