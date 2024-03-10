

# Other
export def "regutil remove" [
	key_section: string
] {
	str replace --regex --multiline ('(?s)\[' + (
		$key_section
		| str replace --all '\' '\\'
		| str replace --all '.' '\.'
		| str replace --all '$' '\$'
	) + '\].*?(?:\r\n){2}\[') '['
}

export def "regutil force-delete" [
	key: string
] {
	let tmp = mktemp --tmpdir XXXXXXXXXX.hiv
	
	^reg add 'HKCU\emptyKey' /f
	^reg save 'HKCU\emptyKey' $tmp /y
	^reg delete 'HKCU\emptyKey' /f
	
	^reg restore $key $tmp
	
	rm -f $tmp
}

export def escape [] {
	str replace --all `\` `\\`
	| str replace --all `"` `\"`
	| str replace --all `'` `\'`
}






# Script running
export def runscript [
	using: string
	...file: string
] {
	let runscript_table = {
		nu:     {name:'nu'     icon:󰟆  run:{ |p| nu $env.NU_ARGS $p}}
		cmd:    {name:'CMD'    icon:  run:{ |p| ^cmd /c $p}}
		python: {name:'Python' icon:  run:{ |p| ^python3 $'($p)'}}
	}

	let runner = $runscript_table | get $using
	let file = $file | str join ' '
	
	loop {
		print $"(ansi blue)Running (ansi magenta)($runner.icon) (ansi yellow)($runner.name) (ansi blue)script '(ansi white)($file)(ansi blue)'(ansi reset)\n(delimiter)\n"
		let start_time = (date now)
		
		try {
			cd ($file | path dirname)
			do $runner.run $file
			
			print $"\n(delimiter)\n(ansi green)Script took (ansi yellow)((date now) - $start_time)(ansi reset)"
			print $"(ansi green)Press (ansi yellow)[ENTER](ansi green) to close...(ansi reset)"
		} catch {
			print $"\n(delimiter)\n(ansi red)Script took (ansi yellow)((date now) - $start_time)(ansi red) and closed abruptly(ansi reset)"
			print $"(ansi red)Press (ansi yellow)[R](ansi red) to retry or (ansi yellow)[ENTER](ansi red) to close...(ansi reset)"
		}
		
		loop {
			let key = input listen --types [key]
			
			if $key.code == 'r' {
				clear
				break
			} else if $key.code == 'enter' {
				return
			}
		}
	}
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
		$"$env.config.hooks = \($env.config.hooks | update ($hook) {filter { |x| $\"\($x)\" !~ '#($id)'}})"
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