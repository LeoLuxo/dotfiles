#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
   branch='wsl'
elif [[ "$OSTYPE" == "msys" ]]; then
   branch='gitbash'
else
	echo "Unknown system, aborting"
	exit 1
fi

echo "Platform detected: $branch"
read -p "Running this script will overwrite ALL dotfiles on this system! Continue (y/n)?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	DOTFILES_REPO="$HOME/.dotfiles"
	DOTFILES_TEMP="$TEMP/.dotfiles"
 
	function dotfiles {
		GIT_DIR=$DOTFILES_REPO GIT_WORK_TREE=$HOME $@
	}
	
	cd $HOME
	rm -rf $DOTFILES_REPO
	
	git config --global url.https://.insteadOf git://
	
	git clone -b $branch --single-branch --bare https://github.com/LeoLuxo/dotfiles.git $DOTFILES_REPO
	dotfiles git config --local status.showUntrackedFiles no
 
	git clone -b $branch --single-branch https://github.com/LeoLuxo/dotfiles.git $DOTFILES_TEMP
 	grep -rl "(%USER-$USERNAME%" $DOTFILES_TEMP | xargs -i@ sed -ri -e "s/\(%USER-$USERNAME%\s*?(.*?)\s*?%\)/\1/g" -e "/\(%USER-(.+?)%(.*?)%\)/d" @
 	rm -rf $DOTFILES_TEMP/.git
  	cp -rf $DOTFILES_TEMP/* $HOME/.
  	rm -rf $DOTFILES_TEMP
 	
	if [[ "$branch" == "wsl" ]]; then
		sudo rm "/etc/wsl.conf"
		sudo ln "$HOME/.wsl.conf" "/etc/wsl.conf"
	fi
else
	[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi
