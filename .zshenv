TRAPUSR1() {
	if [[ -o INTERACTIVE ]]; then
		printf "\033[1;31mShell forcefully restarted by .dotfiles downloader." 1>&2
		exec "${SHELL}"
	fi
}
