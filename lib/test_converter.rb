require_relative 'html_to_pdf_converter'

# Создаем простой тестовый HTML
html_content = <<-HTML
<html>
<head>
    <title>Тест</title>
    <style>
        body { font-family: Arial; padding: 20px; }
    </style>
</head>
<body>
    <h1>Тестовый PDF</h1>
    <p>Привет, это тест конвертации!</p>
    <p>Время: #{Time.now}</p>
</body>
</html>
HTML

puts "Начинаем конвертацию..."
result = HtmlToPdfConverter.convert(html_content, 'output.pdf')
puts "Конвертация #{result ? 'успешно завершена' : 'завершилась с ошибкой'}" 