# == Define: single_user_rvm::install
#
# Installs RVM.
#
# More info on installation: https://rvm.io/rvm/install
#
# === Parameters
#
# Document parameters here
#
# [*user*]
#   The user for which RVM will be installed. Defaults to the value of the title string.
#
# [*version*]
#   Version of RVM to install. This version *will* be enforced. That is, the current RVM version will be tested against
#   this and if different it will be changed to the one specified. However this does not mean that setting the version
#   to one that changes (like stable or latest) will pull the latest of that version and apply it. To enable that kind
#   of behaviour use the auto_upgrade parameter. Defaults to 'stable'.
#
#   More info on versions: https://rvm.io/rvm/upgrading.
#
# [*rvmrc*]
#   Content for the global .rvmrc file placed in the user's homedir. If empty, .rvmrc will no be touched.
#   Defaults to ''.
#
# [*home*]
#   Set to home directory of user. Defaults to /home/${user}.
#
# [*auto_upgrade*]
#   Set to true to enable automatically upgrading RVM. That essentially means that `rvm get $version` will be run on
#   every puppet run. This essentially breaks the puppet "idempotent" feature but that may be desireable as there's no
#   other way to ensure you always have the latest stable or latest master version for example. This setting probably
#   makes no sense combined with a static version (like 1.22.0 for example) as there will never be something new to
#   fetch. Defaults to false.
#
# === Examples
#
# Plain simple installation for user 'dude'
#
#   single_user_rvm::install { 'dude': }
#
# Install version 'head' for user dude
#
#   single_user_rvm::install { 'dude':
#     version => 'head',
#   }
#
# Ensure always having the latest and greatest RVM.
#
#   single_user_rvm::install { 'dude':
#     version      => 'latest',
#     auto_upgrade => true,
#   }
#
# Set .rvmrc configuration (example auto-trusts all rvmrc's in the system).
#
#   single_user_rvm::install { 'dude':
#     rvmrc => 'rvm_trust_rvmrcs_flag=1',
#   }
#
# Use a custom home directory.
#
#   single_user_rvm::install { 'dude':
#     home  => '/path/to/special/home',
#   }
#
# Use a title different than the user name.
#
#   single_user_rvm::install { 'some other title':
#     user  => 'dude',
#     rvmrc => 'rvm_trust_rvmrcs_flag=1',
#     home  => '/path/to/special/home',
#   }
#
define single_user_rvm::install (
  $user         = $title,
  $version      = 'stable',
  $rvmrc        = '',
  $home         = '',
) {

  if $home {
    $homedir = $home
  } else {
    $homedir = "/home/${user}"
  }

  require single_user_rvm::dependencies
  $import_key = "curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -"
  $install_command = "curl -L https://get.rvm.io | bash -s ${version}"
  
  exec { $import_key:
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    user        => "${user}",
    onlyif      => "test `gpg --list-keys | grep 'RVM signing' | wc -l` -eq 0",
    cwd         => $homedir,
    environment => "HOME=${homedir}",
  }
  exec { $install_command:
    path        => '/usr/bin:/usr/sbin:/bin',
    creates     => "${homedir}/.rvm/bin/rvm",
    require     => [ Package['curl'], Package['bash'], User[$user], Exec[$import_key] ],
    user        => "${user}",
    cwd         => $homedir,
    environment => "HOME=${homedir}"
  }

  if $rvmrc {
    file { "${homedir}/.rvmrc":
      ensure  => present,
      owner   => $user,
      content => $rvmrc,
      require => User[$user],
    }
  }

}
