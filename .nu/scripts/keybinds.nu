$env.config.keybindings = ($env.config.keybindings | append [
	{
		name: quickreload
		modifier: none
		keycode: f5
		mode: emacs
		event: {
			send: executehostcommand,
			cmd: "reload"
		}	
	},
	{
		name: quickreload_hard
		modifier: CONTROL
		keycode: f5
		mode: emacs
		event: {
			send: executehostcommand,
			cmd: "reload --hard"
		}	
	},
])