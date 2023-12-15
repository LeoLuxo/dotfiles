export def l [] {
	ls | sort-by type name -ni | grid -c
}

export alias please = sudo -d nu -c (history | last 1 | get command | into string)
export alias pls = please


# Setup one-time hook
export def --env hook [
	hook: string
	command: string
	--persistent (-p)
	--debug
] {
	if $persistent {
		
	} else {
		let id = random uuid
		let payload = [
			$"($command) #($id)",
			$"$env.config.hooks = \($env.config.hooks | update ($hook) {filter {|x| $\"\($x)\" !~ '#($id)'}})"
		]
		
		$env.config.hooks = ($env.config.hooks | update $hook {
			append $payload
		})
	}
	
	if $debug {
		print ($env.config.hooks | get $hook)
	}
}

# Startup banner
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
9999999999999999999999999099999999999999999999}

export def print-reload [] {
	print $"\n(ansi green)Reload successful!\n(reload-time)\n"
}

export def --env startup-hook [] {
	hook pre_prompt $"print-startup"
}

export def --env reload [
	--hard (-h)
] {
	if $hard {
		wezterm cli split-pane | null
		wezterm cli kill-pane --pane-id $env.WEZTERM_PANE
	} else {
		print $"(ansi red)Reloading...(ansi reset)"
		$env.last-reload = (date now)
		
		let payload = [
			"source ($nu.env-path)",
			"source ($nu.config-path)",
			"print-reload"
		] | str join "; "
		
		# wezterm cli send-text $"hook pre_prompt \"($payload)\"\n"
		hook pre_prompt $"($payload)"
	}
}