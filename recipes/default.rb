#
# Cookbook Name:: trac 
# Recipe:: default 
#
# Author:: Ryuzee <ryuzee@gmail.com>
#
# Copyright 2012, Ryutaro YOSHIBA 
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in wrhiting, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node["platform"]
when "centos", "redhat", "amazon", "scientific", "fedora"

  include_recipe "apache2"

  %w{python-setuptools mod_wsgi subversion mod_dav_svn}.each do |package_name|
    package package_name do
      action :install
    end
  end

  package "subversion-python" do
    action :install
    only_if {node["platform"] == "amazon"}
  end

  %w{Babel}.each do |package_name|
    easy_install_package package_name do
      action :install
    end
  end

  easy_install_package "Genshi" do
    action :install
    if node["platform"] =="centos" && node["platform_version"][0] == "5"
      version "0.6" 
    end
  end

  if node["platform"] =="centos" && node["platform_version"][0] == "5"
    package "python-devel" do
      action :install
    end
    package "sqlite-devel" do
      action :install
    end
    # http://trac-hacks.org/ticket/5512
    execute "easy_install -U setuptools" do
      action :run
    end
    easy_install_package "pysqlite" do
      action :install
    end
  end

  easy_install_package "Trac" do
    action :install
    if node["platform"] =="centos" && node["platform_version"][0] == "5"
      version "0.12.5" 
    end
  end

  ## create directory
  dir_list=[
    node["trac"]["trac_root_dir"].to_s,
    node["trac"]["svn_repository_root_dir"].to_s
  ]
  dir_list.each do |dir|
    directory dir do
      owner "apache"
      group "apache"
      mode "0755"
      action :create
    end
  end

  ## create svn repository
  e = execute "svnadmin create #{node["trac"]["svn_repository_root_dir"].to_s}/#{node["trac"]["project_name"].to_s}" do
    action :run
    not_if do File.exists?(node["trac"]["svn_repository_root_dir"].to_s+"/"+node["trac"]["project_name"].to_s) end
  end

  ## create trac project
  e = execute "trac-admin #{node["trac"]["trac_root_dir"]}/#{node["trac"]["project_name"]} initenv #{node["trac"]["project_name"]} sqlite:db/trac.db svn #{node["trac"]["svn_repository_root_dir"]}/#{node["trac"]["project_name"]}" do
    action :run
    not_if do File.exists?("#{node["trac"]["trac_root_dir"]}/#{node["trac"]["project_name"]}/conf/trac.ini") end
  end

  ## deploy trac wsgi
  e = execute "trac-admin #{node["trac"]["trac_root_dir"]}/#{node["trac"]["project_name"]} deploy /var/www/trac/#{node["trac"]["project_name"]}" do
    action :run
  end

  ## change owner
  a = node["trac"]["trac_root_dir"].to_s+"/"+node["trac"]["project_name"].to_s;
  b = node["trac"]["svn_repository_root_dir"].to_s+"/"+node["trac"]["project_name"].to_s;
  dir_list=[a,b]
  dir_list.each do |dir| 
    e = execute "chown -R apache:apache " + dir do
      action :run
    end
  end

  ## deploy apache configuration
  template "/etc/httpd/conf.d/trac_#{node["trac"]["project_name"]}.conf" do
    source "trac.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :restart, "service[httpd]"
  end

  ## deploy mod_dav_svn configuration
  template "/etc/httpd/conf.d/subversion_#{node["trac"]["project_name"]}.conf" do
    source "subversion.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :restart, "service[httpd]"
  end

  ## make password for Trac and SVN
  file node["trac"]["password_file"] do
    owner "apache"
    group "apache"
    mode "0644"
    action :create
    not_if do File.exists?(node["trac"]["password_file"]) end
  end

  e = execute "htpasswd -b #{node["trac"]["password_file"]} #{node["trac"]["admin_account"]} #{node["trac"]["admin_password"]}" do
    action :run
  end

  ## add admin user to trac
  e = execute "trac-admin #{node["trac"]["trac_root_dir"]}/#{node["trac"]["project_name"]} permission add #{node["trac"]["admin_account"]} TRAC_ADMIN" do
    action :run
    not_if "trac-admin #{node["trac"]["trac_root_dir"]}/#{node["trac"]["project_name"]} permission list | grep #{node["trac"]["admin_account"]}"
  end

  e = execute "easy_install http://trac-hacks.org/svn/accountmanagerplugin/trunk" do
    action :run
    not_if "python -c 'import sys; from pkg_resources import get_distribution; get_distribution(sys.argv[1])' TracAccountManager 2>/dev/null"
  end

  template "#{node["trac"]["trac_root_dir"]}/#{node["trac"]["project_name"]}/conf/trac.ini" do
    source "trac.ini.erb"
    owner "apache"
    group "apache"
    mode "0644"
    not_if "cat #{node["trac"]["trac_root_dir"]}/#{node["trac"]["project_name"]}/conf/trac.ini | grep password_format"
  end

end

# vim: filetype=ruby.chef
