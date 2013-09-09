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
require 'minitest/spec'

describe_recipe 'tknetworks_nginx::example' do
  it 'disables default' do
    link("#{node['nginx']['dir']}/sites-enabled/default").wont_exist
  end

  it 'configures default-debian-wheezy.vagrantup.com' do
    domain = "default-debian-wheezy.vagrantup.com"
    assert_file("#{node['nginx']['dir']}/ssl/#{domain}.crt", node['nginx']['user'], node['nginx']['group'], 0644)
    assert_file("#{node['nginx']['dir']}/ssl/#{domain}.key", node['nginx']['user'], node['nginx']['group'], 0640)
    vhost = directory("/var/www/#{domain}")
    vhost.must_have(:mode, 0755)
    vhost.must_have(:owner, node['nginx']['user'])
    vhost.must_have(:group, node['nginx']['group'])

    conf = file("#{node['nginx']['dir']}/sites-available/#{domain}")
    conf.must_exist
    conf.must_include("ssl_certificate             /etc/nginx/ssl/#{domain}.crt;")
    conf.must_include("fastcgi_pass unix:/var/run/php5-fpm-www.sock;")
    link("#{node['nginx']['dir']}/sites-enabled/#{domain}").must_exist
    assert_sh("""set -e
content=$(wget -O- --header='Host: #{domain}' --no-check-certificate https://127.0.0.1/ 2> /dev/null)
echo \"${content}\" | grep -E 'PHP Version 5\.4\.4'
echo \"${content}\" | grep -E '^domain:#{Regexp.escape(domain)}$'
""")
  end

  it 'configures default-debian-wheezy-example.vagrantup.com' do
    domain = "default-debian-wheezy-example.vagrantup.com"
    conf = file("#{node['nginx']['dir']}/sites-available/#{domain}")
    conf.must_exist
    conf.wont_include("ssl_certificate             /etc/nginx/ssl/#{domain}.crt;")
    conf.must_include("fastcgi_pass unix:/var/run/www_example_foobar.sock;")
    link("#{node['nginx']['dir']}/sites-enabled/#{domain}").must_exist
    assert_sh("""set -e
content=$(wget -O- --header='Host: #{domain}' http://127.0.0.1/ 2> /dev/null)
echo \"${content}\" | grep -E 'PHP Version 5\.4\.4'
echo \"${content}\" | grep -E '^domain:#{Regexp.escape(domain)}$'
""")
  end
end
