# quick-compile-scripts
Tiny script that will run/build/test stuff.
Intended to be used with keybindings.

## Usage


* (optional) Export `QCS_SAVE_FILE` to a valid file as it will be used to store qcs session info.
* Call `qcs output` in a tmux pane to set the "output" tmux pane into which run/build/test commands will be set.
* Call `qcs set <lang>` to set the project directory while located in it.
* Use. (`qcs run/build/test`)

## Args

* `run/build/test` does the thing.
* `output` updates the tmux pane
* `set <lang>` updates project dir and lang to pwd
* `dir` echoes back the project dir
* `terminate` sends a CTRL-C interrupt to the tmux pane.
