#Firewall rules for the pgsql server
class profiles::stash::fw {

  firewalld_rich_rule { 'stash_rule':
    ensure => 'present',
    zone   => 'public',
    source => '172.16.254.0/24',
    port   => {
      'port'     => 7990,
      'protocol' => 'tcp',
    },
    action => 'accept',
  }

}
