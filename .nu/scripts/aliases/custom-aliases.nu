export def l [] {
	ls | sort-by type name -ni | grid -c
}

export def reload [] {
	let pid = $nu.pid
	let payload = $"print $'new \($nu.pid)'; run-external echo test:($pid)" # "taskkill /F /PID ($pid)"
	
	print $"current: ($nu.pid)"
	run-external start cmd /C nu $nu_args "-e" $payload
}
export alias please = sudo -d nu -c (history | last 1 | get command | into string)
export alias pls = please