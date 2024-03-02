
# General
export def l [] {
	ls | sort-by type name --natural --ignore-case | grid --color
}

export alias please = sudo --direct nu --commands ...(history | last 1 | get command | into string)
export alias pls = please
export def "sudo nu" [] {^gsudo nu $env.NU_ARGS}

export alias explorer = ^explorer .

# ==(* OS=windows *)==
export alias cat = open
# ==(* OS END *)==



# Dotfiles
export alias dfa = dotfiles apply
export alias dfu = dotfiles update

export def "dotfiles yeet" [--untracked (-u)] {cd $env.DOTFILES; git yeet --untracked=$untracked}




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



# Start11
export def "start11 export" [] {
	let path = "~/.dotfiles/_reg/start11.reg" | path expand
	
	^reg export HKEY_CURRENT_USER\SOFTWARE\Stardock\Start8 $path /y
	
	open $path --raw
	| decode utf-8
	| regutil remove 'HKEY_CURRENT_USER\SOFTWARE\Stardock\Start8\Start8.ini\Start8\Taskbar'
	| encode utf-8
	| save $path --force --raw
}

