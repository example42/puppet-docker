# @define docker::run
#
# This define manages and runs a container based on the given docker image
#
define docker::run (

  String[1]               $ensure              = 'running',

  Variant[Undef,String]   $image               = undef,
  String                  $command             = '',

  String[1]               $username            = undef,
  Variant[Undef,String]   $repository          = $title,
  Variant[Undef,String]   $repository_tag      = undef,

  String                  $container_name      = $title,

  Pattern[/service|command/] $run_mode         = 'command',
  String                     $run_options      = '',
  String                     $service_prefix   = 'docker-',

  Boolean                 $remove_container_on_start = true,
  Boolean                 $remove_container_on_stop  = true,
  Boolean                 $remove_volume_on_start    = true,
  Boolean                 $remove_volume_on_stop     = true,

  Variant[Undef,Array]    $exec_environment    = undef,
  Variant[Boolean,Pattern[/on_failure/]] $exec_logoutput = 'on_failure',

  Variant[Undef,String]   $init_template       = undef,

  Boolean                 $mount_data_dir      = true,
  Boolean                 $mount_log_dir       = true,

  Hash                    $settings            = { },

  ) {

  include ::docker

  $real_username = $username ? {
    undef   => $::docker::username,
    default => $username
  }
  $app = regsubst($title, '[^0-9A-Za-z.\-]', '-', 'G')
  #  $tp_app_settings = tp_lookup($app,'settings',$::docker::tinydata_module,'merge')
  # $app_settings = $tp_app_settings + $settings


  if $run_mode == 'command' {
    Exec {
      path        => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin',
      timeout     => 3000,
      environment => $exec_environment,
      logoutput   => $exec_logoutput,
    }

    $real_image = $image ? {
      undef   => "${real_username}/${repository}:${repository_tag}",
      default => $image,
    }
    $cidfile = "/var/run/${service_prefix}${app}.cid"

    exec { "docker run ${real_image}":
      command     => "docker run -d ${run_options} --name ${app} --cidfile=${cidfile} ${real_image} ${command}",
      unless      => "docker ps --no-trunc -a | grep `cat ${cidfile}`",
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
    case $::docker::module_settings['init_system'] {
      'upstart': {
        $initscript_file_path = "/etc/init/${service_prefix}${app}.conf"
        $default_template = 'docker/run/upstart.erb'
        $init_file_mode = '0644'
      }
      'systemd': {
        $initscript_file_path = "/etc/systemd/system/${service_prefix}${app}.service"
        $default_template = 'docker/run/systemd.erb'
        $init_file_mode = '0644'
      }
      'sysvinit': {
        $initscript_file_path = "/etc/init.d/${service_prefix}${app}"
        $default_template = 'docker/run/sysvinit.erb'
        $init_file_mode = '0755'
      }
    }

    file { $initscript_file_path:
      ensure  => $ensure,
      content => template(pick_default($init_template,$default_template)),
      mode    => $init_file_mode,
      notify  => Service["docker-${app}"],
    }
    service { "docker-${app}":
      ensure  => $service_ensure,
      enable  => $service_enable,
    }
  }
}
