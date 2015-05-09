#Add on some packages to the base OS
class profiles::base::packages {

  $packages = [
    'vim-enhanced',
    'zsh',
    'nfs-utils',
  ]

  package { $packages:
    ensure => 'installed',
  }
}
