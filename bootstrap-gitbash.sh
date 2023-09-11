echo "Running this script will overwrite ALL dotfiles on this system."
read -p "Make sure you are on *GIT BASH*! Continue (y/n)?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
   cd $HOME

	export $DOTFILES_REPO="$HOME/.dotfiles"
	alias dotfiles="GIT_DIR=$DOTFILES_REPO GIT_WORK_TREE=$HOME"

	git clone -b gitbash --single-branch --bare git@github.com:LeoLuxo/dotfiles.git $DOTFILES_REPO

	dofiles git checkout --force
	
	dofiles git config status.showUntrackedFiles no
else
	[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi


