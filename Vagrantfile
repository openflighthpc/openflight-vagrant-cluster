# vim: set filetype=ruby:

FLAVOUR = ENV.fetch('FLAVOUR', 'dev')
unless %w(dev acceptance).include?(FLAVOUR)
  $stderr.puts <<-EOF
    Unknown flavour #{FLAVOUR.inspect}

    Environment variable FLAVOUR must be one of 'dev' or 'acceptance'
    Defaults to 'dev'.
  EOF
  exit 1
end

CODE_PATH = ENV['FLIGHT_CODE'] || "#{ENV['HOME']}/code"
if FLAVOUR == 'dev' && !File.directory?(File.expand_path(CODE_PATH))
  $stderr.puts <<-EOF
  Code path is not set.
  
  Either set the environment variable FLIGHT_CODE or create a symlink at
  $HOME/code pointing to the directory containing your OpenFlight github
  repositories.
  EOF
  exit 1
end

# Using Vagrant's inserted custom keys can result in suprising ansible
# behaviour on the compute nodes once NFS has been setup.  We avoid that
# behaviour by insisting on a single key used for all nodes.
SSH_PRV_KEY_PATH = File.expand_path('~/.ssh/openflight-vagrant-cluster.key')
SSH_PUB_KEY_PATH = "#{SSH_PRV_KEY_PATH}.pub"
if !File.file?(SSH_PRV_KEY_PATH) || !File.file?(SSH_PUB_KEY_PATH)
  $stderr.puts <<-EOF
    You need to create a passwordless SSH key-pair and save them to
    ~/.ssh/openflight-vagrant-cluster.key
    ~/.ssh/openflight-vagrant-cluster.key.pub
  EOF
  exit 1
end

Vagrant.configure("2") do |config|
  # Number of compute nodes.  Must be between 1 and 9.
  NUM_NODES = 1

  # NOTE: If changing the IP address below also change the network in
  # `nfs_shares`.
  nodes = [
    *(1..NUM_NODES).map do |idx|
      {
        vmname: "cnode0#{idx}",
        hostname: "cnode0#{idx}.flight.lvh.me",
        private_ip: "172.17.177.2#{idx}",
        ssh_port: 2300 + idx,
        type: 'node',
      }
    end,
    {
      vmname: 'chead1',
      hostname: 'chead1.flight.lvh.me',
      private_ip: '172.17.177.11',
      ssh_port: 2200,
      type: 'gateway',
    }
  ]

  # The openflight-vagrant-cluster key exists.  We insert it in much the
  # same way that Vagrant would insert a per-node key if
  # `config.ssh.insert_key = true`.  However, it is the same key for all
  # nodes and doesn't change once NFS is mounted on the compute nodes.
  config.ssh.forward_agent    = false
  config.ssh.insert_key       = false
  config.ssh.private_key_path =  ["~/.vagrant.d/insecure_private_key", SSH_PRV_KEY_PATH]
    .compact.select {|k| File.file?(File.expand_path(k))}

  config.vm.provision "shell", privileged: false do |s|
    if !SSH_PRV_KEY_PATH.nil? && !File.file?(SSH_PRV_KEY_PATH) || !File.file?(SSH_PUB_KEY_PATH)
      s.inline = <<-SHELL
        echo "No SSH key found. This should have been caught above. Fix this or things are likely broken. :shrug:"
        exit 0
      SHELL
    else
      ssh_prv_key = File.read(SSH_PRV_KEY_PATH)
      ssh_pub_key = File.readlines(SSH_PUB_KEY_PATH).first.strip
      s.inline = <<-SHELL
        if grep -sq "#{ssh_pub_key}" /home/$USER/.ssh/authorized_keys; then
          echo "SSH keys already provisioned."
          exit 0;
        fi
        echo "SSH key provisioning."
        mkdir -p /home/$USER/.ssh/
        touch /home/$USER/.ssh/authorized_keys
        echo #{ssh_pub_key} >> /home/$USER/.ssh/authorized_keys
        sed -i -s '/vagrant insecure public key/d' /home/$USER/.ssh/authorized_keys
        echo #{ssh_pub_key} > /home/$USER/.ssh/id_rsa.pub
        chmod 644 /home/$USER/.ssh/id_rsa.pub
        echo "#{ssh_prv_key}" > /home/$USER/.ssh/id_rsa
        chmod 600 /home/$USER/.ssh/id_rsa
        #chown -R $USER:$USER /home/$USER
        exit 0
      SHELL
    end
  end

  ansible_groups = {
    "gateway" => nodes.select{|n| n[:type] == 'gateway'}.map{|n| n[:vmname]},
    "nodes"   => nodes.select{|n| n[:type] == 'node'}.map{|n| n[:vmname]},
  }

  ansible_host_vars = nodes.select{|n| n[:type] == 'node'}.map do |node|
    # This needs to be the path as resolved on `chead1`.
    ansible_ssh_private_key_file = "/home/vagrant/.ssh/id_rsa"

    [
      node[:vmname], { 
        "ansible_host" => node[:private_ip],
        "ansible_ssh_private_key_file" => ansible_ssh_private_key_file,
        "ansible_ssh_extra_args" => "'-o StrictHostKeyChecking=no'",
      }
    ]
  end.to_h

  FLIGHTENV_DEV = ENV.key?('FLIGHTENV_DEV') ?
    ENV['FLIGHTENV_DEV'] != "false" :
    FLAVOUR == 'dev'
  BOOTSTRAP_GRIDWARE_BINARIES = ENV['BOOTSTRAP_GRIDWARE_BINARIES'] == "true"

  ansible_extra_vars = {
    'cluster_name' => ENV.fetch('CLUSTER_NAME', 'dev'),
    'compute_nodes' => "cnode[01-0#{NUM_NODES}]",
    'flightenv_dev' => FLIGHTENV_DEV,
    'bootstrap_gridware_binaries' => BOOTSTRAP_GRIDWARE_BINARIES,
    'munge_key' => SecureRandom.hex(48),
    'etc_host_entries' => nodes.map do |n|
      {
        name: n[:vmname],
        hostname: n[:hostname],
        ip: n[:private_ip],
      }
    end
  }
  if !ENV['BOOTSTRAP_DESKTOP_TYPES'].nil?
    ansible_extra_vars['bootstrap_desktop_types'] = ENV['BOOTSTRAP_DESKTOP_TYPES']
  end

  nodes.each do |node|
    is_gateway = node[:type] == 'gateway'

    config.vm.define node[:vmname], primary: is_gateway do |build|
      build.vm.box = "bento/centos-7"
      build.vm.hostname = node[:hostname]

      build.vm.network "private_network", ip: node[:private_ip]

      build.vm.network "forwarded_port",
        guest: 22,
        host: node[:ssh_port],
        id: 'ssh'

      if is_gateway
        # Expose Flight WWW
        build.vm.network "forwarded_port",
          guest: 8080,
          host: 8080,
          host_ip: '127.0.0.1'
        build.vm.network "forwarded_port",
          guest: 8443,
          host: 8443,
          host_ip: '127.0.0.1'

        # Expose ports used by development webapps and api, e.g.,
        # `flight-desktop-webapp`, and `flight-desktop-restapi.
        if ENV['EXPOSE_DEV_PORTS'] == 'true'
          [ (3000..3009), (6305..6312) ].each do |range|
            range.each do |port|
              build.vm.network "forwarded_port",
                guest: port,
                host: "#{ENV['DEV_PORT_PREFIX']}#{port}",
                host_ip: '127.0.0.1'
            end
          end
        end

        if File.directory?(CODE_PATH)
          build.vm.synced_folder CODE_PATH, "/code"
        end

        build.vm.provision "ansible_local" do |ansible|
          ansible.playbook = "ansible/playbook-#{FLAVOUR}.yml"
          ansible.verbose = true
          ansible.limit = ENV.fetch('ANSIBLE_LIMIT', 'all')
          ansible.groups = ansible_groups
          ansible.host_vars = ansible_host_vars

          # The current version of `ansible_local` has a bug preventing
          # `ansible.extra_vars = {...}` from working correctly.  We
          # workaround this by using `ansible.raw_arguments`.
          ansible.raw_arguments = [
            "--extra-vars", ansible_extra_vars.to_json.inspect,
          ]
        end
      end
    end
  end
end
