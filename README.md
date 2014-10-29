## Requirements: ##
+ [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
+ [Vagrant](http://www.vagrantup.com/downloads.html)
+ [Vagrant Host Manager](https://github.com/smdahlen/vagrant-hostmanager)


## Vagrant Note: ##
If your vagrant is below version 1.6.6, then apply this fix to the vagrant file plugins/guests/redhat/cap/nfs_client.rb :
 * https://github.com/sprin/vagrant/commit/8d610659de427e94369179f911b754f6a8acd574

The easiest way to do it is to search your system for the file **nfs_client.rb**, open up the one in guests/redhat/cap directory, and replace it's contents with the following:
 * https://raw.githubusercontent.com/sprin/vagrant/8d610659de427e94369179f911b754f6a8acd574/plugins/guests/redhat/cap/nfs_client.rb


## Other Stuff ##
This is probably not overly relevent on windows; Make sure you have NSF server running locally, and there won't be anything to block relevant ports between the VMs.

Eg: On Fedora
```
systemctl stop firewalld
systemctl enable nfs-server
systemctl start nfs-server 
```


# What do you get? #
 * CentOS 7 - Up to date 
 * Apache 2.4
 * PHP 5.6
 * MariaDB 10.0.1 (Compatible with MySQL 5.6)
 * CSS compilation tools & NPM
 * Various useful commandline tools & zsh
 * PHP-FPM through mod_proxy & mod_proxy_fcgi
 * All necessary extensions for Magento development
 * And of course... the latest version of Magento (currently 1.9.0.1)


# Install Instructions #
```
vagrant up
```

Once complete, you should be able to navigate to http://magento.dev/ and have an installed version of Magento there. To access admin, go to http://magento.dev/admin and log in with **admin** / **password1** .
