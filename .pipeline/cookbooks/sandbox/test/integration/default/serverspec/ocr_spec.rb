require 'serverspec'

describe package('tesseract-ocr') do
  it { should be_installed }
end

describe package('imagemagick') do
  it { should be_installed }
end