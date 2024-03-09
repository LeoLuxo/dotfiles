
# General
export def l [] {
	ls | sort-by type name --natural --ignore-case | grid --color
}

# ==(* OS=windows *)==
export alias please = ^gsudo --direct nu --commands (history | last 1 | get command | into string)
export alias pls = please

export alias su = ^gsudo nu $env.NU_ARGS
export def "sudo" [input?:string] {
	let mut $input = $input
	
	if $input == null {
		$input = (input)
	}
	
	^gsudo --direct nu $env.NU_ARGS --commands $input
}

export alias explorer = ^explorer .

export alias cat = open
# ==(* OS END *)==



# Dotfiles
export alias dfa = dotfiles apply
export alias dfu = dotfiles update

export def "dotfiles yeet" [
	--untracked (-u)
	--export (-e)
] {
	cd $env.DOTFILES
	if $export {
		dotfiles export-config *
	}
	git yeet --untracked=$untracked
}
export def "dotfiles code" [] {code ~/.dotfiles --profile "nu"}




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
	git add -u
	let changes = (git diff --staged --name-only | lines | path basename)
	git commit -am $"Yeet ($changes | str join ', ')"
	git push
}




