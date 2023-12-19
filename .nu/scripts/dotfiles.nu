
export-env {
	$env.DOTFILES = ([$env.HOME, ".dotfiles"] | path join)
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



export def get-os [] {
	match $env.OS {
		"Windows_NT" => {platform:"local" name:"Windows"},
		_ if "OSTYPE" in $env and $env.OSTYPE == "linux-gnu" => {
			if "WSL_DISTRO_NAME" in $env {
				{platform:"WSL" name:$env.WSL_DISTRO_NAME}
			} else {
				{platform:"unknown" name:"unknown"}
			}},
		_ => {platform:"unknown" name:"unknown"},
	}
}

# Will patch a given file by preprocessing user and OS -related lines, as well as including extra files
# 
# Format:
# File inclusion (line wide):
# ==(* INCLUDE file.ext *)==
# 
# OS delimiter, OS can be any combination of platform & name:
# (* OS=wsl ubuntu | lorem ipsum *)
# Line wide:
# ==(* OS=windows *)==
# ==(* END *)==
#
# USER delimiter:
# (* USER=neon | lorem ipsum *)
# Line wide:
# ==(* USER=pollux *)==
# ==(* END *)==
export def patch [
	file? # File to patch
	--info (-i) # Print current info instead of patching
] {
	let os = get-os | str downcase platform name
	let user = $env.USERNAME | str downcase
	
	if $info {
		print $"OS=($os.platform) ($os.name)"
		print $"USER=($user)"
		return
	}
	
	if $file == null or ($file | path type) != "file" {
		error make {msg: "Given path must be a file", label: {text: "bad file", span: (metadata $file).span}}
	}
	
	let linewide_left = '^.*?==*=\(\*\s*'
	let linewide_right = '\s*\*\)==*=.*?$'
	
	let os_keep = ('OS\s*=\s*(?:' + $os.platform + '\s+' + $os.name + '|' + $os.platform + '|' + $os.name + ')')
	let os_line_any = $linewide_left + 'OS (?:KEEP|REMOVE)' + $linewide_right
	let os_line_keep = $linewide_left + 'OS KEEP' + $linewide_right
	let os_line_remove = $linewide_left + 'OS REMOVE' + $linewide_right
	
	let user_line_any = $linewide_left + 'USER (?:KEEP|REMOVE)' + $linewide_right
	
	let end_line = $linewide_left + 'END' + $linewide_right
	
	let multi_line = '(?s)(.*?)(?s)'
	
	open $file
	| inspect
	| str replace --all --regex $os_keep 'OS KEEP'
	| str replace --all --regex ('OS\s*=\s*\S*') 'OS REMOVE'
	| inspect
	# Add END before all OS-line delimiters
	| str replace --all --multiline --regex $os_line_any "==(*END*)==\n$0"
	| inspect
	| str replace --all --multiline --regex ($os_line_keep + $multi_line + $end_line) "$1"
	| inspect
	| str replace --all --multiline --regex ($os_line_remove + $multi_line + $end_line) ""
	| inspect
	
	
	
	# | str replace --all --multiline --regex ('(?i)^.*?==*=\(\*\s*OS\s*=\s*' + $os.platform + '\s+' + $os.name + '\s*\*\)==*=.*?$\r?\n?(?s)(.*?)(?s)\r?\n?^.*?==*=\(\*.*?\S+.*?\*\)==*=.*?$') '$1'
	# | inspect
	# | str replace --all --multiline --regex ('(?i)^.*?==*=\(\*\s*OS\s*=\s*' + $os.platform + '\s*\*\)==*=.*?$\r?\n?(?s)(.*?)(?s)\r?\n?^.*?==*=\(\*.*?\S+.*?\*\)==*=.*?$') '$1'
	# | inspect
	# | str replace --all --multiline --regex ('(?i)^.*?==*=\(\*\s*OS\s*=\s*' + $os.name + '\s*\*\)==*=.*?$\r?\n?(?s)(.*?)(?s)\r?\n?^.*?==*=\(\*.*?\S+.*?\*\)==*=.*?$') '$1'
	# | inspect
	# | str replace --all --multiline --regex ('(?i)^.*?==*=\(\*\s*USER\s*=\s*' + $user + '\s*\*\)==*=.*?$\r?\n?(?s)(.*?)(?s)\r?\n?^.*?==*=\(\*.*?\S+.*?\*\)==*=.*?$') '$1'
	# | inspect
	# | str replace --all --multiline --regex ('(?i)^.*?==*=\(\*.*?\S+.*?\*\)==*=.*?$') ''
	# | inspect
	# | str replace --all --regex ('(?i)\(\*\s*OS\s*=\s*' + $os.platform + '\s+' + $os.name + '\s*\|\s*(.*?)\*\)') '$1'
	# | str replace --all --regex ('(?i)\(\*\s*OS\s*=\s*' + $os.platform + '\s*\|\s*(.*?)\*\)') '$1'
	# | str replace --all --regex ('(?i)\(\*\s*OS\s*=\s*' + $os.name + '\s*\|\s*(.*?)\*\)') '$1'
	# | str replace --all --regex ('(?i)\(\*\s*OS\s*=\s*.*?\s*\|\s*.*?\*\)') ''
	# | inspect
	# | str replace --all --regex ('(?i)\(\*\s*USER=' + $user + '\s*\|\s*(.*?)\*\)') '$1'
	# | str replace --all --regex ('(?i)\(\*\s*USER=.*?\s*\|\s*.*?\*\)') ''
	# | inspect
	# | save $file --force
}
