#!/bin/bash

#-- docker
sudo apt --yes install ca-certificates curl gnupg lsb-release

docker_gpg_file="/etc/apt/keyrings/docker.gpg"
[ ! -d "$(dirname "${docker_gpg_file}")" ] && sudo mkdir "$(dirname "${docker_gpg_file}")"
[ -f "${docker_gpg_file}" ] && docker_gpg_content="$(cat "${docker_gpg_file}")"
if [ ! -f "${docker_gpg_file}" ] || [ -z "${docker_gpg_content}" ]
then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o "${docker_gpg_file}"
fi
echo "deb [arch=$(dpkg --print-architecture) signed-by=${docker_gpg_file}] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt --yes install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker "${USER}"

systemctl --no-pager status docker || sudo systemctl --no-pager start docker
[ $? -ne 0 ] && echo "ERRO: Falha ao iniciar serviço docker" && exit 1

[ ! -f ~/.profile ] && touch ~/.profile
if ! cat ~/.profile | grep ' workspace.dockerd ' &> /dev/null
then
  echo -n "
#--[ workspace.dockerd ]--
if ! ps aux | grep dockerd | grep -v grep &> /dev/null
then
  sudo /etc/init.d/docker start
fi
" >> ~/.profile
fi
