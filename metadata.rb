name             "trac"
maintainer       "Ryuzee"
maintainer_email "ryuzee@gmail.com"
license          "MIT License"
description      "Install Trac and Subversion"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.3"
depends          "apache2"

%w{redhat centos scientific fedora amazon}.each do |os|
    supports os
end
