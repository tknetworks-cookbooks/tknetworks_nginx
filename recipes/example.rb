#
# Author:: Ken-ichi TANABE (<nabeken@tknetworks.org>)
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
nginx_site 'default' do
  enable false
end

nginx_site_conf 'default-debian-wheezy.vagrantup.com' do
  use_php_fpm true, 'www'
  use_https true
end

nginx_site 'default-debian-wheezy.vagrantup.com' do
  action :enable
end

php_fpm_pool 'www_example' do
  user 'www-data'
  group 'www-data'
  sock 'unix:/var/run/www_example_foobar.sock'
  notifies :restart, "service[#{node['php_fpm']['service']['name']}]"
end

nginx_site_conf 'default-debian-wheezy-example.vagrantup.com' do
  use_php_fpm true, 'www_example'
end

nginx_site 'default-debian-wheezy-example.vagrantup.com' do
  action :enable
end

%w{
  default-debian-wheezy.vagrantup.com
  default-debian-wheezy-example.vagrantup.com
}.each do |d|
  file "/var/www/#{d}/htdocs/index.php" do
    owner 'www-data'
    group 'www-data'
    mode 0644
    content """
<?php phpinfo(); ?>

domain:#{d}
"""
  end

  file "/var/www/#{d}/nginx.conf" do
    owner 'www-data'
    group 'www-data'
    mode 0644
    content """location / {
  root   /var/www/#{d}/htdocs;
  index  index.html index.htm index.php;
}
"""
  end
end
