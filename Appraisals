if ENV['INTEGRATION_TEST']
  appraise "rails-4" do
    gem "rails", "~> 4.0"
  end

  appraise "rails-5" do
    gem "rails", "~> 5.0"
  end
else
  appraise "mail-2-5" do
    gem "mail", "~> 2.5.2"
  end

  appraise "mail-2-6" do
    gem "mail", "~> 2.6.0"
  end

  appraise "mail-2-7" do
    gem "mail", "~> 2.7.0"
  end
end
