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
  }

  # Run a local image built with docker::push
  ::docker::run { 'puppet-agent': 
    ensure           => $ensure,
  }
  ::docker::run { 'apache': 
    ensure           => $ensure,
  }


  # Run, in service mode (an init file is created and a service started), an official redis instance
  ::docker::run { 'redis':
    ensure           => $ensure,
    image            => 'redis',
    # run_mode         => 'service',
    container_name   => 'official_redis',
  }
 
  ::docker::run { 'registry':
    ensure           => $ensure,
    image            => 'registry',
    repository_tag   => '2.4.0',
    run_mode         => 'command',
    run_options      => '-p 5000:5000',
  }

}
