class ExampleMailer < ActionMailer::Base
  def sample_email(user)
    @user = user
    mail(to: @user.email, subject: 'Sample Email', user: @user)
  end
end
