# Описываем Виртуальные машины
MACHINES = {
  # Указываем имя ВМ "RPM"
  :"RPM" => {
              #Какой vm box будем использовать
              :box_name => "ubuntu/jammy64",
              :ip_addr => '192.168.56.10',
              #Указываем количество ядер ВМ
              :cpus => 4,
              #Указываем количество ОЗУ в мегабайтах
              :memory => 4096,
            }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    # Применяем конфигурацию ВМ
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.provision "shell", path: "script.sh"
      box.vm.box_version = boxconfig[:box_version]
      box.vm.host_name = boxname.to_s
      box.vm.network "private_network", ip: boxconfig[:ip_addr]
      box.vm.provider "virtualbox" do |v|
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
      end
    end
  end
end

