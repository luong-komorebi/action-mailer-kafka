require 'json'

manifest_path = File.expand_path('../../app.json', __FILE__)
version = JSON.parse(File.read(manifest_path))['version']

exec("gem build eh-mailer.gemspec && curl -F package=@eh-mailer-#{version}.gem https://#{ENV['GEMFURY_TOKEN']}@push.fury.io/#{ENV['GEMFURY_PACKAGE']}/")
