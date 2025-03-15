require 'sinatra'
require 'json'
require 'tempfile'
require 'fileutils'
require_relative 'lib/html_to_pdf_converter'
require_relative 'lib/docx_converter'
require 'logger'
require 'sinatra/json'

# Настройки для загрузки файлов
configure do
  enable :logging
  set :server, :puma
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :views, File.join(Dir.pwd, 'views')
  # Увеличиваем лимит на размер файла до 10 МБ
  set :max_file_size, 10 * 1024 * 1024
  set :logger, Logger.new(STDOUT)
end

# Создаем директории если их нет
['public', 'public/uploads', 'public/pdf', 'public/generated_pdfs', 'views'].each do |dir|
  Dir.mkdir(dir) unless Dir.exist?(dir)
end

# Очистка старых файлов
def cleanup_old_files
  threshold = Time.now - 3600 # 1 час

  [
    File.join(settings.public_folder, 'uploads', '*'),
    File.join(settings.public_folder, 'pdf', '*'),
    File.join(settings.public_folder, 'generated_pdfs', '*')
  ].each do |pattern|
    Dir[pattern].each do |file|
      FileUtils.rm(file) if File.mtime(file) < threshold
    end
  end
end

before do
  # Логируем все входящие запросы
  puts "\n=== Новый запрос ==="
  puts "Метод: #{request.request_method}"
  puts "Путь: #{request.path}"
  puts "Параметры: #{params.inspect}"
end

get '/' do
  cleanup_old_files
  erb :index
end

post '/convert' do
  content_type :json
  
  begin
    # Получаем HTML контент
    html_content = params[:html_content]
    return json error: 'HTML код не был предоставлен' unless html_content
    
    # Получаем и парсим переменные
    variables = {}
    if params[:variables]
      begin
        variables = JSON.parse(params[:variables])
        puts "\n=== Переменные шаблона ==="
        puts "Количество переменных: #{variables.size}"
        variables.each do |key, value|
          puts "#{key}: #{value}"
        end
        puts "========================\n"
      rescue JSON::ParserError => e
        puts "Ошибка парсинга JSON переменных: #{e.message}"
        return json error: 'Ошибка при обработке переменных'
      end
    end
    
    # Получаем параметры страницы
    options = {
      'page-size' => params[:page_size] || 'A4',
      'margin-top' => params[:margin_top] || '20mm',
      'margin-right' => params[:margin_right] || '20mm',
      'margin-bottom' => params[:margin_bottom] || '20mm',
      'margin-left' => params[:margin_left] || '20mm',
      'encoding' => 'UTF-8'
    }
    
    # Создаем временный файл для PDF
    pdf_file = Tempfile.new(['output', '.pdf'])
    pdf_path = pdf_file.path
    
    # Создаем временный HTML файл
    filename = "document_#{SecureRandom.hex(8)}"
    html_path = File.join(settings.public_folder, 'uploads', "#{filename}.html")
    
    # Сохраняем HTML в файл
    File.write(html_path, html_content, encoding: 'UTF-8')
    
    # Конвертируем HTML в PDF
    if HtmlToPdfConverter.convert_html(html_path, pdf_path, options, variables)
      # Создаем директорию если её нет
      generated_pdfs_dir = File.join('public', 'generated_pdfs')
      FileUtils.mkdir_p(generated_pdfs_dir)

      # Генерируем имя файла для PDF
      output_filename = "output_#{Time.now.to_i}.pdf"
      public_pdf_path = File.join(generated_pdfs_dir, output_filename)

      begin
        # Копируем файл вместо перемещения
        FileUtils.cp(pdf_path, public_pdf_path)
        
        # Проверяем, что файл успешно скопирован
        unless File.exist?(public_pdf_path)
          raise "Не удалось создать файл в директории #{generated_pdfs_dir}"
        end

        # Возвращаем URL для доступа к PDF
        json success: true, pdf_url: "/generated_pdfs/#{output_filename}"
      rescue => e
        logger.error "Ошибка при копировании файла: #{e.message}"
        json success: false, error: "Ошибка при сохранении PDF: #{e.message}"
      end
    else
      json success: false, error: 'Ошибка при конвертации HTML в PDF'
    end
  rescue => e
    json success: false, error: e.message
  ensure
    # Удаляем временные файлы
    File.delete(html_path) if defined?(html_path) && File.exist?(html_path)
    if defined?(pdf_file) && pdf_file
      pdf_file.close
      pdf_file.unlink
    end
    
    # Периодически очищаем старые файлы
    cleanup_old_files if rand < 0.1 # 10% шанс очистки при каждом запросе
  end
end

post '/convert_docx' do
  begin
    logger.info "Начало обработки DOCX файла"
    
    unless params[:docx_file]
      logger.error "Файл не был загружен"
      halt 400, 'Файл не был загружен'
    end

    temp_file = params[:docx_file][:tempfile]
    original_filename = params[:docx_file][:filename].force_encoding('UTF-8')
    
    logger.info "Загружен файл: #{original_filename}"
    logger.info "Временный путь: #{temp_file.path}"
    
    begin
      html_content = DocxConverter.convert(temp_file.path)
      logger.info "Конвертация успешно завершена"
      
      content_type 'text/html; charset=utf-8'
      html_content
    rescue => e
      logger.error "Ошибка при конвертации: #{e.message}"
      logger.error e.backtrace.join("\n")
      halt 500, "Ошибка при конвертации: #{e.message}"
    ensure
      temp_file.close
      temp_file.unlink
    end
  rescue => e
    logger.error "Необработанная ошибка: #{e.message}"
    logger.error e.backtrace.join("\n")
    halt 500, "Внутренняя ошибка сервера: #{e.message}"
  end
end 