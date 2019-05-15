require 'json'

manifest_path = File.expand_path('../../app.json', __FILE__)
version = JSON.parse(File.read(manifest_path))['version']

abort('Development Gem must have .dev in version') unless version.include?('dev')

exec("gem build eh_monitoring.gemspec && curl -F package=@eh_monitoring-#{version}.gem https://#{ENV['GEMFURY_TOKEN']}@push.fury.io/#{ENV['GEMFURY_PACKAGE']}/")
