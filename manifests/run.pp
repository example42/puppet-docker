# @define tp_docker::run
#
# This define manages and runs a container based on the given docker image
#
define tp_docker::run (

  String[1]               $ensure              = 'running',

  String[1]               $username            = 'example42',
  Variant[Undef,String]   $repository          = $title,
  Variant[Undef,String]   $repository_tag      = undef,

  Pattern[/service|command/] $run_mode         = 'command',

  Variant[Undef,Array]    $exec_environment    = undef,
  Variant[Undef,String]   $init_template       = 'tp_docker/init.erb',

  Boolean                 $mount_data_dir      = true,
  Boolean                 $mount_log_dir       = true,

  Hash                    $settings_hash       = {},

  String[1]               $data_module         = 'tinydata',

  ) {

  $app = $title

  if $run_mode == 'command' {
    Exec {
      path        => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin',
      timeout     => 3000,
      environment => $exec_environment,
    }

    exec { "docker run ${username}/${repository}:${repository_tag}":
      unless      => "docker ps | grep ${username}/${repository} | grep ${repository_tag}",
    }
  }

  if $run_mode == 'service' {
    $service_ensure = $ensure ? {
      'absent' => 'stopped',
      false    => 'stopped',
      default  => $settings[service_ensure],
    }
    $service_enable = $ensure ? {
      'absent' => false,
      false    => false,
      default  => $settings[service_enable],
    }
    file { "/etc/init/docker-${app}":
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
