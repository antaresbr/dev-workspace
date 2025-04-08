#!/bin/bash

#-- sudoer
[ ! -f /etc/sudoers.d/${USER} ] && cat files/sudoer | sed "s/{{USER}}/${USER}/g" | sudo tee /etc/sudoers.d/${USER} > /dev/null

#-- .bash_aliases
[ ! -f ~/.bash_aliases ] && touch ~/.bash_aliases

cat ~/.bash_aliases | grep "^alias sail=" > /dev/null
[ $? -ne 0 ] && echo "alias sail='[ -f sail ] && bash sail || bash sail/sail'" >> ~/.bash_aliases

cat ~/.bash_aliases | grep "^alias sshx=" > /dev/null
[ $? -ne 0 ] && echo "alias sshx='ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR'" >> ~/.bash_aliases

cat ~/.bash_aliases | grep "^alias scpx=" > /dev/null
[ $? -ne 0 ] && echo "alias scpx='scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR'" >> ~/.bash_aliases

cat ~/.bash_aliases | grep "^alias docker-pss=" > /dev/null
[ $? -ne 0 ] && echo "alias docker-pss=alias docker-pss='docker ps --format \"table {{.ID}}\\t{{.Image}}\\t{{.Names}}\\t{{.State}}\\t{{.Status}}\\t{{.Ports}}\"'" >> ~/.bash_aliases

#-- .vimrc
[ ! -f ~/.vimrc ] && cp -p files/.vimrc ~/

#-- ~/bin
[ ! -d ~/bin ] && mkdir ~/bin

#-- update system packages
sudo apt update
sudo apt -y upgrade

#-- required pakages
sudo apt install -y dos2unix dnsutils git iproute2 jq net-tools vim

#-- .gitconfig
echo ""
echo "---[ .gitconfig ]---"

gitKey="credential.helper"
gitValue="$(git config --global --get ${gitKey})"
[ -z "${gitValue}" ] && git config --global "${gitKey}" "cache --timeout=3600"

gitKey="user.name"
gitValue="$(git config --global --get ${gitKey})"
if [ -z "${gitValue}" ]
then
  echo ""
  read -p "Git [${gitKey}] : " gitValue
  [ -n "${gitValue}" ] && git config --global "${gitKey}" "${gitValue}"
fi

gitKey="user.email"
gitValue="$(git config --global --get ${gitKey})"
if [ -z "${gitValue}" ]
then
  echo ""
  read -p "Git [${gitKey}] : " gitValue
  [ -n "${gitValue}" ] && git config --global "${gitKey}" "${gitValue}"
fi

echo ""
