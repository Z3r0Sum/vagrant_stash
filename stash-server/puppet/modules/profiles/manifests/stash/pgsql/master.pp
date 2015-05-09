#pqsql profile for master 
class profiles::stash::pgsql::master {

  require ::profiles::base::packages
  require ::profiles::base::hosts
  include ::profiles::stash::pgsql::fw

  #Pull data from hiera to abstract data from profile
  $postgresql_password = hiera('pgsql_server::postgres_password')
  $ipv4acls            = hiera('pgsql_server::ipv4acls')
  $db_name             = hiera('pgsql_server::db_name')
  $db_user             = hiera('pgsql_server::user')
  $db_user_passwd      = hiera('pgsql_server::password')
  $db_role             = hiera('pgsql_server::role')

  #This would be locked down in a real environment to specific
  #addresses and would most-likely use SSL for auth
  class { 'postgresql::server':
    listen_addresses  => '*',
    postgres_password => $postgresql_password,
    ipv4acls          => [$ipv4acls],
  }

  class { 'postgresql::server::contrib': }
  class { 'postgresql::lib::java': }

  postgresql::server::extension { 'pgcrypto':
    ensure   => 'present',
    database => $db_name,
  }

  #Begin setting up for dynamic failover.
  postgresql::server::config_entry { 'wal_level':
    value => 'hot_standby',
  }

  #This is based on how many standby servers 
  postgresql::server::config_entry { 'max_wal_senders':
    value => '1',
  }

  #Number of past log file segments to keep in case standby server
  #needs to fetch them for streaming replication.
  postgresql::server::config_entry { 'wal_keep_segments':
    value => '75',
  }

  postgresql::server::config_entry { 'archive_mode':
    value => 'on',
  }

  postgresql::server::config_entry { 'archive_command':
    value   => 'cp "%p" /mnt/db_archive/"%f"',
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

  postgresql::server::db { $db_name:
    user     => $db_user,
    password => postgresql_password($db_user,$db_user_passwd),
  }

  postgresql::server::role { $db_role:
    password_hash => postgresql_password($db_user,$db_user_passwd),
    replication   => true,
    superuser     => true,
  }

  postgresql::server::database_grant { $::env:
    privilege => 'ALL',
    db        => $db_name ,
    role      => $db_role,
  }

  #Create directory for NFS backups
  file { '/mnt/db_bkup':
    ensure  => 'directory',
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0770',
    require => Class['postgresql::server'],
  }->
  #Mount NFS filesystem for DB backup
  mount { 'db_bkup':
    ensure  => 'mounted',
    name    => '/mnt/db_bkup',
    device  => 'nfs-server:/var/nfs/db_bkup',
    fstype  => 'nfs4',
    options => 'defaults',
  }

  #Create directory for NFS WAL Archives
  file { '/mnt/db_archive':
    ensure  => 'directory',
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0770',
    require => Class['postgresql::server'],
  }->
  #Mount NFS filesystem for DB WAL Archives
  mount { 'db_archive':
    ensure  => 'mounted',
    name    => '/mnt/db_archive',
    device  => 'nfs-server:/var/nfs/db_archive',
    fstype  => 'nfs4',
    options => 'defaults',
  }

  class { 'selinux':
    mode => 'permissive',
  }

  cron { 'pg_sql_bkup':
    ensure  => 'present',
    command => 'su - postgres -c /vagrant/run_db_bkup.sh',
    user    => root,
    hour    => 1,
    weekday => 7,
  }
}
