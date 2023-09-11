# dotfiles

## Init from scratch

```bash
export $DOTFILES_REPO="$HOME/.dotfiles"
git init --bare $DOTFILES_REPO
alias dotfiles="GIT_DIR=$DOTFILES_REPO GIT_WORK_TREE=$HOME"
dotfiles git config --local status.showUntrackedFiles no
```

## Open git repo in vscode

```bash
dotfiles code ~
```

## Installation
### Install in WSL
```bash
bash <(curl -sL https://gist.githubusercontent.com/LeoLuxo/cbf09033fcef7f5b8db259549779be61/raw/bootstrap-wsl.sh)
```

### Install in Git Bash
```bash
bash <(curl -sL https://gist.githubusercontent.com/LeoLuxo/cbf09033fcef7f5b8db259549779be61/raw/bootstrap-gitbash.sh)
```