# Common class for nova installation
# Private, and should not be used on its own
# usage: include from controller, declare from worker
# This is to handle dependency
# depends on openstack::profile::base having been added to a node
class openstack::common::nova ($is_compute    = false) {
  $is_controller = $::openstack::profile::base::is_controller

  $management_network = $::openstack::config::network_management
  $management_address = ip_for_network($management_network)

  $storage_management_address = $::openstack::config::storage_address_management
  $controller_management_address = $::openstack::config::controller_address_management

  class { '::nova':
    database_connection     => $::openstack::resources::connectors::nova,
    api_database_connection => $::openstack::resources::connectors::novaapi,
    glance_api_servers      => "http://${storage_management_address}:9292",
    memcached_servers       => ["${controller_management_address}:11211"],
    rabbit_hosts            => [$controller_management_address],
    rabbit_userid           => $::openstack::config::rabbitmq_user,
    rabbit_password         => $::openstack::config::rabbitmq_password,
    debug                   => $::openstack::config::debug,
    verbose                 => $::openstack::config::verbose,
  }

  # nova_config { 'DEFAULT/default_floating_pool': value => 'public' }

  class { '::nova::api':
    admin_password                       => $::openstack::config::nova_password,
    enabled                              => $is_controller,
    auth_uri                             => "http://${controller_management_address}:5000/",
    identity_uri                         => "http://${controller_management_address}:35357/",
    neutron_metadata_proxy_shared_secret => $::openstack::config::neutron_shared_secret,
    default_floating_pool                => 'public',
  }

  class { '::nova::vncproxy':
    host    => $::openstack::config::controller_address_api,
    enabled => $is_controller,
  }

  class { [
    'nova::scheduler',
    'nova::cert',
    'nova::consoleauth',
    'nova::conductor'
  ]:
    enabled => $is_controller,
  }

  class { '::nova::compute':
    enabled                       => $is_compute,
    vnc_enabled                   => true,
    vncserver_proxyclient_address => $management_address,
    vncproxy_host                 => $::openstack::config::controller_address_api,
  }

  class { '::nova::compute::neutron': }

  class { '::nova::network::neutron':
    neutron_password      => $::openstack::config::neutron_password,
    neutron_url           => "http://${controller_management_address}:9696",
    neutron_region_name   => $::openstack::config::region,
    neutron_auth_url      => "http://${controller_management_address}:35357/v3",
    vif_plugging_is_fatal => false,
    vif_plugging_timeout  => '0',
  }
}
