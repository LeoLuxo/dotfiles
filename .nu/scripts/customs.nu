
# General
export def l [] {
	ls | sort-by type name --natural --ignore-case | grid --color
}

export alias please = sudo --direct nu --command (history | last 1 | get command | into string)
export alias pls = please

export alias explorer = ^explorer .



# Dotfiles
export def "dotfiles update" [] {dotfiles download; dotfiles apply; reload --hard}
export def "dotfiles yeet" [] {cd $env.DOTFILES; git yeet}
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



# Special
export def --env hook [
	hook: string
	command: string
	--debug
] {
	let id = random uuid
	let payload = [
		$"($command) #($id)",
		$"$env.config.hooks = \($env.config.hooks | update ($hook) {filter {|x| $\"\($x)\" !~ '#($id)'}})"
	]
	
	$env.config.hooks = ($env.config.hooks | update $hook {
		append $payload
	})
	
	if $debug {
		print ($env.config.hooks | get $hook)
	}
}

export def --env startup-hook [] {
	hook pre_prompt $"sleep 10ms; print-startup"
}

export def --env reload [
	--hard (-h)
] {
	if $hard {
		wezterm cli split-pane | null
		sleep 50ms
		wezterm cli kill-pane --pane-id $env.WEZTERM_PANE
	} else {
		print $"(ansi red)Reloading...(ansi reset)"
		$env.last-reload = (date now)
		
		let payload = [
			"source ($nu.env-path)",
			"source ($nu.config-path)",
			"print-reload"
		] | str join "; "
		
		hook pre_prompt $"($payload)"
	}
}



# Startup and reload sequence libs
use std [ellie, repeat]

alias dope-gradient = ansi gradient --fgstart '0x40c9ff' --fgend '0xe81cff'

def delimiter [] {
	"━" | repeat (term size).columns | str join | dope-gradient
}

def banner [] {
	ellie | ansi strip | dope-gradient
}
	
def startup-time [] {
	$"(ansi yellow)Startup Time: (ansi blue)($nu.startup-time)(ansi reset)"
}

def reload-time [] {
	mut time = $"(ansi red)n/a"
	if "last-reload" in $env {
		$time = (date now) - $env.last-reload
	}
	$"(ansi yellow)Reload Time: (ansi blue)($time)(ansi reset)"
}

export def print-startup [] {
	print $"\n(banner)\n\n(startup-time)\n\n(delimiter)\n"
}

export def print-reload [] {
	print $"\n(ansi green)Reload successful!\n(reload-time)\n"
}