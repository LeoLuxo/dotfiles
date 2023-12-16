let source_link = "https://raw.githubusercontent.com/LeoLuxo/dotfiles/nu/.nu/scripts/dotfiles.nu"
let destination = (mktemp -t)

def printc [
	text: string
	maincolor?: string
] {
	mut color = (ansi blue)
	if $maincolor != null {
		$color = $maincolor
	}
	print (
		($color + $text + (ansi reset))
		| str replace -a '<' $"(ansi reset)(ansi magenta_italic)"
		| str replace -a '>' $"(ansi reset)($color)"
	)
}

printc $"Downloading <($source_link)> into <($destination)>..."

http get --raw $source_link | save $destination --force

printc $"Sourcing <($destination)>..."
nu -c $"source ($destination); download -f"

printc $"Deleting <($destination)>..."
rm --permanent $destination

printc $"Done!" (ansi green)

printc $"\nDON'T FORGET TO RELOAD" (ansi red)
