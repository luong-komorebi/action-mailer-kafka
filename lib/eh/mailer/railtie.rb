module Eh
  module Mailer
    class Railtie < Rails::Railtie
      initializer 'eh_mailer.add_delivery_method', before: 'action_mailer.set_configs' do
        ActionMailer::Base.add_delivery_method :eh_mailer, Eh::Mailer::DeliveryMethod
      end
    end
  end
end
