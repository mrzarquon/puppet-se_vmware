#!/usr/bin/env ruby
### BEGIN INIT INFO
# Provides:          vmware-post
# Required-Start:    $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: Run /etc/init.d/vmware-post
### END INIT INFO

# Script to update things on first boot of a VM cloned from template.  Probably better
# served as a bourne script but we need rbvmomi, because I don't want to parse soap
# returned from a curl.
# Dependancies:
#   apt: facter, ruby-minitest, racc, rake, rdoc, ruby-dev, libxml2-dev, libxslt-dev
#   gem: rbvmomi

require 'rubygems'
require 'rbvmomi'
require 'facter'
require 'socket'

# Because I can't for the life of me get debain to 100% always wait on DNS.
begin
  Socket.getaddrinfo('vcsa.se.eng.puppetlabs.net', nil)
rescue
  retry
end

vim = RbVmomi::VIM.connect(
  :host     => 'vcsa.se.eng.puppetlabs.net',
  :user     => 'root',
  :password => 'puppetlabs',
  :ssl      => true,
  :insecure => true,
  :rev      => '5.0'
)

ip = Facter.value(:ipaddress_eth0)

vm = nil

while vm.nil?
  vm = vim.searchIndex.FindByIp(:vmSearch => true, :ip => ip)
  sleep 2
end

# Set and save hostname
hostname = vm.name

centosnetwork = File.read('/etc/sysconfig/network')


File.open('/etc/sysconfig/network', 'w') do |f|
  centosnetwork.gsub!(/^(HOSTNAME=.*)/, "HOSTNAME=#{hostname}")
  f.write(centosnetwork)
end

Kernel.system("hostname #{hostname}")

# Put hostname in our dhclient.conf so it gets sent to DNS.
data = File.read('/etc/sysconfig/network-scripts/ifcfg-eth0')

#puts hostname

File.open('/etc/sysconfig/network-scripts/ifcfg-eth0', 'w') do |f|
  data.gsub!(/^(DHCP_HOSTNAME=\".*\")/, "DHCP_HOSTNAME=\"#{hostname}\"")
  data.gsub!(/^(HOSTNAME=\".*\")/, "HOSTNAME=\"#{hostname}\"")
  #puts data
  f.write(data)
end

#lets restart networking entirely
Kernel.system('/etc/init.d/network restart')

# Clean up puppet's ssldir...shelling our because of run_mode.
#ssldir = `/opt/puppet/bin/puppet config print ssldir`

# Destruction!
#Kernel.system("rm -rf #{ssldir}")

# New fqdn we have.
fqdn = Facter.value(:fqdn)
domain = Facter.value(:domain)

#puts fqdn
#puts domain

# Setup with new certs
Kernel.system("/opt/puppet/bin/puppet agent --server puppet.#{domain} --onetime --no-daemonize --pluginsync true --certname #{fqdn}")

Kernel.system('chkconfig vmware-post-puppet off')
Kernel.system('chkconfig pe-puppet on')
Kernel.system('chkconfig pe-mcollective on')
#Kernel.system('reboot')

exit 0
