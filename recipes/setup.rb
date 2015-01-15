require 'json'

Chef::Application.fatal!("'ansible['environment']' must be defined in custom json for the opsworks stack") if node['ansible'].nil? || node['ansible']['environment'].nil? || node['ansible']['environment'].empty?

environment = node['ansible']['environment']
layer = node['opsworks']['instance']['layers'].first

# If the role for this layer is defined in custom json then set the role to what's defined
# If not, set the role to the name of the layer
role = node['ansible']['layers'][layer]['role'] rescue nil
if role.nil?
  role = layer
end

execute "tag instance" do
  command "aws ec2 create-tags --tags Key=environment,Value=#{environment} Key=role,Value=#{role} --resources `curl http://169.254.169.254/latest/meta-data/instance-id/` --region #{node['opsworks']['instance']['region']}"
  action :run
end

execute "configure base" do
  command "ansible-playbook -i /home/ec2-user/base/inv /home/ec2-user/base/configure.yml"
  only_if { ::File.exists?("/home/ec2-user/base/configure.yml")}
  action :run
end

extra_vars = {}
extra_vars['opsworks'] = node['opsworks']
extra_vars['ansible']  = node['ansible']

execute "setup" do
  command "ansible-playbook -i /home/ec2-user/ansible/inv /home/ec2-user/ansible/#{node['opsworks']['activity']}.yml --extra-vars '#{extra_vars.to_json}'"
  only_if { ::File.exists?("/home/ec2-user/ansible/#{node['opsworks']['activity']}.yml")}
  action :run
end

if ::File.exists?("/home/ec2-user/ansible/#{node['opsworks']['activity']}.yml")
  Chef::Log.info("Log into #{node['opsworks']['instance']['private_ip']} and view /var/log/ansible.log to see the output of your ansible run")
else
  Chef::Log.info("No updates: /home/ec2-user/ansible/#{node['opsworks']['activity']}.yml not found")
end
