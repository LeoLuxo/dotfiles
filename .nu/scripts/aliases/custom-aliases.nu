export def l [] {
	ls | sort-by type name -ni | grid -c
}

export def reload [] {
	let pid = $nu.pid
	
	print $"current: ($nu.pid)" # kill --force ($pid)
	cmd /c start "" /b /wait nu $nu_args -e $"do {print \($nu.pid); print ($pid)}"
}
export alias please = sudo -d nu -c (history | last 1 | get command | into string)
export alias pls = please