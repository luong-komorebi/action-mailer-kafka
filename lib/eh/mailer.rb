require 'eh/mailer/version'
require 'eh/mailer/railtie' if defined? Rails

module Eh
  module Mailer
    class Delivery
      attr_accessor :message

      def initialize(**params)
        @params = params
      end

      def deliver!(mail)
        puts "from #{mail.from}"
        puts "to #{mail.to}"

        mail.parts.each do |m|
          puts "Content: #{m.body}"
        end
      end
    end
  end
end
