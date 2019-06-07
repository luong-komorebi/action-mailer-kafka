require 'json'
require 'kafka'
require 'mail'
require 'eh/mailer/error'
require 'eh/mailer/railtie' if defined? Rails
require 'eh/mailer/delivery_method'
require 'eh/mailer/version'

module Eh
  module Mailer
  end
end
