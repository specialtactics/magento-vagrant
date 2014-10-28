If your vagrant is below version 1.6.6, then apply this fix to the vagrant file plugins/guests/redhat/cap/nfs_client.rb :
https://github.com/sprin/vagrant/commit/8d610659de427e94369179f911b754f6a8acd574

Make sure you have NSF server running locally, and there won't be anything to block relevant ports between the VMs
Eg: On Fedora
systemctl stop firewalld
systemctl enable nfs-server
systemctl start nfs-server 

Install Instructions
Install the vagrant hostmanager plugin
vagrant plugin install vagrant-hostmanager 
