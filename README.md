If your vagrant is below version 1.6.6, then apply this fix to the vagrant file plugins/guests/redhat/cap/nfs_client.rb :
https://github.com/sprin/vagrant/commit/8d610659de427e94369179f911b754f6a8acd574

Install the vagrant hostmanager plugin
vagrant plugin install vagrant-hostmanager 
