#Default node for site.pp
#Use for classification instead of traditional methods

Package {
  allow_virtual => false,
}

node default {
  include ::roles::stash
}
