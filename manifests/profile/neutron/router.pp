# The profile to set up a neutron ovs network router
class openstack::profile::neutron::router {
  Exec {
    path    => '/usr/bin:/usr/sbin:/bin:/sbin',
    require => Class['openstack::common::neutron'],
  }

  ::sysctl::value { 'net.ipv4.ip_forward':
    value     => '1',
  }

  $controller_management_address = $::openstack::config::controller_address_management
  include ::openstack::common::neutron
  include ::openstack::common::ovs

  ### Router service installation
  class { '::neutron::agents::l3':
    debug                   => $::openstack::config::debug,
    external_network_bridge => 'brex',
    enabled                 => true,
  }

  class { '::neutron::agents::dhcp':
    debug                    => $::openstack::config::debug,
    enabled                  => true,
    enable_isolated_metadata => true,
    enable_metadata_network  => true,
  }

  class { '::neutron::agents::metadata':
    auth_password => $::openstack::config::neutron_password,
    shared_secret => $::openstack::config::neutron_shared_secret,
    auth_url      => "http://${controller_management_address}:35357/v2.0",
    debug         => $::openstack::config::debug,
    auth_region   => $::openstack::config::region,
    metadata_ip   => $controller_management_address,
    enabled       => true,
  }

  neutron_metadata_agent_config {
    'DEFAULT/nova_metadata_insecure':
      value => true
  }

  class { '::neutron::agents::lbaas':
    debug   => $::openstack::config::debug,
    enabled => true,
  }

  class { '::neutron::agents::vpnaas':
    enabled                 => true,
    external_network_bridge => 'brex',
  }

  class { '::neutron::agents::metering':
    enabled => true,
  }

  class { '::neutron::services::fwaas':
    enabled => true,
  }

  $external_bridge = 'brex'
  $external_network = $::openstack::config::network_external
  $external_device = device_for_network($external_network)
  vs_bridge { $external_bridge:
    ensure => present,
  }
  if $external_device != $external_bridge {
    vs_port { $external_device:
      ensure => present,
      bridge => $external_bridge,
    }
  } else {
    # External bridge already has the external device's IP, thus the external
    # device has already been linked
  }
}
