# https://learn.microsoft.com/en-us/windows/wsl/wsl-config#network-settings

sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 1.1.1.1" > /etc/resolv.conf'
sudo bash -c 'echo "[boot]" >> /etc/wsl.conf' 
sudo bash -c 'echo "systemd = true" >> /etc/wsl.conf'
sudo bash -c 'echo "[network]" >> /etc/wsl.conf'
sudo bash -c 'echo "hostname = lab" > /etc/wsl.conf' 
sudo bash -c 'echo "generateResolvConf = false" >> /etc/wsl.conf'
sudo bash -c 'echo "generateHosts = False" >> /etc/wsl.conf'
sudo chattr +i /etc/resolv.conf
