let bootstrap_file = (mktemp -t)
http get --raw "https://raw.githubusercontent.com/LeoLuxo/dotfiles/nu/.nu/scripts/dotfiles.nu" | save $bootstrap_file

nu -c $"use ($bootstrap_file); dotfiles download -f; dotfiles apply"

rm $bootstrap_file

print $"(ansi red)DON'T FORGET TO RELOAD(ansi reset)"