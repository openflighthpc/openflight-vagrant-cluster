Vagrant.configure("2") do |config|
  code_path = ENV['FLIGHT_CODE'] || "#{ENV['HOME']}/code"

  # Number of compute nodes.  Must be between 0 and 9.
  # If NUM_NODES changes update ansible/extra_vars.yml.
  NUM_NODES = 2
  # (1..NUM_NODES).each do |idx|
  #   config.vm.define "cnode0#{idx}", primary: true do |build|
  #     build.vm.box = "bento/centos-7"
  #     build.vm.hostname = "cnode0#{idx}"

  #     # build.vm.network "private_network", ip: "10.0.0.#{idx + 1}"
  #     build.vm.network "private_network", type: "dhcp"

  #     # build.vm.provision "shell", path: "provision/chead.sh"
  #     # if File.directory?(code_path)
  #     #   build.vm.synced_folder code_path, "/code"
  #     # end
  #   end
  # end

  config.vm.define "chead1", primary: true do |build|
    build.vm.box = "bento/centos-7"
    build.vm.hostname = "chead1"

    # build.vm.network "private_network", ip: "10.0.0.100"
    build.vm.network "private_network", type: "dhcp"
    build.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: '127.0.0.1'
    build.vm.network "forwarded_port", guest: 443, host: 8443, host_ip: '127.0.0.1'

    # build.vm.provision "shell", path: "provision/chead.sh"
    if File.directory?(code_path)
      build.vm.synced_folder code_path, "/code"
    end

    build.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
      ansible.verbose = true

      ansible.groups = {
        "gateway" => ["chead1"],
        "nodes" => (1..NUM_NODES).map { |idx| "cnode0#{idx}" },
      }

      # XXX FSR passing extra vars as a hash doesn't work.  It's supposed to.
      # If NUM_NODES changes we need to update the extra_vars.yml too.
      ansible.extra_vars = "ansible/extra_vars.yml"
      # ansible.extra_vars = {
      #   cluster_name: "ben1",
      #   compute_nodes: "cnode[01-0#{NUM_NODES}]",
      #   flightenv_dev: true,
      #   flightenv_bootstrap: true,
      #   # XXX Don't hardcode this.
      #   munge_key: "1c616544e99c418a281bee2e853d726172c255d3d51ed4302aefcf956d63f6dca5a463059212faee46aff7371237281f0cc4b0b8055f6fecbf34031967a30e3d",
      # }
      # }.map { |k, v| [k, '=', v].join }
      #  .join(' ')
    end
  end

end
