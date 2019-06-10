module Eh
  module Mailer
    class Error < StandardError
    end

    class RequiredParamsError < Error
      def initialize(settings_params, msg)
        super("Some required settings are missing: #{msg}. Original config: #{settings_params}")
      end
    end

    class KafkaOperationError < Error
      def initialize(msg)
        super(msg)
      end
    end

    class ParsingOperationError < Error
      def initialize(msg)
        super(msg)
      end
    end
  end
end
