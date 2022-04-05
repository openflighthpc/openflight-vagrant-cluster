# OpenFlight Vagrant Cluster

Create an OpenFlight Compute cluster using Vagrant suitable for development
work on OpenFlight R&D projects.

## Prerequisites

* An installation of a recent version of Vagrant.

If using OpenFlight Vagrant Cluster for development the following plugin is
highly recommended.

* The `vagrant-notify-forwarder` plugin:
  https://github.com/mhallin/vagrant-notify-forwarder

## Quick start

```
cd openflight-vagrant-cluster
vagrant up
vagrant ssh chead1
```

In case this doesn't work, see the next section on Configuration.

The host directory `~/code` is mounted on `chead1` at `/code`.  Develop your
project on your host and test it on `chead1`.

On the host

```
$EDITOR ~/code/flight-desktop/lib/desktop/cli.rb
```

On `chead1`

```
cd /code/flight-desktop
/opt/flight/bin/ruby ./bin/desktop --help
```

## Configuration

By default, an OpenFlight Vagrant Cluster consists of a gateway machine,
`chead1`, and a compute node `cnode01`.  The number of nodes can be changed by
editing [Vagrantfile](Vagrantfile) and changing the variable `NUM_NODES`.

The host directory `~/code` is mounted on `chead1` at `/code`.  This is the
directory where your OpenFlight projects should be found.  If you want a
directory other than `~/code` to be mounted on `chead1`, set the environment
variable `FLIGHT_CODE` when running `vagrant up`.

The nodes share a private network, which defaults to `172.17.177.0/24`. You
can change this by editing [Vagrantfile](Vagrantfile) and the [ansible group
vars](ansible/group_vars/all).

You can also change the ranges of IP addresses accepted by VirtualBox by
editing/creating `/etc/vbox/networks.conf`. Enter the ranges in the format: `*
<range1> <range2>` etc.

### SSH key configuration

By default vagrant will install custom SSH keys.  Unfotunately, there are some
issues surrounding use of those keys, NFS and ansible.

To work around those issues you will need to create a passwordless SSH key
pair and save them to `~/.ssh/openflight-vagrant-cluster.key` /
`~/.ssh/openflight-vagrant-cluster.key.pub`.

## Developing Flight User Suite applications

By default the directory `~/code` will be mounted on `chead1` at `/code`.

Command line applications can be tested by `cd`ing to the application's
directory and executing it from there.  For `flight-desktop`, a Ruby CLI
application, you would do the following:

```
cd /code/flight-desktop
/opt/flight/bin/ruby ./bin/desktop --help
```

## Developing Flight Web Suite applications

TODO: Finish documentation

* Flight Web Suite is configured with an SSL cert for `flight.lvh.me`.
* The Flight Web Suite applications are available on the host at
  http://fligth.lvh.me:8080 / https://flight.lvh.me:8443.

* A development landing page is available at https://flight.lvh.me:8443/dev.
  It links to the development versions of the web applications.  That is the
  applications at `/code/`.
* The development Flight Desktop Webapp is available at
  https://flight.lvh.me:8443/dev/desktop.

* Before the webapp can be used it needs to be configured to use either the
  development or RPM apis.  Edit the webapp's `.env.development` file.  E.g.,
  `/code/flight-desktop-webapp/.env.development`.  The file should be well
  commented.
* The webapp can be started by running `yarn run start` from the webapp's
  directory.
* If the webapp is using the development API, you will need to ensure that it
  is configured accoring to your requirements.  E.g., you may want
  `flight-job-script-api` to use `flight-job` located at `/code` or the one
  installed via RPM.

---

* Accessing the webapps via https://flight.lvh.me:8443/dev uses Flight WWW as
  a proxy.
* The webapps can also be accessed without proxying via Flight WWW.
  * To do so the webapp needs to be configured accordingly.  Do this by
    editing its `.env.development` file and restarting.
  * `chead1` will need to be restarted to expose the development ports.
    `EXPOSE_DEV_PORTS=true DEV_PORT_PREFIX=1 vagrant reload chead1`.
  * This will expose the ports used by the development apps to the host,
    prefixed by `1`.  So the Flight Desktop Webapp, which binds to port `3001`
    on `chead1` will be exposed to the host on port `13001`.  See [this
    file](ansible/roles/dev-setup/templates/dev-web-suite.conf) for ports used
    by other webapps.


# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2019-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Flight Desktop is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
