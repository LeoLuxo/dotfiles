

def add-extension [
	extension: string
	--icon: string
	--open_command: string
	--edit_command: string
	--reset
] {
	print $"(ansi blue)Adding extension (ansi yellow)($extension)(ansi blue).(ansi reset)" --no-newline
	
	[]
	| append (if $reset {$'regutil force-delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.nu'})
	| append (if $reset {$'reg delete HKEY_CLASSES_ROOT\($extension)\ /va /f'})
	| append (if $reset {$'reg delete HKEY_CLASSES_ROOT\($extension)\ /f'})
	| append (if $icon != null {$'reg add HKEY_CLASSES_ROOT\($extension)\DefaultIcon\ /t REG_EXPAND_SZ /d "($icon | path expand | escape)" /f'})
	| append (if $open_command != null {$'reg add HKEY_CLASSES_ROOT\($extension)\shell\open\command\ /t REG_EXPAND_SZ /d "($open_command | escape)" /f'})
	| append (if $edit_command != null {$'reg add HKEY_CLASSES_ROOT\($extension)\shell\edit\command\ /t REG_EXPAND_SZ /d "($edit_command | escape)" /f'})
	| each { |c| do {sudo nu $env.NU_ARGS --commands $c} | complete | {command: $c, ...$in}}
	| do {
		let res = $in
		if ($res | all { |r| $r.exit_code == 0}) {
			print $"(ansi green) Done.(ansi reset)"
		} else {
			print $"(ansi red) An error occured.(ansi reset)"
			$res | each { |r| 
				if $r.exit_code == 0 {
					print ($r | table)
				} else {
					print $"(ansi red)($r | table | ansi strip)(ansi reset)"
				}
			}
		}
	}
	
	return
}


export def "setup extensions" [] {
	let $open_in_vscode = 'C:\Scoop\apps\vscode\current\Code.exe --profile "nu" "%1" %*'
	let $open_wez_nu = 'C:\Scoop\apps\wezterm\current\wezterm-gui.exe start -- nu --env-config "~\.nu\env.nu" --config "~\.nu\config.nu" --commands '
	
	(add-extension '.nu'
	--open_command ($open_wez_nu + '"runscript nu %1"')
	--edit_command $open_in_vscode
	--icon '~/.nu/assets/terminal.ico'
	--reset)
	
	(add-extension '.bat'
	--open_command ($open_wez_nu + '"runscript cmd %1"')
	--edit_command $open_in_vscode
	--icon '~/.nu/assets/terminal.ico')
	
	(add-extension '.py'
	--open_command ($open_wez_nu + '"runscript python %1"')
	--edit_command $open_in_vscode
	--icon '~/.nu/assets/terminal_python.ico'
	--reset)
	
	(add-extension '.nss'
	--open_command $open_in_vscode
	--edit_command $open_in_vscode
	--icon '~/.nu/assets/nss.ico'
	--reset)
	
	return
}






export def "setup keyboard" [] {
	
}