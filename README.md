# OpenFlight Vagrant Cluster

Create an OpenFlight Compute cluster using Vagrant suitable for active
development work on OpenFlight R&D projects.

## Prerequisites

An installation of a recent version of Vagrant.

## Create a Cluster

- Navigate to the root of this repository

    ```
    cd openflight-vagrant-cluster
    ```

- Create a cluster

    ```
    vagrant up
    ```

## Using the cluster

- SSH into the cluster

    ```
    vagrant ssh chead1
    ```

## Configuration

TBD.

- FLIGHT_CODE, NUM_NODES, cluster name, private ip, ansible playbook/roles


## Developing applications

By default the directory `~/code` will be mounted on `chead1` at `/code`.

This can be used to develop and test applications.

## Known limitations

- SSH issues. Until `flight start` is ran it is not possible for the `vagrant`
  user to SSH from one node on the cluster to another.  After `flight start`
  is ran `vagrant ssh` only works for `chead`.

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
