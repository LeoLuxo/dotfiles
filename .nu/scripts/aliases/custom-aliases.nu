export def l [] {
	ls | sort-by type name -ni | grid -c
}

export alias please = sudo -d nu -c (history | last 1 | get command | into string)
export alias pls = please

export alias dope-gradient = ansi gradient --fgstart '0x40c9ff' --fgend '0xe81cff'

# Print custom banner
use std ellie

# Setup one-time hook
export def --env hook [
	hook: string
	command: string
	--debug
] {
	$env.config.hooks = ($env.config.hooks | update $hook {
		append [
			$command,
			$"$env.config.hooks = \($env.config.hooks | update ($hook) {drop 2})"
		]
	})
	if $debug {
		print ($env.config.hooks | get $hook)
	}
}

# Startup sequence
export def --env startup [] {
	clear
	print $"\n(ellie | ansi strip | dope-gradient)\n"
	
	if "reload-start" in $env {
		let time = (date now) - $env.reload-start
		print $"(ansi yellow)Reload Time: (ansi blue)($time)(ansi reset)\n"
		hide-env -i reload-start
	} else {
		print $"(ansi yellow)Startup Time: (ansi blue)($nu.startup-time)(ansi reset)\n"		
	}
}

export def --env reload [] {
	print $"(ansi red)Reloading...(ansi reset)"
	$env.reload-start = (date now)
	
	let payload = [
		"source ($nu.env-path)",
		"source ($nu.config-path)",
	] | str join "\n"
	
	wezterm cli send-text $"($payload)\n"
}