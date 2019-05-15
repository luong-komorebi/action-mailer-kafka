require 'json'
require 'kafka'
require 'mail'
require 'eh/mailer/railtie' if defined? Rails
require 'eh/mailer/kafka_worker'
require 'eh/mailer/delivery_method'

module Eh
  module Mailer
  end
end
