module ActionMailerKafka
  class Railtie < Rails::Railtie
    initializer 'action_mailer_kafka.add_delivery_method', before: 'action_mailer.set_configs' do
      ActionMailer::Base.add_delivery_method :action_mailer_kafka, ActionMailerKafka::DeliveryMethod
    end
  end
end
