require 'dotenv/load'
require 'logger'
require './app'

# Настройка логирования
$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO

# Middleware для обработки ошибок
class ErrorHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue => e
      $logger.error "Error: #{e.message}\n#{e.backtrace.join("\n")}"
      [500, {'Content-Type' => 'text/html'}, ["Произошла ошибка на сервере. Пожалуйста, попробуйте позже."]]
    end
  end
end

# Middleware для логирования запросов
class RequestLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    start_time = Time.now
    status, headers, body = @app.call(env)
    end_time = Time.now

    $logger.info "#{env['REQUEST_METHOD']} #{env['PATH_INFO']} - #{status} (#{end_time - start_time}s)"
    
    [status, headers, body]
  end
end

# Настройка временных файлов
require 'tmpdir'
require 'fileutils'

temp_dir = File.join(Dir.tmpdir, 'docx_converter')
FileUtils.mkdir_p(temp_dir)
ENV['TMPDIR'] = temp_dir

# Очистка старых временных файлов
Thread.new do
  loop do
    begin
      threshold = Time.now - 3600 # 1 час
      Dir.glob(File.join(temp_dir, '*')).each do |file|
        FileUtils.rm_f(file) if File.mtime(file) < threshold
      end
    rescue => e
      $logger.error "Error cleaning temp files: #{e.message}"
    end
    sleep 3600 # Проверяем каждый час
  end
end

use ErrorHandler
use RequestLogger
use Rack::CommonLogger, $logger
use Rack::ShowExceptions if ENV['RACK_ENV'] == 'development'

run Sinatra::Application 