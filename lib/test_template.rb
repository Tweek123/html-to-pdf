require_relative 'html_to_pdf_converter'

# Тестовые данные для шаблона
variables = {
  watermark: true,
  document: {
    number: "2024-001",
    date: Time.now.strftime("%d.%m.%Y"),
    company_name: "ООО \"Рога и Копыта\"",
  }
}

# Опции для PDF
options = {
  'page-size' => 'A4',
  'margin-top' => '20mm',
  'margin-right' => '20mm',
  'margin-bottom' => '20mm',
  'margin-left' => '20mm',
  'encoding' => 'UTF-8',
  'footer-font-size' => '9',
  'disable-smart-shrinking' => '',
  'zoom' => '1.0',
  'dpi' => '300'
}

puts "Начинаем конвертацию шаблона счета..."
result = HtmlToPdfConverter.convert_template(
  'templates/invoice.html.erb',
  'invoice.pdf',
  variables,
  options
)
puts "Конвертация #{result ? 'успешно завершена' : 'завершилась с ошибкой'}" 