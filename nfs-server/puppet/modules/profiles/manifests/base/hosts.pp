#Manage /etc/hosts - add all machines in project.
class profiles::base::hosts {

  host { 'nfs-server':
    ensure       => 'present',
    comment      => 'NFS Server for DB backup',
    host_aliases => 'nfs-server',
    ip           => '172.16.254.10',
  }

  host { 'stash-server':
    ensure       => 'present',
    comment      => 'stash server',
    host_aliases => 'stash-server',
    ip           => '172.16.254.11',
  }

  host { 'production-db-standby':
    ensure       => 'present',
    comment      => 'pgsql standby server',
    host_aliases => 'production-db-standby',
    ip           => '172.16.254.12',
  }
}
