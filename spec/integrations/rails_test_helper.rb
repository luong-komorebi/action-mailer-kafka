require 'rails'
require 'faraday'
require 'fileutils'
require 'open3'
require 'socket'
require 'timeout'

module RailsTestHelper
  APP_NAME = 'railstest'.freeze
  TEMPLATE_PATH = File.absolute_path(File.join(__dir__, 'rails_app_template.rb'))
  BASE_DIR = File.dirname File.dirname __dir__
  TMP_DIR = File.join BASE_DIR, 'tmp'
  APP_DIR = File.join TMP_DIR, APP_NAME
  RAILS_OPTIONS = %w[
    --skip-yarn
    --skip-active-record
    --skip-action-cable
    --skip-puma
    --skip-sprockets
    --skip-spring
    --skip-listen
    --skip-coffee
    --skip-javascript
    --skip-turbolinks
    --skip-test
    --skip-system-test
    --skip-bundle
  ].join ' '

  class << self
    def create_rails_app
      puts '**** Creating test Rails app...'
      FileUtils.mkdir_p TMP_DIR
      FileUtils.rm_rf APP_DIR
      Dir.chdir TMP_DIR do
        system "bundle exec rails new #{APP_NAME} #{RAILS_OPTIONS} -m #{TEMPLATE_PATH}"
      end
      Dir.chdir APP_DIR do
        Bundler.with_original_env do
          original_gemfile = ENV.delete 'BUNDLE_GEMFILE'
          begin
            system 'bundle lock'
            system 'bundle install --without development,test'
          ensure
            ENV['BUNDLE_GEMFILE'] = original_gemfile if original_gemfile
          end
        end
      end
      puts '**** Finished creating test Rails app'
    end

    def run_rails_app(timeout: 10)
      Dir.chdir APP_DIR do
        Bundler.with_original_env do
          Open3.popen2e 'bundle exec rails s -b 0.0.0.0 -p 3000' do |stdin, stdout, thr|
            begin
              Timeout.timeout timeout do
                loop do
                  # line = stdout.gets
                  # break if !line || line =~ /WEBrick::HTTPServer#start/
                  break if begin
                             TCPSocket.open('localhost', 3000)
                           rescue StandardError
                             nil
                           end

                  puts 'Waiting for rails....'
                  sleep 1
                end
                puts 'Rails server started'
                yield stdout if block_given?
              end
            rescue Timeout::Error
              puts "Timeout #{thr.value}"
            rescue StandardError => e
              puts e.message
              exit 1
            ensure
              puts 'Killing rails server process'
              Process.kill('INT', thr.pid)
              puts 'Rails server killed'
              stdin.close
              stdout.close
            end
          end
        end
      end
    end

    # def capture_in_rails_context(cmd, timeout: 5)
    #   result = nil
    #   Dir.chdir APP_DIR do
    #     Bundler.with_original_env do
    #       Timeout.timeout timeout do
    #         result = `#{cmd}`
    #       end
    #     end
    #   end
    #   result
    # end

    def rails_request(path)
      resp = Faraday.get "http://localhost:3000#{path}"
      puts "Request with Faraday responds: #{resp.inspect}"
      resp.status.to_s
    end
  end
end
