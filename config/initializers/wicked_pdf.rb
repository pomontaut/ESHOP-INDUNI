WickedPdf.configure do |config|
  config.exe_path = `which wkhtmltopdf`.strip
end
