#NFS Server for pgsql backups
class profiles::nfs::server {

  include ::profiles::base::packages
  include ::profiles::base::hosts
  include ::profiles::nfs::fw

  $nfs_user = hiera('nfs_server::user')
  $exports_content = '/var/nfs/db_bkup   *(rw,sync,no_root_squash,no_all_squash)
/var/nfs/db_archive *(rw,sync,no_root_squash,no_all_squash)'
                      

  $additional_pkgs = [
    'nfs-utils'
  ]

  package { $additional_pkgs:
    ensure => 'installed',
  }

  group { 'postgres_sql':
    ensure => 'present',
    name   => 'postgres',
    gid    => '26',
  }

  user { 'postgres':
    ensure  => 'present',
    comment => 'PostgreSQL User for NFS',
    shell   => '/bin/bash',
    uid     => '26',
    gid     => '26',
  }

  file { '/var/nfs':
    ensure => 'directory',
    mode   => '0770',
    owner  => 'postgres',
    group  => 'postgres',
  }

  user { $nfs_user:
    ensure     => 'present',
    comment    => 'Database user',
    shell      => '/bin/bash',
    managehome => true,
  }

  file { '/var/nfs/db_bkup':
    ensure => 'directory',
    mode   => '0770',
    owner  => 'postgres',
    group  => 'postgres',
  }

  file { '/var/nfs/db_archive':
    ensure => 'directory',
    mode   => '0770',
    owner  => 'postgres',
    group  => 'postgres',
  }

  file { '/etc/exports':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $exports_content,
    notify  => Service['nfs-server'],
  }

  service { 'rpcbind':
    ensure => 'running',
    enable => true,
  }

  service { 'nfs-server':
    ensure => 'running',
    enable => true,
  }

  class { 'selinux':
    mode => 'permissive',
  }

  Package[$additional_pkgs]->
  User['postgres']->
  File['/var/nfs']->
  User[$nfs_user]->
  File['/var/nfs/db_bkup']->
  File['/var/nfs/db_archive']->
  File['/etc/exports']->
  Service['rpcbind']->
  Service['nfs-server']

}
