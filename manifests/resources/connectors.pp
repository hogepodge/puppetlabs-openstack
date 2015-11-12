class openstack::resources::connectors {

  $management_address = $::openstack::config::controller_address_management
  $password = $::openstack::config::mysql_service_password

  $keystone = "mysql://keystone:${password}@${management_address}/keystone"
  $cinder   = "mysql://cinder:${password}@${management_address}/cinder"
  $glance   = "mysql://glance:${password}@${management_address}/glance"
  $nova     = "mysql://nova:${password}@${management_address}/nova"
  $neutron  = "mysql://neutron:${password}@${management_address}/neutron"
  $heat     = "mysql://heat:${password}@${management_address}/heat"
  $trove    = "mysql://trove:${password}@${management_address}/trove"
  $sahara   = "mysql://sahara:${password}@${management_address}/sahara"
  $ironic   = "mysql://ironic:${password}@${management_address}/ironic"
  $tuskar   = "mysql://tuskar:${password}@${management_address}/tuskar"
}
