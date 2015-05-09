#Add on some packages to the base OS
class profiles::base::packages {

  $packages = [
    'vim-enhanced',
    'zsh',
    'git',
    'nfs-utils',
    'postgresql-contrib',
  ]

  package { $packages:
    ensure => 'installed',
  }
}
