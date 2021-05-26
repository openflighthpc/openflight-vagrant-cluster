Vagrant.configure("2") do |config|
  code_path = ENV['FLIGHT_CODE'] || "#{ENV['HOME']}/code"

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
        type: 'node',
      }
    end,
    {
      vmname: 'chead1',
      hostname: 'chead1.flight.lvh.me',
      private_ip: '172.17.177.11',
      type: 'gateway',
    }
  ]

  # If this key does not exist, we'll use Vagrant's inserted custom keys.  The
  # effect of that will be that ansible won't work on the compute nodes once
  # the NFS step has been ran.  There is not any real issue with that, as that
  # is the last ansible step that runs on the compute nodes, but its nicer if
  # it does work.
  ssh_prv_key_path = [File.expand_path('~/.ssh/openflight-vagrant-cluster.key')]
    .compact.select {|k| File.file?(k)}.first

  if ssh_prv_key_path
    # The openflight-vagrant-cluster key exists.  We insert it in much the
    # same way that Vagrant would insert a per-node key if
    # `config.ssh.insert_key = true`.  However, it is the same key for all
    # nodes and doesn't change once NFS is mounted on the compute nodes.
    config.ssh.forward_agent    = false
    config.ssh.insert_key       = false
    config.ssh.private_key_path =  ["~/.vagrant.d/insecure_private_key", ssh_prv_key_path]
      .compact.select {|k| File.file?(File.expand_path(k))}

    config.vm.provision "shell", privileged: false do |s|
      ssh_pub_key_path = "#{ssh_prv_key_path}.pub"
      if !ssh_prv_key_path.nil? && !File.file?(ssh_prv_key_path) || !File.file?(ssh_pub_key_path)
        s.inline = <<-SHELL
          echo "No SSH key found. This will never be ran but needs to exist. :shrug:"
          exit 0
        SHELL
      else
        ssh_prv_key = File.read(ssh_prv_key_path)
        ssh_pub_key = File.readlines(ssh_pub_key_path).first.strip
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
  end

  ansible_groups = {
    "gateway" => nodes.select{|n| n[:type] == 'gateway'}.map{|n| n[:vmname]},
    "nodes"   => nodes.select{|n| n[:type] == 'node'}.map{|n| n[:vmname]},
  }

  ansible_host_vars = nodes.select{|n| n[:type] == 'node'}.map do |node|
    # This needs to be the path as resolved on `chead1`.
    ansible_ssh_private_key_file = ssh_prv_key_path.nil? ?
      "/vagrant/.vagrant/machines/#{node[:vmname]}/virtualbox/private_key" :
      "/home/vagrant/.ssh/id_rsa"

    [
      node[:vmname], { 
        "ansible_host" => node[:private_ip],
        "ansible_ssh_private_key_file" => ansible_ssh_private_key_file,
        "ansible_ssh_extra_args" => "'-o StrictHostKeyChecking=no'",
      }
    ]
  end.to_h

  ansible_extra_vars = {
    'cluster_name' => ENV.fetch('CLUSTER_NAME', 'dev'),
    'compute_nodes' => "cnode[01-0#{NUM_NODES}]",
    'flightenv_dev' => true,
    'flightenv_bootstrap' => true,
    'munge_key' => SecureRandom.hex(48),
    'etc_host_entries' => nodes.map do |n|
      {
        name: n[:vmname],
        hostname: n[:hostname],
        ip: n[:private_ip],
      }
    end
  }

  nodes.each do |node|
    is_gateway = node[:type] == 'gateway'

    config.vm.define node[:vmname], primary: is_gateway do |build|
      build.vm.box = "bento/centos-7"
      build.vm.hostname = node[:hostname]

      build.vm.network "private_network", ip: node[:private_ip]

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

        if File.directory?(code_path)
          build.vm.synced_folder code_path, "/code"
        end

        build.vm.provision "ansible_local" do |ansible|
          ansible.playbook = "ansible/playbook.yml"
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
