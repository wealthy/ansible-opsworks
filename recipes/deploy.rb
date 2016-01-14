require 'json'


# Temporary setup code 
environment = node['ansible']['environment']
layer = node['opsworks']['instance']['layers'].first
playbooks = node['ansible']['playbooks']
folder = node['ansible']['folder']

zippath = '/etc/opsworks-customs'
basepath  = '/etc/opsworks-customs/'+folder

directory zippath do
  mode '0755'
  recursive true
  action :delete
end

directory zippath do
  mode '0755'
  recursive true
  action :create
end

remote_file '/etc/opsworks-customs/ansible.zip' do
  source playbooks
  mode '0755'
  action :create
end

execute 'extract_some_tar' do
  command 'unzip /etc/opsworks-customs/ansible.zip'
  cwd zippath
end

# Temporary setup code ends

extra_vars = {}
app = node['custom_ansible']['app']
extra_vars['opsworks'] = node['opsworks']
extra_vars['ansible']  = node['ansible']
extra_vars['environment_variables'] = node['deploy'][app]['environment_variables']
folder = node['ansible']['folder']
extra_vars['repository'] = node['deploy'][app]['scm']

zippath = '/etc/opsworks-customs'
basepath  = '/etc/opsworks-customs/'+folder

Chef::Log.info("Getting all data.. #{node['deploy']}")
Chef::Log.info("Getting app data.. #{extra_vars.to_json}")


execute "deploy" do
  command "ansible-playbook -i #{basepath}/inv #{basepath}/deploy.yml --extra-vars '#{extra_vars.to_json}'"
  only_if { ::File.exists?("#{basepath}/deploy.yml")}
  action :run
end

if ::File.exists?("#{basepath}/deploy.yml")
  Chef::Log.info("Log into #{node['opsworks']['instance']['private_ip']} and view /var/log/ansible.log to see the output of your ansible run")
else
  Chef::Log.info("No updates: #{basepath}/deploy.yml not found")
end
