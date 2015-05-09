#Firewall rules for the NFS server
class profiles::nfs::fw {

  firewalld_rich_rule { 'nfs_rule':
    ensure => 'present',
    zone   => 'public',
    source => '172.16.254.0/24',
    port   => {
      'port'     => 2049,
      'protocol' => 'tcp',
    },
    action => 'accept',
  }
  firewalld_rich_rule { 'mountd_rule':
    ensure => 'present',
    zone   => 'public',
    source => '172.16.254.0/24',
    port   => {
      'port'     => 20048,
      'protocol' => 'tcp',
    },
    action => 'accept',
  }

  firewalld_rich_rule { 'rpcbind_rule':
    ensure => 'present',
    zone   => 'public',
    source => '172.16.254.0/24',
    port   => {
      'port'     => 111,
      'protocol' => 'tcp',
    },
    action => 'accept',
  }

}
