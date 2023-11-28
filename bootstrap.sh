#!/usr/bin/env bash

RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
NOCOLOR="\033[0m"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
   branch='wsl'
elif [[ "$OSTYPE" == "msys" ]]; then
   branch='gitbash'
else
	printf "${RED}Unknown system, aborting${NOCOLOR}\n"
	exit 1
fi

printf "Platform detected: ${GREEN}$branch${NOCOLOR}\n"
read -p $'${RED}Running this script will overwrite ALL dotfiles on this system!${NOCOLOR} Continue (y/n)?' -n 1 -r
printf "\n"
if [[ $REPLY =~ ^[Yy]$ ]]
then
	printf "${BLUE}Setting environment variables...${NOCOLOR}\n"
	DOTFILES_REPO="$HOME/.dotfiles"
	DOTFILES_TEMP="$TEMP/.dotfiles"
 
	function dotfiles {
		GIT_DIR=$DOTFILES_REPO GIT_WORK_TREE=$HOME $@
	}
	
	printf "${BLUE}Removing previous dotfiles...${NOCOLOR}\n"
	cd $HOME
	rm -rf $DOTFILES_REPO
	
	git config --global url.https://.insteadOf git://
	
	printf "${BLUE}Downloading bare dotfiles repo...${NOCOLOR}\n"
	git clone -b $branch --single-branch --bare https://github.com/LeoLuxo/dotfiles.git $DOTFILES_REPO
	dotfiles git config --local status.showUntrackedFiles no
 
	printf "${BLUE}Downloading temp dotfiles repo...${NOCOLOR}\n"
	git clone -b $branch --single-branch https://github.com/LeoLuxo/dotfiles.git $DOTFILES_TEMP
 	grep -rl "(%USER-$USERNAME%" $DOTFILES_TEMP | xargs -i@ sed -ri -e "s/\(%USER-$USERNAME%\s*?(.*?)\s*?%\)/\1/g" -e "/\(%USER-(.+?)%(.*?)%\)/d" @
  
	printf "${BLUE}Copying dotfiles...${NOCOLOR}\n"
 	rm -rf $DOTFILES_TEMP/.git
  	cp -rf $DOTFILES_TEMP/* $HOME/.
  	rm -rf $DOTFILES_TEMP
 	
	if [[ "$branch" == "wsl" ]]; then
		sudo rm "/etc/wsl.conf"
		sudo ln "$HOME/.wsl.conf" "/etc/wsl.conf"
	fi

	printf "${GREEN}Done!${NOCOLOR}\n"
 
  	exec zsh
else
	[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi
