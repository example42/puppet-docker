# @class docker
#
class docker (

  Variant[Boolean,String] $ensure           = present,
  String[1]               $username         = 'example42',
  
  Hash                    $confs            = { },
  Hash                    $dirs             = { },

  Hash                    $options          = { },
  Hash                    $settings         = { },

  Array                   $profiles         = [],

  Boolean                 $auto_restart     = true,
  Boolean                 $auto_conf        = false,

  Variant[Undef,Hash]     $run                 = undef,
  Variant[Undef,Hash]     $build               = undef,
  Variant[Undef,Hash]     $test                = undef,
  Variant[Undef,Hash]     $push                = undef,

  String[1]               $data_module         = 'docker',
  String[1]               $tinydata_module     = 'tinydata',

  ) {


  $tp_settings = tp_lookup('docker','settings',$data_module,'merge')
  $module_settings = $tp_settings + $settings
  if $module_settings['service_name'] and $auto_restart {
    $service_notify = "Service[${module_settings['service_name']}]"
  } else {
    $service_notify = undef
  }

  tp::install { 'docker':
    options_hash  => $options,
    settings_hash => $module_settings,
    data_module   => $data_module,
    conf_hash     => $confs,
    dir_hash      => $dirs,
    auto_conf     => $auto_conf,
  }

  if $profiles != [] {
    $profiles.each |$kl| {
      include "::docker::profile::${kl}"
    }
  }

  if $run {
    create_resources('docker::run', $run )
  }
  if $build {
    create_resources('docker::build', $build )
  }
  if $test {
    create_resources('docker::test', $test )
  }
  if $push {
    create_resources('docker::push', $push )
  }
}
