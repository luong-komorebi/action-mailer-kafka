lib = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eh/mailer/version'

abort('Development Gem must have .dev in version') unless Eh::Mailer::VERSION.include?('dev')

exec("gem build eh-mailer.gemspec && curl -F package=@eh-mailer-#{Eh::Mailer::VERSION}.gem https://#{ENV['GEMFURY_TOKEN']}@push.fury.io/#{ENV['GEMFURY_PACKAGE']}/")
