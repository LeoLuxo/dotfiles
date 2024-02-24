

export-env {
	$env.DOTFILES = ([$env.HOME, ".dotfiles"] | path join)
}

# Utils

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

def path-count [] {
	reduce --fold {files:0, dirs:0} {|it, acc| match ($it | path type) {
		"file" => {files: ($acc.files + 1), dirs: $acc.dirs},
		"dir"  => {files: $acc.files, dirs: ($acc.dirs + 1)},
	}}
}

def debug-path-type [] {
	each { |e| print $"($e): ($e | path type)"}
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

def download-check [] {
	let result = true
	
	let repo_dialog = {confirmation-prompt $"(ansi red)($env.DOTFILES) repo has uncommitted changes, are you sure you want to overwrite?(ansi reset)"}
	let repo_override_cancel = (repo-exists $env.DOTFILES) and (repo-has-changes $env.DOTFILES) and (not (do $repo_dialog))
	
	if $repo_override_cancel {
		print $"(ansi yellow)Aborted.(ansi reset)"
		return false
	}
	
	let folder_dialog = {confirmation-prompt $"(ansi red)($env.DOTFILES) folder is non-empty, are you sure you want to overwrite?(ansi reset)"}
	let folder_override_cancel = not ((folder-empty $env.DOTFILES) or (do $folder_dialog))
	
	if $folder_override_cancel {
		print $"(ansi yellow)Aborted.(ansi reset)"
		return false
	}
	
	return true
}



# Commands


# Download the dotfiles from the repo into $env.DOTFILES.
# Will prompt if the repo already exists and has uncommitted changes
export def download [
	--force (-f) # Force deletion of $env.DOTFILES and override potential prompt
] {
	let folder_exist = ($env.DOTFILES | path exists)
	
	# If user chose to force override, or if the folder doesn't exist anyway, continue
	if $folder_exist {
		if (not ($force or (download-check))) {
			return
		}
		
		rm --recursive $env.DOTFILES
	}
	
	git clone --branch nu --single-branch https://github.com/LeoLuxo/dotfiles.git $env.DOTFILES
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
		return {file:$file dirname:$dirname OS:$os USER:$user}
	}
	
	if ($file | is-empty) or ($file | path type) != "file" {
		error make {msg: $"Given path '($file)' must be a file", label: {text: "bad file", span: (metadata $file).span}}
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
	
	open $file --raw
	| decode utf-8
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
	# | inspect
	| each --keep-empty {|e|
		if ($e.file | is-empty) {
			$e.rest
		} else {
			cd $dirname;
			try {
				open $e.file
			} catch {
				error make {msg: $"The given file '($file)' has an invalid INCLUDE", label: {text: "bad file", span: (metadata $file).span}}
			}
		}
	}
	| str join "\n"
	# Save or output
	| if $dry {$in} else {$in | save $file --force}
	
}



# Applies the dotfiles from .dotfiles.
# This includes:
# - Patching each file
# - Applying registry keys from _reg
# - Copying the folders from _copy to their respective destinations
# - Copying other dotfiles to HOME
export def apply [
	--restart (-r)
] {
	let exclude = ['**/.git' '**/.gitignore']
	let exclude_patch = ['.ico']
	
	let tmp = mktemp --directory --tmpdir
	
	# Copy from .dotfiles to temp
	cp --recursive ($env.DOTFILES | path join "*") $tmp
	
	# Remove unwanted files
	do {
		cd $tmp;
		$exclude | each { |e|
			glob $e | each { |e|
				rm --recursive $e
			}
		}
	}
	
	# Patch in temp
	do {
		cd $tmp;
		glob "**/*" --no-dir
		| where not ($it | is-empty)
		| where ($it | path type) == "file"
		| where not ($it | str ends-with "dotfiles.nu")
		| each { |e|
			if ($exclude_patch | each { |f| $e | path basename | str ends-with $f} | all {|e| $e == false}) {
				patch $e;
				$e
			}
		}
		| print $"(ansi blue)($in | length) files patched.(ansi reset)"
	}
	
	# Apply windows registry files
	let reg_path =  ($tmp | path join "_reg")
	do {
		if ((get-os).name | str downcase) == "windows" {
			cd $reg_path
			glob "**/*.reg" --no-dir
			| each { |e|
				do {^reg import $e} | complete |
				(if $in.exit_code != 0 {
					print $"(ansi red)Registry file '($e)' could not be applied.(ansi reset)"
				}; $in)
			}
			| where $it.exit_code == 0
			| print $"(ansi blue)Applied ($in | length) registry files.(ansi reset)"
		}
	}
	rm --recursive $reg_path
	
	# Copy special destinations
	let copy_path =  ($tmp | path join "_copy")
	do {
		cd $copy_path
		glob "*" --no-file
		| each { |e| 
			let destinations = do {
				cd $e;
				open "_destinations" | lines | where not ($it | is-empty)
			}
			rm ($e | path join "_destinations");
			
			$destinations | each { |f|
				cp --recursive ($e | path join "*") $f
				
				cd $e;
				glob "**"
				# | inspect
				| path-count
				| print $"(ansi blue)($in.files) files in ($in.dirs) folders copied from (ansi yellow)($e | path relative-to $copy_path)(ansi blue) to (ansi purple)($f)(ansi blue) \((ansi white)($f | path expand)(ansi blue)\).(ansi reset)"
			}
		}
		
	}
	rm --recursive $copy_path
	
	# Copy into home
	do {
		cd $tmp;
		cp --recursive ./* $env.HOME;
		
		glob "**"
		| path-count
		| print $"(ansi blue)($in.files) files in ($in.dirs) folders copied to (ansi purple)~/(ansi blue) \((ansi white)($env.HOME | path expand)(ansi blue)\).(ansi reset)"
	}
	
	rm --recursive $tmp
	print $"(ansi green)Done!(ansi reset)"
	
	if $restart {
		restart
	}
}


# Force reload/restart of affected processes
export def restart [] {
	print $"(ansi yellow)Restarting...(ansi reset)"
	
	try {
		let exit_code = (sudo shell -register -treat -silent | complete).exit_code
		if $exit_code == 999 {
			print $"(ansi red)Nilesoft-shell needs admin priviledge.(ansi reset)"
		} else {
			print $"(ansi green)Nilesoft-shell registered.(ansi reset)"
		}
	} catch {
		print $"(ansi red)Nilesoft-shell not found.(ansi reset)"
	}
	
	^taskkill /F /IM explorer.exe
	^start explorer
	sleep 5sec
	print $"(ansi green)Explorer restarted.(ansi reset)"
	
	sleep 3sec
	reload --hard
}


# Download, apply and optionally reload
export def update [
	--force (-f) # Force deletion of $env.DOTFILES and override potential prompt
	--restart (-r)
] {
	if (not ($force or (download-check))) {
		return
	}
	
	download --force
	apply --restart=$restart
}
