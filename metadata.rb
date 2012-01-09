name              "tknetworks_nginx"
maintainer        "TKNetworks"
maintainer_email  "nabeken@tknetworks.org"
license           "Apache 2.0"
description       "Installs and configures nginx"
version           "0.0.1"

%w{debian}.each do |os|
  supports os
end

%w{nginx php_fpm}.each do |d|
  depends d
end
