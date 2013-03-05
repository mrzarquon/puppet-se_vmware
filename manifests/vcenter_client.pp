class se_vmware::vcenter_client {

  file { 'vcenter-installer':
    ensure => present,
    path   => "C:\VMware-viclient.exe",
    owner  => 'Administrators',
    mode   => "0777",
    group  => 'Administrators',
    source => 'puppet:///files/VMware-viclient.exe',
  }

  windows_package { 'VMware-viclient':
    ensure          => installed,
    name            => 'VMware vSphere Client 5.1',
    source          => 'C:/VMware-viclient.exe',
    install_options => ['/s', '/s', '/w', '/L1003', '/V/qb!'],
    require         => [ File['vcenter-installer'] ],
  }
}
