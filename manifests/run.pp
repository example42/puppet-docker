# @define docker::run
#
# This define manages and runs a container based on the given docker image
#
define docker::run (

  String[1]               $ensure              = 'running',

  String[1]               $username            = undef,
  Variant[Undef,String]   $repository          = $title,
  Variant[Undef,String]   $repository_tag      = undef,

  String                  $container_name      = $title,

  Pattern[/service|command/] $run_mode         = 'command',
  String                     $run_options      = '',

  Variant[Undef,Array]    $exec_environment    = undef,
  Variant[Boolean,Pattern[/on_failure/]] $exec_logoutput = 'on_failure',

  Variant[Undef,String]   $init_template       = 'docker/init.erb',

  Boolean                 $mount_data_dir      = true,
  Boolean                 $mount_log_dir       = true,

  Hash                    $settings            = { },

  ) {

  include ::docker

  $real_username = $username ? {
    undef   => $::docker::username,
    default => $username
  }
  $app = $title
  $tp_app_settings = tp_lookup($app,'settings',$::docker::tinydata_module,'merge')
  $app_settings = $tp_app_settings + $settings

  if $run_mode == 'command' {
    Exec {
      path        => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin',
      timeout     => 3000,
      environment => $exec_environment,
      logoutput   => $exec_logoutput,
    }

    exec { "docker run ${real_username}/${repository}:${repository_tag}":
      command     => "docker run ${run_options} ${real_username}/${repository}:${repository_tag}",
      unless      => "docker ps | grep ${real_username}/${repository} | grep ${repository_tag}",
    }
  }

  if $run_mode == 'service' {
    $service_ensure = $ensure ? {
      'absent' => 'stopped',
      false    => 'stopped',
      default  => $::docker::module_settings['service_ensure'],
    }
    $service_enable = $ensure ? {
      'absent' => false,
      false    => false,
      default  => $::docker::module_settings['service_enable'],
    }
    file { "/etc/init/docker-${app}.conf":
      ensure  => $ensure,
      content => template($init_template),
      mode    => '0755',
      notify  => Service["docker-${app}"],
    }
    service { "docker-${app}":
      ensure  => $service_ensure,
      enable  => $service_enable,
    }
  }
}
