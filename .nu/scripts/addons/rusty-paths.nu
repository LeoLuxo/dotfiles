# Description
#
# Include `target/debug` and `target/release` in `$env.PATH`
# while `cd`-ing into a Rust project (assumed existence of `Cargo.lock`)


$env.config = ($env.config | update hooks.env_change.PWD {
	append {
		condition: {|_, after| ($after | path join 'Cargo.lock' | path exists) }
		code: {
			$env.PATH = (
				$env.PATH
					| prepend ($env.PWD | path join 'target/debug')
					| prepend ($env.PWD | path join 'target/release')
					| uniq
				)
		}
	}
})