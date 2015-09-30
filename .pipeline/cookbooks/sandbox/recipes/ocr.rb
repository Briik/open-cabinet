%w{tesseract-ocr tesseract-ocr-eng imagemagick}.each do |pkg|
  package pkg do
    action :install
  end
end
