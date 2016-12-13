class docker::profile::build_examples (

  Variant[Boolean,String] $ensure              = present,

) {

  include ::docker

  # Run, in command mode, a container based on official jenkins image
  ::docker::tp_build { 'memcached': 
    ensure           => $ensure,
  }

}
