# @define docker::build
#
define docker::build (

  String[1]               $ensure              = 'present',

  Variant[Undef,String]   $template            = 'docker/Dockerfile.erb',
  String[1]               $workdir             = '/var/tmp',

  String[1]               $username            = '',

  String[1]               $image_os            = downcase($::operatingsystem),
  String[1]               $image_osversion     = $::operatingsystemmajrelease,

  Variant[Undef,String]   $maintainer          = undef,
  String                  $from                = '',

  Variant[Undef,String]   $repository          = $title,
  Variant[Undef,String]   $repository_tag      = 'latest',

  Variant[Undef,Array]    $exec_environment    = undef,
  Variant[Boolean,Pattern[/on_failure/]] $exec_logoutput = 'on_failure',

  String                  $build_options       = '',
  Pattern[/command|supervisor/] $command_mode  = 'supervisor',

  Boolean                 $mount_data_dir      = true,
  Boolean                 $mount_log_dir       = true,

  Boolean                 $copy_data_on_image  = true,
  Hash                    $conf_hash           = { },
  Hash                    $dir_hash            = { },

  Hash                    $settings_hash       = {},

  String[1]               $data_module         = 'tinydata',

  ) {

  include ::docker

  # Settings evaluation
  $title_elements = split ($title, '::')
  $app = $title_elements[0]
  $tp_settings = tp_lookup($app,'settings',$data_module,'merge')
  $settings_supervisor = tp_lookup('supervisor','settings',$data_module,'merge')
  $settings = $tp_settings + $settings_hash

  $real_from = $from ? {
    ''      => "${image_os}:${image_osversion}",
    default => $from,
  }
  $basedir_path = "${workdir}/${username}/${image_os}/${image_osversion}/${app}"
  $image_name = "${username}/${repository}:${repository_tag}"

  Exec {
    path    => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin',
    timeout => 3000,
  }

  # Dockerfile creation
  exec { "mkdir -p ${basedir_path}/root":
    creates => "${basedir_path}/root",
  } ->
  file { [ "${basedir_path}/Dockerfile" , "${basedir_path}/root/Dockerfile" ]:
    ensure  => $ensure,
    content => template($template),
  }

  # Extra confs or dirs creation
  $conf_hash.each |$conf_name,$conf_options| {
    tp::conf { "${conf_name}::docker::build":
      ensure              => pick_default($conf_options['ensure'],present),
      source              => pick_undef($conf_options['source']),
      template            => pick_undef($conf_options['template']),
      epp                 => pick_undef($conf_options['epp']),
      content             => pick_undef($conf_options['content']),
      base_dir            => pick_undef($conf_options['base_dir']),
      base_file           => pick_default($conf_options['base_file'],'config'),
      path                => pick_undef($conf_options['path']),
      mode                => pick_undef($conf_options['mode']),
      owner               => pick_undef($conf_options['owner']),
      group               => pick_undef($conf_options['group']),
      path_prefix         => "${basedir_path}/root",
      path_parent_create  => true,
      config_file_notify  => false,
      config_file_require => false,
      options_hash        => pick_default($conf_options['options_hash'],{ }),
      settings_hash       => pick_default($conf_options['settings_hash'],{ } ),
      data_module         => pick_default($conf_options['data_module'],'tinydata'),
      notify              => Exec["docker build ${build_options} -t ${image_name} ${basedir_path}"],
    }
  }

  $dir_hash.each |$dir_name,$dir_options| {
    tp::dir { "${dir_name}::docker::build":
      ensure              => pick_default($dir_options['ensure'],present),
      source              => pick_undef($dir_options['source']),
      vcsrepo             => pick_undef($dir_options['vcsrepo']),
      base_dir            => pick_default($dir_options['base_dir'],'config'),
      path                => pick_undef($dir_options['path']),
      mode                => pick_undef($dir_options['mode']),
      owner               => pick_undef($dir_options['owner']),
      group               => pick_undef($dir_options['group']),
      path_prefix         => "${basedir_path}/root",
      path_parent_create  => true,
      config_dir_notify   => false,
      config_dir_require  => false,
      purge               => pick_default($dir_options['purge'],false),
      recurse             => pick_default($dir_options['recurse'],false),
      force               => pick_default($dir_options['force'],false),
      settings_hash       => pick_default($dir_options['settings_hash'],{ } ),
      data_module         => pick_default($dir_options['data_module'],'tinydata'),
      notify              => Exec["docker build ${build_options} -t ${image_name} ${basedir_path}"],
    }
  }

  exec { "docker build ${build_options} -t ${image_name} ${basedir_path}":
    command     => "docker build ${build_options} -t ${image_name} ${basedir_path}",
    cwd         => $basedir_path,
    subscribe   => File["${basedir_path}/Dockerfile"],
    environment => $exec_environment,
    logoutput   => $exec_logoutput,
    refreshonly => true,
    require     => Class['docker'],
  }

}
