class docker::profile::host (

  Variant[Boolean,String] $ensure              = present,
  Hash                    $instances           = {},

  Variant[Undef,String]   $repository_tag      = 'latest',

  Variant[Undef,Array]    $exec_environment    = [],
  Variant[Boolean,Pattern[/on_failure/]] $exec_logoutput = 'on_failure',

  Pattern[/command|service/] $run_mode         = 'service',

  Boolean                 $mount_data_dir      = true,
  Boolean                 $mount_log_dir       = true,

) {

  include ::docker

  $instances.each |$instance,$opts| {

    docker::run { $instance:
      ensure           => pick_default($opts['ensure'],$ensure),
      username         => pick_default($opts['username'],$::docker::username),
      repository       => pick_default($opts['repository'],$app),
      repository_tag   => pick_default($opts['repository_tag'],$repository_tag),
      exec_environment => pick_default($opts['exec_environment'],$exec_environment),
      exec_logoutput   => pick_default($opts['exec_logoutput'],$exec_logoutput),
      run_mode         => pick_default($opts['run_mode'],$run_mode),
      mount_data_dir   => pick_default($opts['mount_data_dir'],$mount_data_dir),
      mount_log_dir    => pick_default($opts['mount_log_dir'],$mount_log_dir),
    }
  }

}
