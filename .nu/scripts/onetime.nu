

export def "register extension" [
	extension: string
	ftype_name: string
	command: string
	icon_path: string
] {
	[
		$'reg add HKEY_CLASSES_ROOT\($extension)\ /t REG_SZ /d ($ftype_name) /f'
		$'reg add HKLM\SOFTWARE\Classes\($ftype_name)\DefaultIcon\ /t REG_SZ /d ($icon_path | path expand) /f'
		$'ftype ($ftype_name)=($command)'
		$'assoc ($extension)=($ftype_name)'
	]
	| cmd-raw
}