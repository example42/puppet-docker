class docker::install::tp (

  Variant[Boolean,String] $ensure           = present,
  Hash                    $confs            = { },
  Hash                    $dirs             = { },

) {

  include ::docker
  
  tp::install { 'docker':
    options_hash  => $::docker::options,
    settings_hash => $::docker::module_settings,
    data_module   => $::docker::data_module,
    conf_hash     => $confs,
    dir_hash      => $dirs,
    auto_conf     => $::docker::auto_conf,
  }

}
