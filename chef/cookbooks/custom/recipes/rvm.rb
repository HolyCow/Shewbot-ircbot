

execute "install curl" do
  command "aptitude install curl -y"
  ignore_failure false
  creates '/usr/bin/curl'
end

execute "install nodejs" do
  command "aptitude install nodejs -y"
  ignore_failure false
  creates '/usr/bin/nodejs'
end

execute "install rvm" do
  cwd "/vagrant"
  user "vagrant"
  environment ({"HOME" => "/home/vagrant"})
  command "curl -Ls https://get.rvm.io | bash -s stable"
  ignore_failure false
  creates '/home/vagrant/.rvm/bin/rvm'
end

execute "install ruby through rvm" do
  command "su vagrant -l -c 'cd /vagrant && rvm install ruby-1.9.3-p547'"
  ignore_failure false
  creates '/home/vagrant/.rvm/rubies/ruby-1.9.3-p547/bin/ruby'
end

execute "bundle install" do
  command "su vagrant -l -c 'cd /vagrant && bundle install'"
  ignore_failure false
end

