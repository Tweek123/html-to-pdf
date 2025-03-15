require 'aspose_words_cloud'

class DocxConverter
  class << self
    def convert(docx_path)
      begin
        # Проверяем наличие ключей API
        unless ENV['ASPOSE_APP_SID'] && ENV['ASPOSE_APP_KEY']
          raise "Отсутствуют ключи API Aspose. Установите переменные окружения ASPOSE_APP_SID и ASPOSE_APP_KEY"
        end

        # Настраиваем конфигурацию API
        AsposeWordsCloud.configure do |config|
          config.client_data['ClientId'] = ENV['ASPOSE_APP_SID']
          config.client_data['ClientSecret'] = ENV['ASPOSE_APP_KEY']
        end

        # Создаем экземпляр API
        words_api = AsposeWordsCloud::WordsApi.new

        # Открываем файл и создаем запрос на конвертацию
        doc = File.open(docx_path)
        request = AsposeWordsCloud::ConvertDocumentRequest.new(
          document: doc,
          format: 'html'
        )

        # Выполняем конвертацию
        result = words_api.convert_document(request)
        
        # Создаем имя файла для HTML на основе имени DOCX
        html_path = docx_path.sub(/\.docx$/i, '.html')
        
        # Сохраняем HTML в файл
        File.write(html_path, result)
        puts "HTML сохранен в файл: #{html_path}"
        
        result
      rescue => e
        raise "Ошибка конвертации DOCX: #{e.message}"
      ensure
        doc&.close if defined?(doc)
      end
    end
  end
end 