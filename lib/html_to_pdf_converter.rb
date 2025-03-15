require 'tempfile'
require 'erb'
require 'ostruct'
require 'securerandom'

class HtmlToPdfConverter
  class << self
    def convert(html_content, output_path, options = {})
      begin
        # Создаем временный файл в текущей директории
        temp_file = File.join(Dir.pwd, "temp.html")
        File.write(temp_file, html_content, encoding: 'UTF-8')

        # Путь к wkhtmltopdf
        wkhtmltopdf = 'C:\\Program Files\\wkhtmltopdf\\bin\\wkhtmltopdf.exe'
        
        # Проверяем существование файла
        unless File.exist?(wkhtmltopdf)
          puts "Ошибка: wkhtmltopdf не найден по пути #{wkhtmltopdf}"
          puts "Пожалуйста, установите wkhtmltopdf с сайта https://wkhtmltopdf.org/downloads.html"
          return false
        end

        # Формируем команду для wkhtmltopdf
        cmd_options = build_options(options)
        command = "\"#{wkhtmltopdf}\" #{cmd_options} \"#{temp_file}\" \"#{output_path}\""

        puts "Выполняем команду: #{command}"
        
        # Выполняем конвертацию
        result = system(command)
        
        if result
          puts "PDF успешно создан: #{output_path}"
          true
        else
          puts "Ошибка при создании PDF"
          false
        end
      rescue => e
        puts "Ошибка при конвертации: #{e.message}"
        false
      ensure
        # Удаляем временный файл
        File.delete(temp_file) if File.exist?(temp_file)
      end
    end

    def convert_html(input, output_path, options = {}, variables = {})
      begin
        html_content = if File.exist?(input)
          # Если input это путь к файлу, читаем его содержимое
          File.read(input, encoding: 'UTF-8')
        else
          # Иначе считаем, что input это HTML строка
          input
        end

        # Обрабатываем специальные переменные
        special_options = {}
        variables.each do |key, value|
          if key.start_with?('#') && value.is_a?(Hash)
            case value['type']
            when 'watermark'
              if value['value'].include?('::after') || value['value'].include?('::before')
                # Если это CSS watermark, оставляем его для обработки в HTML
                next
              else
                special_options['--footer-center'] = value['value']
                special_options['--footer-font-size'] = '48'
                special_options['--footer-opacity'] = '0.3'
              end
            when 'header'
              special_options['--header-center'] = value['value']
              special_options['--header-font-size'] = '10'
              special_options['--header-spacing'] = '10'
            when 'footer'
              special_options['--footer-center'] = value['value']
              special_options['--footer-font-size'] = '10'
              special_options['--footer-spacing'] = '10'
            when 'page_number'
              special_options['--footer-right'] = value['value']
                .gsub('#', '[page]')
                .gsub('##', '[topage]')
            end
            variables.delete(key)
          end
        end

        # Сначала обрабатываем блочные специальные переменные
        rendered_html = html_content.gsub(/\{\{#([^}]+)\}\}(.*?)\{\{\/\1\}\}/m) do |match|
          block_name = $1.strip
          block_content = $2
          
          # Проверяем значение переменной
          if variables[block_name] == true
            # Если переменная равна true, возвращаем содержимое блока
            block_content
          else
            # Если переменная равна false или не определена, удаляем блок
            ''
          end
        end

        # Затем заменяем обычные переменные
        rendered_html = rendered_html.gsub(/\{\{([^}]+)\}\}/) do |match|
          variable_name = $1.strip
          if variable_name.include?('?')
            # Обработка тернарного оператора
            condition, true_value, false_value = variable_name.match(/(.+?)\s*\?\s*(.+?)\s*:\s*(.+)/).captures
            variable_name = condition.strip
            value = variables[variable_name] || variables[variable_name.to_sym]
            value ? true_value.strip : false_value.strip
          else
            value = variables[variable_name] || variables[variable_name.to_sym]
            case value
            when Array
              # Если значение - массив, применяем map
              if variable_name.include?('.map')
                code = variable_name.match(/\.map\((.*?)\)(?:\.join\(['"](.*)['"])?\)/).captures
                item_template, join_separator = code
                items = value.map { |item| eval("\"#{item_template}\"", binding) }
                join_separator ? items.join(join_separator) : items.join('')
              else
                value.join(', ')
              end
            when Hash
              # Пропускаем специальные переменные
              match
            else
              value.to_s
            end
          end
        end

        # Создаем временный файл в текущей директории
        temp_file = File.join(Dir.pwd, "temp_#{Time.now.to_i}.html")
        File.write(temp_file, rendered_html, encoding: 'UTF-8')

        # Путь к wkhtmltopdf
        wkhtmltopdf = 'C:\\Program Files\\wkhtmltopdf\\bin\\wkhtmltopdf.exe'
        
        # Проверяем существование файла
        unless File.exist?(wkhtmltopdf)
          puts "Ошибка: wkhtmltopdf не найден по пути #{wkhtmltopdf}"
          puts "Пожалуйста, установите wkhtmltopdf с сайта https://wkhtmltopdf.org/downloads.html"
          return false
        end

        # Формируем команду для wkhtmltopdf с учетом специальных опций
        cmd_options = build_options(options.merge(special_options))
        command = "\"#{wkhtmltopdf}\" #{cmd_options} \"#{temp_file}\" \"#{output_path}\""

        puts "Выполняем команду: #{command}"
        
        # Выполняем конвертацию
        result = system(command)
        
        if result
          puts "PDF успешно создан: #{output_path}"
          true
        else
          puts "Ошибка при создании PDF"
          false
        end
      rescue => e
        puts "Ошибка при конвертации: #{e.message}"
        puts e.backtrace
        false
      ensure
        # Удаляем временный файл
        File.delete(temp_file) if File.exist?(temp_file)
      end
    end

    def convert_template(template_path, output_path, variables = {}, options = {})
      begin
        # Проверяем существование шаблона
        unless File.exist?(template_path)
          puts "Ошибка: файл шаблона не найден: #{template_path}"
          return false
        end

        # Читаем шаблон
        template_content = File.read(template_path, encoding: 'UTF-8')
        
        # Создаем ERB объект
        erb = ERB.new(template_content)
        
        # Создаем контекст для переменных
        context = OpenStruct.new(variables)
        
        # Рендерим шаблон
        rendered_html = erb.result(context.instance_eval { binding })
        
        # Конвертируем отрендеренный HTML
        convert_html(rendered_html, output_path, options)
      rescue => e
        puts "Ошибка при обработке шаблона: #{e.message}"
        puts e.backtrace
        false
      end
    end

    private

    def build_options(options)
      default_options = {
        'page-size' => 'A4',
        'margin-top' => '10mm',
        'margin-right' => '10mm',
        'margin-bottom' => '10mm',
        'margin-left' => '10mm',
        'encoding' => 'UTF-8'
      }.merge(options)

      default_options.map do |k, v|
        if v.nil? || v.empty?
          "--#{k}"
        else
          "--#{k} #{v}"
        end
      end.join(' ')
    end
  end
end 