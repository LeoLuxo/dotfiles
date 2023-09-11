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
```

### Install in Git Bash
```bash
```