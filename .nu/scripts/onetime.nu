

export def add-extension [
	extension: string
	ftype_name: string
	command: string
	icon_path: string
] {
	print $"(ansi blue)Adding extension (ansi yellow)($extension)(ansi blue).(ansi reset)"
	
	[
		$'^reg add HKEY_CLASSES_ROOT\($extension)\ /t REG_SZ /d ($ftype_name) /f'
		$'^reg add HKEY_CLASSES_ROOT\($ftype_name)\DefaultIcon\ /t REG_SZ /d ($icon_path | path expand) /f'
		$'^ftype ($ftype_name)=($command)'
		$'^assoc ($extension)=($ftype_name)'
	]
	| do {sudo nu --commands ...($in)}
}


export def extensions [] {
	# gsudo cache on
	
	add-extension '.nu' 'nufile' 'C:\Scoop\apps\wezterm\current\wezterm-gui.exe start -- nu --env-config ~\.nu\env.nu --config ~\.nu\config.nu --commands "runscript %1"' '~/.nu/assets/terminal.ico'
	
	gsudo cache off
}