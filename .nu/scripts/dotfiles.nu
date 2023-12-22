
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



def get-os [] {
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
# Multiline:
# ==(* OS=windows *)==
# ==(* OS END *)==
#
# USER delimiter:
# (* USER=neon | lorem ipsum *)
# Multiline:
# ==(* USER=pollux *)==
# ==(* USER END *)==
export def patch [
	file? # File to patch
	--info (-i) # Print current info instead of patching
	--dry (-d) # Don't save the file and only return the result instead
] {
	let os = get-os | str downcase platform name
	let user = $env.USERNAME | str downcase
	let dirname = $file | path dirname
	
	if $info {
		print $"OS=($os.platform) ($os.name)"
		print $"USER=($user)"
		print $"[dirname=($dirname)]"
		return
	}
	
	if $file == null or ($file | path type) != "file" {
		error make {msg: "Given path must be a file", label: {text: "bad file", span: (metadata $file).span}}
	}
	
	let linewide_left = '^.*?==*=\(\*\s*'
	let linewide_right = '\s*\*\)==*=.*?$\n?'
	let multi_line = '(?s)(.*?)(?s)'	
	
	let os_keep = 'OS\s*=\s*(?:' + $os.platform + '\s+' + $os.name + '|' + $os.platform + '|' + $os.name + ')'
	let os_line_any = $linewide_left + 'OS (?:KEEP|REMOVE)' + $linewide_right
	let os_line_keep = $linewide_left + 'OS KEEP' + $linewide_right
	let os_line_remove = $linewide_left + 'OS REMOVE' + $linewide_right
	let os_end_line = $linewide_left + 'OS END' + $linewide_right
	let os_single_keep = '\(\*\s*OS KEEP\s*\|(.*?)\*\)'
	let os_single_remove = '\(\*\s*OS REMOVE\s*\|(.*?)\*\)'
	
	let user_keep = 'USER\s*=\s*' + $user
	let user_line_any = $linewide_left + 'USER (?:KEEP|REMOVE)' + $linewide_right
	let user_line_keep = $linewide_left + 'USER KEEP' + $linewide_right
	let user_line_remove = $linewide_left + 'USER REMOVE' + $linewide_right
	let user_end_line = $linewide_left + 'USER END' + $linewide_right
	let user_single_keep = '\(\*\s*USER KEEP\s*\|(.*?)\*\)'
	let user_single_remove = '\(\*\s*USER REMOVE\s*\|(.*?)\*\)'
	
	let include = '(?:' + $linewide_left + 'INCLUDE\s*(?<file>.*?)' + $linewide_right + '|(?<rest>.*))'
	
	open $file
	# | inspect
	| str replace --all --multiline --regex '(?:\r\n|\n)' "\n"
	# Multiline OS
	| str replace --all --regex $os_keep "OS KEEP"
	| str replace --all --regex ('OS\s*=\s*\S*') "OS REMOVE"
	| str replace --all --multiline --regex $os_line_any "==(*OS END*)==\n$0"
	| str replace --all --multiline --regex ($os_line_remove + $multi_line + $os_end_line) ""
	| str replace --all --multiline --regex ($os_line_keep) ""
	| str replace --all --multiline --regex ($os_end_line) ""
	# Multiline USER
	| str replace --all --regex $user_keep "USER KEEP"
	| str replace --all --regex ('USER\s*=\s*\S*') "USER REMOVE"
	| str replace --all --multiline --regex $user_line_any "==(*USER END*)==\n$0"
	| str replace --all --multiline --regex ($user_line_remove + $multi_line + $user_end_line) ""
	| str replace --all --multiline --regex ($user_line_keep) ""
	| str replace --all --multiline --regex ($user_end_line) ""
	# Single OS
	| str replace --all --regex $os_single_keep "$1"
	| str replace --all --regex $os_single_remove ""
	# Single USER
	| str replace --all --regex $user_single_keep "$1"
	| str replace --all --regex $user_single_remove ""
	# Include file
	| lines
	| parse --regex $include
	| each --keep-empty {|e| if ($e.file | is-empty) {$e.rest} else {cd $dirname; open $e.file}}
	| str join "\n"
	# Save or output
	| if $dry {$in} else {$in | save $file --force}
	
}
