export def l [] {
	ls | sort-by type name -ni | grid -c
}