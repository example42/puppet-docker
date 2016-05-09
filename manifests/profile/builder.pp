class docker::profile::builder (

  Variant[Boolean,String] $ensure              = present,
  Hash                    $images              = {},

  Variant[Undef,String]   $template            = 'docker/Dockerfile.erb',
  String[1]               $workdir             = '/var/dockerfiles',

  Variant[Undef,String]   $maintainer          = undef,
  String                  $from                = '',

  Variant[Undef,String]   $default_image_os        = downcase($::operatingsystem),
  Variant[Undef,String]   $default_image_osversion = $::operatingsystemmajrelease,

  Variant[Undef,String]   $repository_tag      = undef,

  Variant[Undef,Array]    $exec_environment    = [],
  Variant[Boolean,Pattern[/on_failure/]] $exec_logoutput = 'on_failure',

  Boolean                 $always_build        = false,
  String                  $build_options       = '',
  Pattern[/command|supervisor/] $command_mode  = 'supervisor',

  Boolean                 $mount_data_dir      = true,
  Boolean                 $mount_log_dir       = true,

) {

  include ::docker

  $real_repository_tag=$repository_tag ? {
    undef   => "${default_image_os}-${default_image_osversion}",
    default => $repository_tag,
  }
  $images.each |$image,$opts| {
    docker::build { $image:
      ensure           => pick_default($opts['ensure'],$ensure),
      template         => pick_default($opts['template'],$template),
      workdir          => pick_default($opts['workdir'],$workdir),
      username         => pick_default($opts['username'],$::docker::username),
      image_os         => pick_default($opts['image_os'],$default_image_os),
      image_osversion  => pick($opts['image_osversion'],$default_image_osversion),
      maintainer       => pick($opts['maintainer'],$maintainer),
      from             => pick_default($opts['from'],$from),
      repository       => pick($opts['repository'],$image),
      repository_tag   => pick($opts['repository_tag'],$real_repository_tag),
      exec_environment => pick($opts['exec_environment'],$exec_environment),
      exec_logoutput   => pick($opts['exec_logoutput'],$exec_logoutput),
      always_build     => pick($opts['always_build'],$always_build),
      build_options    => pick_default($opts['build_options'],$build_options),
      command_mode     => pick($opts['command_mode'],$command_mode),
      mount_data_dir   => pick($opts['mount_data_dir'],$mount_data_dir),
      mount_log_dir    => pick($opts['mount_log_dir'],$mount_log_dir),
      conf_hash        => pick($opts['conf_hash'],{ }),
      dir_hash         => pick($opts['dir_hash'],{ }),
      data_module      => $::docker::tinydata_module,
    }
  }

}
