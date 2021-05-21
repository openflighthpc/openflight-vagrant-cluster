Vagrant.configure("2") do |config|
  code_path = ENV['FLIGHT_CODE'] || "#{ENV['HOME']}/code"

  # Number of compute nodes.  Must be between 1 and 9.
  NUM_NODES = 2

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

  ansible_groups = {
    "gateway" => nodes.select{|n| n[:type] == 'gateway'}.map{|n| n[:vmname]},
    "nodes"   => nodes.select{|n| n[:type] == 'node'}.map{|n| n[:vmname]},
  }

  ansible_host_vars = nodes.select{|n| n[:type] == 'node'}.map do |node|
    [
      node[:vmname], { 
        "ansible_host" => node[:private_ip],
        "ansible_ssh_private_key_file" => "/vagrant/.vagrant/machines/#{node[:vmname]}/virtualbox/private_key",
        "ansible_ssh_extra_args" => "'-o StrictHostKeyChecking=no'",
      }
    ]
  end.to_h

  ansible_extra_vars = {
    'cluster_name' => 'ben1',
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
        build.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: '127.0.0.1'
        build.vm.network "forwarded_port", guest: 443, host: 8443, host_ip: '127.0.0.1'

        if File.directory?(code_path)
          build.vm.synced_folder code_path, "/code"
        end

        build.vm.provision "ansible_local" do |ansible|
          ansible.playbook = "ansible/playbook.yml"
          ansible.verbose = true
          ansible.limit = 'all'
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
