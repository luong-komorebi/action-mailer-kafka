base_dir = File.absolute_path File.dirname File.dirname __dir__
gem 'eh-mailer', path: base_dir

environment 'config.action_mailer.raise_delivery_errors = true'
environment 'config.action_mailer.delivery_method = :eh_mailer'
environment "config.action_mailer.eh_mailer_settings = { kafka_mail_topic: 'Mail.Mails.Send' }"

run 'rm public/index.html'
route "root :to => 'home#index'"

file 'app/mailers/example_mailer.rb', <<~CODE
  class ExampleMailer < ActionMailer::Base
    def sample_email
      @some_data = {
        email: 'example@domain.com',
        user_name: 'example'
      }
      mail(to: @some_data[:email], subject: 'Sample Email', user_name: @some_data[:user_name])
    end
  end
CODE

file 'app/views/example_mailer/sample_email.html.erb', <<~CODE
  <!doctype html>
  <html>
    <head>
      <title>This is the title of the webpage!</title>
    </head>
    <body>
      <p>This is an example paragraph. Anything in the <strong>body</strong> tag will appear on the page, just like this <strong>p</strong> tag and its contents.</p>
    </body>
  </html>
CODE

file 'app/views/example_mailer/sample_email.text.erb', <<~CODE
  This is sample mail sent using smtp.
CODE

file 'app/controllers/home_controller.rb', <<~CODE
  class HomeController < ApplicationController
    def index
      ExampleMailer.sample_email.deliver!
      render plain: "OK"
    end
  end
CODE
