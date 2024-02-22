

# Other
export def "regutil remove" [
	key_section: string
] {
	str replace --regex --multiline ('(?s)\[' + (
		$key_section
		| str replace --all '\' '\\'
		| str replace --all '.' '\.'
		| str replace --all '$' '\$'
	) + '\].*?(?:\r\n){2}') ''
}

export def cmd-raw [
	--sudo
] {
	each {|c|
		do {
			if $sudo {
				^cmd /c sudo $c
			} else {
				^cmd /c $c
			}
		} | complete
	}
}

export def is-text-file [
	path: string
] {
	try {
		open $path --raw | decode utf-8 | null;
		return true
	} catch {
		return false
	}
}



# Script running
export def runscript [
	file: string
] {
	print $"(ansi blue)Running script '(ansi white)($file)(ansi blue)'(ansi reset)\n(delimiter)\n"
	let start_time = (date now)
	
	nu $file
	
	print $"\n(delimiter)\n(ansi green)Script took (ansi yellow)((date now) - $start_time)(ansi reset)"
	print $"(ansi green)Press any key to close...(ansi reset)"
	input listen --types [key] | null
}


# Hook and reload
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
	print $"(ansi red)Reloading...(ansi reset)"
	if $hard {
		wezterm cli split-pane | null
		hook pre_prompt $"sleep 500ms; wezterm cli kill-pane --pane-id ($env.WEZTERM_PANE)"
	} else {
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