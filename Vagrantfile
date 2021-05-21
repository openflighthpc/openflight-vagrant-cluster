Vagrant.configure("2") do |config|
  code_path = ENV['FLIGHT_CODE'] || "#{ENV['HOME']}/code"

  # Number of compute nodes.  Must be between 0 and 9.
  #
  # If NUM_NODES changes update:
  #
  #  * ansible/extra_vars.yml
  #  * ansible/inventory
  NUM_NODES = 1
  (1..NUM_NODES).each do |idx|
    config.vm.define "cnode0#{idx}", primary: true do |build|
      build.vm.box = "bento/centos-7"
      build.vm.hostname = "cnode0#{idx}.flight.lvh.me"
      build.vm.network "private_network", ip: "172.17.177.2#{idx}"
    end
  end

  config.vm.define "chead1", primary: true do |build|
    build.vm.box = "bento/centos-7"
    build.vm.hostname = "chead1.flight.lvh.me"

    build.vm.network "private_network", ip: "172.17.177.11"
    build.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: '127.0.0.1'
    build.vm.network "forwarded_port", guest: 443, host: 8443, host_ip: '127.0.0.1'

    # build.vm.provision "shell", path: "provision/chead.sh"
    if File.directory?(code_path)
      build.vm.synced_folder code_path, "/code"
    end

    build.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
      ansible.inventory_path = "ansible/inventory"
      ansible.verbose = true
      ansible.limit = 'all'

      ansible.groups = {
        "gateway" => ["chead1"],
        "nodes" => (1..NUM_NODES).map { |idx| "cnode0#{idx}" },
      }

      # XXX FSR passing extra vars as a hash doesn't work.  It's supposed to.
      # If NUM_NODES changes we need to update the extra_vars.yml too.
      ansible.extra_vars = "ansible/extra_vars.yml"
    end
  end
end
