
export-env {
	$env.DOTFILES = (["~", ".dotfiles"] | path join)
	$env.DOTFILES_TEMP = ([$env.TEMP, ".dotfiles"] | path join)
}

def confirmation-prompt [
	prompt
] {
	(input $"($prompt) y/n: " -n 1) == 'y'
}

def folder-empty [
	path
] {
	cd $path
	glob * | is-empty
}

def repo-exists [
	path
] {
	cd $path
	git rev-parse --is-inside-work-tree
	| into bool
}

def repo-has-changes [
	path
] {
	cd $path
	git update-index --refresh
	| git diff-index --quiet HEAD --
	| complete
	| get exit_code
	| into bool
}

# Download the dotfiles from the repo into $env.DOTFILES.
# Will prompt if the repo already exists and has uncommitted changes
export def download [
	--force (-f) # Force deletion of $env.DOTFILES and override potential prompt
] {
	let folder_exist = ($env.DOTFILES | path exists)
	
	# If user chose to force override, or if the folder doesn't exist anyway, continue
	if $folder_exist {
		if (not $force) {
			let repo_dialog = {confirmation-prompt $"(ansi red)($env.DOTFILES) repo has uncommitted changes, are you sure you want to overwrite?(ansi reset)"}
			let repo_override_cancel = (repo-exists $env.DOTFILES) and (repo-has-changes $env.DOTFILES) and (not (do $repo_dialog))
			
			if $repo_override_cancel {
				print $"(ansi yellow)Aborted.(ansi reset)"
				return
			}
			
			let folder_dialog = {confirmation-prompt $"(ansi red)($env.DOTFILES) folder is non-empty, are you sure you want to overwrite?(ansi reset)"}
			let folder_override_cancel = not ((folder-empty $env.DOTFILES) or (do $folder_dialog))
			
			if $folder_override_cancel {
				print $"(ansi yellow)Aborted.(ansi reset)"
				return
			}
		}
		
		rm -r $env.DOTFILES
	}
	
	git clone -b nu --single-branch https://github.com/LeoLuxo/dotfiles.git $env.DOTFILES
}
