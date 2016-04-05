# @class tp_docker
#
class tp_docker (

  String[1]               $ensure              = 'present',

  Variant[Undef,Hash]     $run                 = undef,
  Variant[Undef,Hash]     $build               = undef,
  Variant[Undef,Hash]     $test                = undef,
  Variant[Undef,Hash]     $push                = undef,

  Hash                    $settings_hash       = {},

  String[1]               $data_module         = 'tinydata',

  ) {

  if $run {
    create_resources('tp_docker::run', $run )
  }
  if $build {
    create_resources('tp_docker::build', $build )
  }
  if $test {
    create_resources('tp_docker::test', $test )
  }
  if $push {
    create_resources('tp_docker::push', $push )
  }
}
