# Common class for neutron installation
# Private, and should not be used on its own
# Sets up configuration common to all neutron nodes.
# Flags install individual services as needed
# This follows the suggest deployment from the neutron Administrator Guide.
class openstack::common::neutron {
  $controller_management_address = $::openstack::config::controller_address_management

  $data_network = $::openstack::config::network_data
  $data_address = ip_for_network($data_network)

  # neutron auth depends upon a keystone configuration
  include ::openstack::common::keystone

  class { '::neutron':
    rabbit_host           => $controller_management_address,
    core_plugin           => 'neutron.plugins.ml2.plugin.Ml2Plugin',
    allow_overlapping_ips => true,
    rabbit_user           => $::openstack::config::rabbitmq_user,
    rabbit_password       => $::openstack::config::rabbitmq_password,
    debug                 => $::openstack::config::debug,
    verbose               => $::openstack::config::verbose,
    service_plugins       => ['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin'],
    #                              'neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPluginv2',
    #                          'neutron.services.vpn.plugin.VPNDriverPlugin',
    #                          'neutron.services.firewall.fwaas_plugin.FirewallPlugin'],
    #                          'neutron.services.metering.metering_plugin.MeteringPlugin'],
  }

  #Anchor['keystone-users'] -> Class['::neutron']

  class { '::neutron::keystone::auth':
    password         => $::openstack::config::neutron_password,
    public_address   => $::openstack::config::controller_address_api,
    admin_address    => $::openstack::config::controller_address_management,
    internal_address => $::openstack::config::controller_address_management,
    region           => $::openstack::config::region,
  }

  class { '::neutron::server':
    auth_password       => $::openstack::config::neutron_password,
    auth_uri            => "http://${controller_management_address}:5000/",
    identity_uri        => "http://${controller_management_address}:35357/",
    database_connection => $::openstack::resources::connectors::neutron,
    enabled             => $::openstack::profile::base::is_controller,
    sync_db             => $::openstack::profile::base::is_controller,
  }

  class { '::neutron::server::notifications':
    auth_url     => "http://${controller_management_address}:35357",
    password     => $::openstack::config::nova_password,
    region_name  => $::openstack::config::region,
  }

  if $::osfamily == 'redhat' {
    package { 'iproute':
        ensure => latest,
        before => Class['::neutron']
    }
  }
}
