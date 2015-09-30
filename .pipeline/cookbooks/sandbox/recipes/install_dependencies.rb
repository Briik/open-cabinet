execute 'bundle-install' do
  command 'no_proxy=myuscispilot.com,${no_proxy} bundle install --verbose --jobs 4 --retry 3 --without development test acceptance'
  cwd node[:myuscis][:app][:location]
  user 'root'
end

execute 'bundle update style_guide' do
  command 'bundle update style_guide'
  cwd node[:myuscis][:app][:location]
  user 'root'
end