class docker::profile::run_examples (

  Variant[Boolean,String] $ensure              = present,

) {

  include ::docker

  # Run, in command mode, a container based on official jenkins image
  ::docker::run { 'jenkins':
    ensure           => $ensure,
    image            => 'jenkins',
    run_mode         => 'command',
    run_options      => '-p 8080:8080 -p 50000:50000',
    require          => Class['docker'],
  }

  # Run a local image built with docker::push
#  ::docker::run { 'puppet-agent': 
#    ensure           => $ensure,
#    require          => Class['docker'],
#  }
#  ::docker::run { 'apache': 
#    ensure           => $ensure,
#    require          => Class['docker'],
#  }


  # Run, in service mode (an init file is created and a service started), an official redis instance
  ::docker::run { 'redis':
    ensure           => $ensure,
    image            => 'redis',
    # run_mode         => 'service',
    container_name   => 'official_redis',
    require          => Class['docker'],
  }
 
  ::docker::run { 'registry':
    ensure           => $ensure,
    image            => 'registry',
    repository_tag   => '2.4.0',
    run_mode         => 'command',
    run_options      => '-p 5000:5000',
    require          => Class['docker'],
  }

  ::docker::run { 'admiral':
    ensure           => $ensure,
    image            => 'vmware/admiral',
    run_mode         => 'service',
    run_options      => '-p 8282:8282',
    require          => Class['docker'],
  }

}
