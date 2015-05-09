#pgsql profile for standby
class profiles::pgsql::standby {
  require ::profiles::base::packages
  require ::profiles::base::hosts
  require ::profiles::pgsql::prework
  include ::profiles::pgsql::fw

  $db_user  = hiera('pgsql_server::user')
  $ipv4acls = hiera('pgsql_server::ipv4acls')

  #Setup node to be able to recover
  class { '::postgresql::server':
    listen_addresses     => '*',
    ipv4acls             => [$ipv4acls],
    manage_recovery_conf => true,
    require              => Class['::profiles::base::hosts'],
  }

  #Begin setting up standby server
  postgresql::server::config_entry { 'hot_standby':
    value => 'on',
  }
  
  postgresql::server::recovery { 'Create a recovery.conf for standby server':
    restore_command  => 'cp /mnt/db_archive/"%f" "%p"',
    standby_mode     => 'on',
    primary_conninfo => 'host=stash-server port=5432',
    trigger_file     => '/var/lib/pgsql/data/trigger_failover.txt',
  }

  #Accept connections from standby server
  postgresql::server::pg_hba_rule { 'allow master server to accept connections':
    type        => 'host',
    database    => 'replication',
    user        => 'all',
    address     => '172.16.254.0/24',
    auth_method => 'trust',
  }

  #Accept connections from standby server localhost
  postgresql::server::pg_hba_rule { 'allow master server to accept local conns':
    type        => 'host',
    database    => 'replication',
    user        => 'all',
    address     => '::1/128',
    auth_method => 'trust',
  }

  #Add DB user to the system
  user { $db_user:
    ensure     => 'present',
    comment    => 'stash db user',
    shell      => '/bin/bash',
    managehome => true,
  }

  class { 'selinux':
    mode => 'permissive',
  }
}
