class docker::profile::builder (

  Variant[Boolean,String] $ensure              = present,
  Hash                    $images              = {},

  Variant[Undef,String]   $template            = 'docker/Dockerfile.erb',
  String[1]               $workdir             = '/var/tmp',


  String[1]               $default_os          = downcase($::operatingsystem),
  String[1]               $default_osversion   = $::operatingsystemmajrelease,

  Variant[Undef,String]   $maintainer          = undef,
  String                  $from                = '',

  Variant[Undef,String]   $repository_tag      = 'latest',

  Variant[Undef,Array]    $exec_environment    = [],
  Variant[Boolean,Pattern[/on_failure/]] $exec_logoutput = 'on_failure',

  String                  $build_options       = '',
  Pattern[/command|supervisor/] $command_mode  = 'supervisor',

  Boolean                 $mount_data_dir      = true,
  Boolean                 $mount_log_dir       = true,

) {

  include ::docker

  tp::dir { 'docker::tp-dockerfiles':
    source      => 'https://github.com/example42/tp-dockerfiles',
    path        => '/etc/tp-dockerfiles',
    vcsrepo     => 'git',
    data_module => $::docker::data_module,
  }

  $images.each |$image,$opts| {

    docker::build { $image:
      ensure           => pick_default($opts['ensure'],$ensure),
      template         => pick_default($opts['template'],$template),
      workdir          => pick_default($opts['workdir'],$workdir),
      username         => pick_default($opts['username'],$::docker::username),
      image_os         => pick_default($opts['image_os'],$default_os),
      image_osversion  => pick_default($opts['image_osversion'],$default_osversion),
      maintainer       => pick_default($opts['maintainer'],$maintainer),
      from             => pick_default($opts['from'],$from),
      repository       => pick_default($opts['repository'],$image),
      repository_tag   => pick_default($opts['repository_tag'],$repository_tag),
      exec_environment => pick_default($opts['exec_environment'],$exec_environment),
      exec_logoutput   => pick_default($opts['exec_logoutput'],$exec_logoutput),
      build_options    => pick_default($opts['build_options'],$build_options),
      command_mode     => pick_default($opts['command_mode'],$command_mode),
      mount_data_dir   => pick_default($opts['mount_data_dir'],$mount_data_dir),
      mount_log_dir    => pick_default($opts['mount_log_dir'],$mount_log_dir),
      settings_hash    => $settings_hash,
      data_module      => $data_module,
    }
  }

}
