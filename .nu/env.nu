# Nushell Environment Config File
#
# version = "0.87.1"

# Default:
# https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/sample_config/default_env.nu


# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
	"PATH": {
		from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
		to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
	}
	"Path": {
		from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
		to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
	}
}

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')






# Custom

$env.NU_ARGS = "--env-config ~/.nu/env.nu --config ~/.nu/config.nu"

# Homogeanize env to fix compat issues
$env.PATH = $env.Path
$env.HOME = $env.USERPROFILE

# $env.CARGO_HOME = ($env.HOME | path join ".cargo")
# setx CARGO_HOME "%USERPROFILE%\\.cargo" | null

# Directories to search for scripts when calling source or use
$env.NU_LIB_DIRS = [
	("~/.nu" | path join "scripts")
]

# Directories to search for plugin binaries when calling register
$env.NU_PLUGIN_DIRS = [
	("~/.nu" | path join "plugins")
]

# Scoop
$env.SCOOP = "C:/Scoop/"
$env.SCOOP_GLOBAL = "C:/ProgramData/scoop/"

# Coq
$env.COQBIN = ([$env.SCOOP, "apps/coq/current/bin/"] | path join)

# Oh-my-posh
oh-my-posh init nu --config "~/.nu/ohmyposh/themes/peppy.omp.json" --print | save ~/.nu/ohmyposh/_ohmyposh.nu --force
