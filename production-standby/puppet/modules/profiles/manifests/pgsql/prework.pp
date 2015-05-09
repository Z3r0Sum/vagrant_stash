#Prework to lay down filesystems and restore from master.
class profiles::pgsql::prework {

  $dir_arry = [
    '/var/lib/pgsql',
    '/var/lib/pgsql/data',
    '/var/lib/pgsql/backups',
    '/var/lib/pgsql/data/pg_xlog'
  ]

  #Need postgres group
  group { 'postgres':
    ensure => 'present',
    gid    => '26',
  }->
  #Need postgres user
  user { 'postgres':
    ensure  => 'present',
    gid     => '26',
    uid     => '26',
    shell   => '/bin/bash',
    home    => '/var/lib/pgsql',
    comment => 'PostgreSQL Server',
  }->
  #Create directory for NFS WAL Archives
  file { '/mnt/db_archive':
    ensure => 'directory',
    owner  => 'postgres',
    group  => 'postgres',
    mode   => '0775',
  }->
  #Mount NFS filesystem for DB WAL Archives
  mount { 'db_archive':
    ensure  => 'mounted',
    name    => '/mnt/db_archive',
    device  => 'nfs-server:/var/nfs/db_archive',
    fstype  => 'nfs4',
    options => 'defaults',
  }->
  #Create directory for NFS backups
  file { '/mnt/db_bkup':
    ensure => 'directory',
    owner  => 'postgres',
    group  => 'postgres',
    mode   => '0775',
  }->
  #Mount NFS filesystem for DB backup
  mount { 'db_bkup':
    ensure  => 'mounted',
    name    => '/mnt/db_bkup',
    device  => 'nfs-server:/var/nfs/db_bkup',
    fstype  => 'nfs4',
    options =>  'defaults',
  }->
  #Left with no choice, since the postgresql module manages this stuff with 
  #file resources already
  exec { 'create pgsql dirs':
    path    => ['/bin','/usr/bin'],
    command => 'mkdir -p /var/lib/pgsql/{backups,data}',
    unless  => 'test -d /var/lib/pgsql/data',
  }->
  exec { 'create pg_xlog dir':
    path    => ['/bin','/usr/bin'],
    command => 'mkdir -p /var/lib/pgsql/data/pg_xlog',
    unless  => 'test -d /var/lib/pgsql/data/pg_xlog',
  }->
  exec { 'chown pgsql dirs':
    path    => ['/bin','/usr/bin'],
    command => 'chown -R postgres:postgres /var/lib/pgsql',
  }->
  #Need to restore from a backup from the primary PostgreSQL server before
  #we can startup the hot-standby server.
  exec { '/vagrant/restore_bkup.rb':
    path    => ['/bin','/usr/bin'],
    unless  => 'test -f /var/lib/pgsql/data/.restored_from_bkup',
    command => 'su - postgres -c "/vagrant/restore_bkup.rb"',
  }
}
