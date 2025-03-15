require_relative 'html_to_pdf_converter'

# Пример HTML строки
html_string = <<~HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Тестовый документ</title>
    <style>
        body { font-family: Arial; padding: 20px; }
        h1 { color: #2c3e50; }
        .content { margin-top: 20px; }
    </style>
</head>
<body>
    <h1>Тестовый PDF из HTML строки</h1>
    <div class="content">
        <p>Это тестовый документ, созданный из HTML строки.</p>
        <p>Время создания: #{Time.now}</p>
    </div>
</body>
</html>
HTML

# Опции для PDF
options = {
  'page-size' => 'A4',
  'margin-top' => '20mm',
  'margin-right' => '20mm',
  'margin-bottom' => '20mm',
  'margin-left' => '20mm',
  'encoding' => 'UTF-8'
}

puts "Конвертация HTML строки в PDF..."
result = HtmlToPdfConverter.convert_html(html_string, 'output_from_string.pdf', options)
puts "Конвертация #{result ? 'успешно завершена' : 'завершилась с ошибкой'}"

# Если у вас есть HTML файл, вы можете конвертировать его так:
if File.exist?('input.html')
  puts "\nКонвертация HTML файла в PDF..."
  result = HtmlToPdfConverter.convert_html('input.html', 'output_from_file.pdf', options)
  puts "Конвертация #{result ? 'успешно завершена' : 'завершилась с ошибкой'}"
end 