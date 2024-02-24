

export def add-extension [
	extension: string
	ftype_name: string
	--icon: string
	--open_command: string
	--edit_command: string
] {
	print $"(ansi blue)Adding extension (ansi yellow)($extension)(ansi blue). (ansi reset)" --no-newline
	
	[
		$'^assoc ($extension)=($ftype_name)'
		$'^reg add HKCR\($extension)\ /t REG_SZ /d ($ftype_name) /f'
		# $'^reg add HKEY_CLASSES_ROOT\($ftype_name)\DefaultIcon\ /t REG_SZ /d ($icon_path | path expand) /f'
		# $'^ftype ($ftype_name)=($command)'
	]
	| append (if $icon != null {$'^reg add HKCR\($ftype_name)\DefaultIcon\ /t REG_EXPAND_SZ /d "($icon | path expand | escape)" /f'})
	| append (if $open_command != null {$'^reg add HKCR\($ftype_name)\Shell\Open\Command\ /t REG_EXPAND_SZ /d "($open_command | escape)" /f'})
	| append (if $edit_command != null {$'^reg add HKCR\($ftype_name)\Shell\Edit\Command\ /t REG_EXPAND_SZ /d "($edit_command | escape)" /f'})
	| each {|c| print $c; do {sudo $c} | complete | print}
	# | do {
		# let res = $in
	# 	if ($res | all {|r| $r.exit_code == 0}) {
	# 		print $"(ansi green)Done.(ansi reset)"
	# 	} else {
	# 		print $"(ansi red)An eror occurred:(ansi reset)"
	# 		$res | each {get stderr | print --no-newline}
	# 	}
	# } | null
}


export def extensions [] {
	(add-extension '.nu' 'nufile'
	--open_command 'C:\Scoop\apps\wezterm\current\wezterm-gui.exe start -- nu --env-config ~\.nu\env.nu --config ~\.nu\config.nu --commands "runscript %1"'
	--edit_command 'C:\Scoop\apps\vscode\current\Code.exe --profile nu "%1"'
	--icon '~/.nu/assets/terminal.ico')
}