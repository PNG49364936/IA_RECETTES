# Configuration WickedPDF pour l'export PDF

WickedPdf.configure do |config|
  if Rails.env.production?
    # En production (Docker), utiliser le wkhtmltopdf système
    config.exe_path = '/usr/bin/wkhtmltopdf'
  else
    # En développement, utiliser le gem wkhtmltopdf-binary
    config.exe_path = Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')
  end
end
