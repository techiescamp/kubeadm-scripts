Vagrant.configure("2") do |config|
  config.vm.provision "shell", inline: <<-SHELL
      apt-get update -y
      echo "10.0.0.10  control-plane-node" >> /etc/hosts
      echo "10.0.0.11  node01" >> /etc/hosts
      echo "10.0.0.12  node02" >> /etc/hosts
  SHELL
  
  config.vm.define "control-plane" do |control_plane|
    control_plane.vm.box = "bento/ubuntu-22.04"
    control_plane.vm.hostname = "control-plane-node"
    control_plane.vm.network "private_network", ip: "10.0.0.10"
    control_plane.vm.provider "virtualbox" do |vb|
        vb.memory = 4048
        vb.cpus = 2
    end
  end

  (1..2).each do |i|

  config.vm.define "node0#{i}" do |node|
    node.vm.box = "bento/ubuntu-24.04"
    node.vm.hostname = "node0#{i}"
    node.vm.network "private_network", ip: "10.0.0.1#{i}"
    node.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
        vb.cpus = 1
    end
  end
  
  end
end
