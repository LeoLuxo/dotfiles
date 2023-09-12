# dotfiles

## Installation
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LeoLuxo/dotfiles/main/bootstrap.sh)
```


## Init from scratch
```bash
export $DOTFILES_REPO="$HOME/.dotfiles"
git init --bare $DOTFILES_REPO
alias dotfiles="GIT_DIR=$DOTFILES_REPO GIT_WORK_TREE=$HOME"
dotfiles git config --local status.showUntrackedFiles no
```


## Fresh install steps
- Install oh-my-zsh:
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

- Run zsh:
```bash
zsh
```

- Install Powerlevel10k:
```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

- Install dofiles:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LeoLuxo/dotfiles/main/bootstrap.sh)
```