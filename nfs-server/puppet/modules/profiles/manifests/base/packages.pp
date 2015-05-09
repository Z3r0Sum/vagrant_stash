#Add on some packages to the base OS
class profiles::base::packages {

  $packages = [
    'vim-enhanced',
    'zsh',
    'git',
  ]

  package { $packages:
    ensure => 'installed',
  }
}
