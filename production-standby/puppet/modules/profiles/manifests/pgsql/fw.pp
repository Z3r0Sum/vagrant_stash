#Firewall rules for the pgsql server
class profiles::pgsql::fw {

  firewalld_rich_rule { 'stash_rule':
    ensure => 'present',
    zone   => 'public',
    source => '172.16.254.11/24',
    action => 'accept',
  }

}
