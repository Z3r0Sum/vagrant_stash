#Stash server
class profiles::stash::server {

  require profiles::stash::pgsql::master
  require profiles::stash::fw

  $dbuser              = hiera('pgsql_server::user')
  $dbpassword          = hiera('pgsql_server::password')
  $db_name             = hiera('pgsql_server::db_name')
  $version             = hiera('stash::version')
  $installdir          = hiera('stash::installdir')
  $homedir             = hiera('stash::homedir')
  $javahome            = hiera('stash::javahome')
  $dburl               = hiera('stash::dburl')
  $backupclientVersion = hiera('stash::backupclientVersion')
  $backup_home         = hiera('stash::backup_home')
  $backupuser          = hiera('stash::backupuser')
  $backuppass          = hiera('stash::backuppass')
  $dir_arry            = [
    '/opt/atlassian',
    $installdir
  ]

  class { '::java': }->
  file { $dir_arry:
    ensure => 'directory',
  }->
  class { '::stash':
    version             => $version,
    installdir          => $installdir,
    homedir             => $homedir,
    javahome            => $javahome,
    dbuser              => $dbuser,
    dbpassword          => $dbpassword,
    dburl               => $dburl,
    repoforge           => false,
    backup_ensure       => present,
    backupclientVersion => $backupclientVersion,
    backup_home         => $backup_home,
    backupuser          => $backupuser,
    backuppass          => $backuppass,
  }
  class { '::stash::facts': }
}

