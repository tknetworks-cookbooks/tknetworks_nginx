#
# Cookbook Name:: nginx
# Definition:: nginx_site
# Author:: AJ Christensen <aj@junglist.gen.nz>
# Author:: TANABE Ken-ichi <nabeken@tknetworks.org>
#
# Copyright 2008-2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

define :nginx_site_conf,
       :create_htdocs => true,
       :use_php_fpm   => [],
       :port          => nil,
       :use_https     => false,
       :ssl_cert      => nil,
       :ssl_key       => nil do
  t = nil
  f = "#{node['nginx']['dir']}/sites-available/#{params[:name]}"
  port = params[:port] || (params[:use_https] ? 443 : 80)
  ssl_cert = params[:ssl_cert] ||
              "#{node['nginx']['dir']}/ssl/#{params[:name]}.crt"
  ssl_key = params['ssl_key'] ||
              "#{node['nginx']['dir']}/ssl/#{params[:name]}.key"

  dirs = [
    "/var/www/#{params[:name]}",
    "#{node['nginx']['log_dir']}/#{params[:name]}"
  ]
  dirs.push "/var/www/#{params[:name]}/htdocs" if params[:create_htdocs]
  dirs.push "#{node['nginx']['dir']}/ssl" if params[:use_https]
  dirs.each do |d|
    directory d do
      owner node['nginx']['user']
      group node['nginx']['group']
      action :create
      recursive true
    end
  end

  if params[:use_https]
    begin
      cert = Chef::EncryptedDataBagItem.load('certs', params[:name].gsub('.', '_'))
      file ssl_cert do
        owner node['nginx']['user']
        group node['nginx']['group']
        mode  "0644"
        notifies :restart, "service[nginx]"
        content cert["cert"]
      end
      file ssl_key do
        owner node['nginx']['user']
        group node['nginx']['group']
        mode  "0640"
        notifies :restart, "service[nginx]"
        content cert["key2"]
      end
    rescue Net::HTTPServerException
      Chef::Log.info("certificate for #{params[:name]} is not found")
    end
  end

  if !params[:use_php_fpm].empty? && params[:use_php_fpm].first
    begin
      pool = resources("php_fpm_pool[#{params[:use_php_fpm].last}]")
      params[:php_fpm_sock] = pool.sock
    rescue
      params[:php_fpm_sock] = params[:use_php_fpm].last
    end
  end

  begin
    t = resources("template[#{f}]")
  rescue
    t = template f do
          owner "root"
          mode "0644"
          variables(
            :port     => port,
            :params   => params,
            :ssl_key  => ssl_key,
            :ssl_cert => ssl_cert
          )
          cookbook 'tknetworks_nginx'
          source "site.conf.erb"
          notifies :restart, "service[nginx]"
        end
  end

end
