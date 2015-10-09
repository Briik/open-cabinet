execute 'bundle-install' do
  command 'bundle install --verbose --jobs 4 --retry 3 --without development test acceptance'
  cwd node[:myuscis][:app][:location]
  user 'root'
end