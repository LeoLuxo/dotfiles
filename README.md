# dotfiles

## Downloading
```nu
```



## Init from scratch
```bash
export $DOTFILES_REPO="$HOME/.dotfiles"
git init --bare $DOTFILES_REPO
alias dotfiles="GIT_DIR=$DOTFILES_REPO GIT_WORK_TREE=$HOME"
dotfiles git config --local status.showUntrackedFiles no
```


## Fresh install steps

- Setup ssh keys:
```bash
ssh-keygen -t rsa-sha2-512 -b 2048 -N "" -C "" -f ~/.ssh/id_rsa_github
```
