#precompile started to get upset about a lack of database.yml, so lay down a dummy one to see if it makes a difference
template "#{node[:myuscis][:app][:location]}/config/database.yml" do
  source 'database.yml.erb'
  action :create
  variables ({
              db_url: 'fake',
              db_user: 'fake',
              db_pass: 'fake'
            })
end

precompile = 'RAILS_ENV=production bundle exec rake assets:precompile'

results = '/tmp/output.txt'
file results do
  action :delete
end

#&>> is a bash 4-ism to redirect both stdout and stderr
bash 'deploy app' do
  code <<-EOH
  set +e

  ruby -v

  #{precompile} &>> #{results}
  precompile_exit_code=$?
  echo AFTER PRECOMPILE
  cat #{results}
  exit ${precompile_exit_code}
  EOH
  cwd node[:myuscis][:app][:location]
  user 'root'
end

ruby_block 'Results' do
  only_if { ::File.exists?(results) }
  block do
    print "\n"
    File.open(results).each do |line|
      print line
    end
  end
end