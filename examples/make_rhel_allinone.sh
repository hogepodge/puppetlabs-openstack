OSTARGET=rhel VAGRANTBOX="centos-7-64-openstack-nov" SCENARIO=allinone puppet apply --modulepath=../tests/modules -e "include ::plostest::vagrant"
