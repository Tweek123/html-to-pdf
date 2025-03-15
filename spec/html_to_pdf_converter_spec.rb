require 'spec_helper'
require_relative '../lib/html_to_pdf_converter'

RSpec.describe HtmlToPdfConverter do
  describe '.convert' do
    let(:html_content) { '<h1>Тестовый документ</h1><p>Это тестовый HTML.</p>' }
    let(:output_path) { 'test_output.pdf' }

    after do
      File.delete(output_path) if File.exist?(output_path)
    end

    it 'создает PDF файл из HTML' do
      expect(HtmlToPdfConverter.convert(html_content, output_path)).to be true
      expect(File.exist?(output_path)).to be true
    end
  end
end 