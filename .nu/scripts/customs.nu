
# General
export def l [] {
	ls | sort-by type name --natural --ignore-case | grid --color
}

export alias please = sudo --direct nu --commands ...(history | last 1 | get command | into string)
export alias pls = please

export alias explorer = ^explorer .

# ==(* OS=windows *)==
export alias cat = open
# ==(* OS END *)==



# Dotfiles
export def "dotfiles yeet" [--untracked (-u)] {cd $env.DOTFILES; git yeet --untracked=$untracked}
export alias dfu = dotfiles update



# Git
export def "git graph" [] {
	let fmt = "format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)'"
	git log --graph --abbrev-commit --decorate --all --format=($fmt)
}

export def "git yeet" [
	--untracked (-u)
] {
	if $untracked {
		git add .
	}
	let changes = (git diff --name-only | split row --regex '[\r\n]{1,2}' | where not ($it | is-empty) | path basename)
	git commit -am $"Yeet ($changes | str join ', ')"
	git push
}

