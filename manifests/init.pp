class se_vmware {

  $pe_servicename = hiera('se_vmware::pe_servicename', 'pe-puppet')

  service { 'puppet_agent':
    name   => $pe_servicename,
    ensure => running,
    enable => true,
  }
}
