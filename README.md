#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
4. [Usage](#usage)
5. [Reference](#reference)
5. [Limitations](#limitations)
6. [Development](#development)

## Overview

This module installs Docker components and provides defines to build, push and run containers.

It is compatible only with Puppet version 4 or newer.

## Module Description

The module installs the following Docker components:

  - Docker Engine (```include ::docker```)
  - Docker Swarm (```include ::docker::profile::swarm```) TODO
  - Docker Compose (```include ::docker::profile::compose```)
  - Docker Machine (```include ::docker::profile::machine```) TODO
  - Docker Registry (```include ::docker::profile::registry```) TODO

It also can configure nodes for different functions:

  - Docker Host server, where containers are running (```include ::docker::profile::host```)
  - Docker Build server, where images are build (```include ::docker::profile::builder```)

It provides Puppet user defines for different functions:

  - ```::docker::run``` to run containers (either as services or via direct exec)
  - ```::docker::tp_build``` to build images via tp (no Puppet installed on images)
  - ```::docker::push``` to push images to Docker's registry

This module follows these design principles:

  - Main class just installs the application using a customisable ```install_class```
  - Parameters on the main class are the entrypoint for all the general configurations
  - Profiles in module provide more or less opinionated setups for specific use cases or related software
  - Tiny Puppet is used inside the module, with local data

## Setup

To install Docker engine without any further configuration just:

    include ::docker

To install one of the internal profiles for different Docker applications or use cases:

    include ::docker::profile::<profile>


## Usage

The module's common paramateres entry point is the main class, which is included by all the profiles and defines.

The most important parameters (here written as configurable via Hiera with Yaml backend, you can obviously pass them when declaring the docker class):

    # Manage installation or removal
    docker::ensure: present # Default
   
    # Define what class to use to install Docker
    docker::install_class: '::docker::install::tp' # Default installation via Tiny Puppet

    # Set the username for Docker Hub (required when building or pushing images)
    docker::username: 'example42'

    # Override the settings defined in the module's data
    # Default is an empty hash, here an example to override the url of the repo and the GPG key to use 
    docker::settings:
      repo_url: 'http://packages.example.com'
      key_url: 'http://packages.example.com/gpg'

    # Set any option you may want to use in templates 
    docker::options:
      my_key: my_value # In an erb template this is accessed with <%= @options['my_key'] %> 

    # Define what module to use for Tiny Puppet data:
    docker::data_module: docker # Default

    # Define the tinydata module to use when building images for different apps
    docker::tinydata_module: tinydata # Default


## Reference

### class docker::profile::builder

This profile configures a node to act as a Docker images build system.

It builds images via the ```::docker::tp_build define``` using base images with the same OS of the node (to build images for different OSes check the [http://github.com/example42/control-repo](Example42 control repo) instructions about MultiOS Docker building.

Note that the image building process is done on official base images **without** installing Puppet on them: Tiny Puppet's data is used, on the builder host, to create Dockerfiles and the configuration files to copy on the images. 

The images to build are defined in the ```images``` hash. The following example creates 4 images (respectively with nginx, apahe, redis and tomcat) with various configuration examples:

    docker::profile::builder::images:
      # Build an nginx image, with custom nginx.conf and ecommerce.conf virtualhost file
      nginx:
        ensure: present
        conf_hash:
          nginx::nginx.conf:
            template: 'profile/ecommerce/nginx/nginx.conf.erb'
            path: '/etc/nginx/nginx.conf'
          nginx::ecommerce.conf:
            template: 'profile/ecommerce/nginx/ecommerce.conf.erb'
            base_dir: 'conf'

      # Just an apache image with default settings (the used image OS is the one of the building host)
      apache:
        ensure: present

      # Build a redis image using a custom Dockerfile template with an added custom redis.conf template with relevant options
      redis:
        ensure: present
        template: 'profile/ecommerce/redis/Dockerfile.erb'
        conf_hash:
          redis::conf:
            path: '/etc/redis.conf'
            template: 'profile/ecommerce/redis/redis.conf.erb'
            base_file: 'config'
            options_hash:
              redis_version: '3.2.0'

      # Build a tomcat image using the official tomcat image and a custom Dockerfile
      tomcat:
        ensure: present
        from: tomcat
        template: 'profile/ecommerce/tomcat/Dockerfile.erb'


Various parameters of this class allow you to set the default settings for these images (you can override them for each image):

    # The erb template to use for the Dockerfile
    docker::profile::builder::template: 'docker/Dockerfile.erb' # Default.

    # The working directory where all the Dockerbuild and build roots are created:
    docker::profile::builder::workdir: '/var/dockerfiles' # Default

    # The Maintainer string to add to the Dockerfile
    docker::profile::builder::maintainer: undef # Default

    # The from field to add to the Dockerfile. By default official Docker images are used according to the underlying OS.
    # Note that if you choose a base image with a different OS things won't probably work as expected (you need to have a MultiOS build setup for that)
    docker::profile::builder::from: ''  # Default

    # The image OS and version to use (by default they are autocalculated according to OS facts):
    docker::profile::builder::default_image_os: centos # Default is downcase($::operatingsystem)
    docker::profile::builder::default_image_osversion: 7 # Default is $::operatingsystemmajrelease

    # The repository tag (on Docker Hub) to use. Default: ```"${default_image_os}-${default_image_osversion}"```
    docker::profile::builder::repository_tag

    # An array of environment variables for the docker build exec resource
    docker::profile::builder::exec_environment:
      - 'http_proxy=proxy.example.com'
  
    # An option to force image building at every puppet run, even if no changes have occurred
    docker::profile::builder::always_build: false # Default

    # Optional extra options to pass to the docker build command
    docker::profile::builder::build_options: '' # Default

    # How the application inside the image should be run: via command or supervisor
    docker::profile::builder::command_mode: 'supervisor'


### class docker::profile::host

This class configures a node to run as Docker host, with different instances as defined via the ```instances``` hash.
In the following example 4 instances are being enabled. The solr one is from an explicitly named image. When the image is not specified this name is based on ```"${username}/${instance}:${repository_tag}"```.

    docker::profile::host::instances:
      nginx:
        ensure: present
      redis:
        ensure: present
      apache:
        ensure: present
      solr:
        ensure: present
        image: solr
    
Also here you can set some defaults to apply to all the instances:

    # An array of environment variables for the docker run exec resource
    docker::profile::host::exec_environment:
      - 'http_proxy=proxy.example.com'

    # How the instance should be run: via direct docker run ```command``` or as a ```service```:
    docker::profile::host::run_mode: 'service' # Default

    # If to mount separately the data and the log directories (if present in the Dockerfile)
    docker::profile::host::mount_data_dir: true # Default
    docker::profile::host::mount_log_dir: true # Default

    # The repository tag (on Docker Hub) to use.
    docker::profile::host::repository_tag: latest # Default


### class docker::profile::compose

This class installs docker-compose directly from GitHub. 

    # To manage installation status
    docker::profile::compose::ensure: present # Default
    
    # To specify the version to install
    docker::profile::compose::version: '1.7.0' # Default is set in $settings['compose_version']

### define docker::run

This define manages the execution of a container. Usage is like:

  ::docker::run { 'jenkins':
    image            => 'jenkins',
    run_mode         => 'command',
    run_options      => '-p 8080:8080 -p 50000:50000',
  }

  If no ```image``` is set, the base image is ```"${username}/${repository}:${repository_tag}"``` (use this for custom images created with docker::push):

  ::docker::run { 'puppet-agent': }

Check che class ```docker::profile::run_examples.pp``` for more usage samples.


### define docker::tp_build

TODO


### define docker::push

TODO


## Limitations

This module needs the following modules:

  - puppetlabs-stdlib
  - example42-tp
  - example42-tinydata

This module works only on Puppet 4 or newer versions. It **might** work with Puppet 3 with future parser enabled.


## Development

Please use GitHub for any contribution, bug notification or feature request about this module.

If you use it, we welcome your rating on the Puppet Forge and any suggestion you may have to make it better.
