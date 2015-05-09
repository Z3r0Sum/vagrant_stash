#Firewall rules for the pgsql server
class profiles::stash::pgsql::fw {

  firewalld_rich_rule { 'pgsql_rule':
    ensure => 'present',
    zone   => 'public',
    source => '172.16.254.0/24',
    port   => {
      'port'     => 5432,
      'protocol' => 'tcp',
    },
    action => 'accept',
  }

}
