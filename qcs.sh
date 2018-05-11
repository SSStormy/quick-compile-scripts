#!/bin/bash

########## Initialize
function log() {
    echo $1
}

function warn() {
    >&2 log "--> $@"
}

if [ "$QCS_SAVE_FILE" = "" ] ; then
    warn "QCS_SAVE_FILE not exported, falling back to default."
    QCS_SAVE_FILE=~/.qcs_save_file
fi

########## Language string setup
# if you want to expand the scipt, start here.
QCS_LANGS="cpp rust-bin rust-lib"
QCS_LANGS_ARRAY=($QCS_LANGS)

QCS_LANG_CPP=${QCS_LANGS_ARRAY[0]}
QCS_LANG_RUST_BIN=${QCS_LANGS_ARRAY[1]}
QCS_LANG_RUST_LIB=${QCS_LANGS_ARRAY[2]}

########## Deserialize QCS_SAVE_FILE
data="$(cat $QCS_SAVE_FILE)"
arr=($data)

QCS_PROJECT_DIR=${arr[0]}
QCS_PROJECT_LANG=${arr[1]}
QCS_TMUX_PANE=${arr[2]}

function send_cmd_to_output() {
    if [ "$QCS_TMUX_PANE" = "" ] ; then
        warn "No TMUX pane selected. (output)"
    else
        tmux send-keys -t $QCS_TMUX_PANE C-c
        tmux send-keys -t $QCS_TMUX_PANE " cd "$QCS_PROJECT_DIR"; clear; $@" C-m 
    fi
}

function script_build() {
    case $QCS_PROJECT_LANG in
        $QCS_LANG_CPP) 
            send_cmd_to_output "cd build; make -j8"
            ;;
        $QCS_LANG_RUST_BIN|$QCS_LANG_RUST_LIB)
            send_cmd_to_output "cargo check"
            ;;
        *) 
            send_cmd_to_output "echo Unknown language: $QCS_PROJECT_LANG"
            ;;
    esac
}

function script_run() {
    case $QCS_PROJECT_LANG in 
        $QCS_LANG_CPP) 
            send_cmd_to_output "echo Running CPP projects is unsupported."
            ;;
        $QCS_LANG_RUST_LIB)
            send_cmd_to_output "RUST_BACKTRACE=1 cargo build --lib"
            ;;
        $QCS_LANG_RUST_BIN)
            send_cmd_to_output "RUST_BACKTRACE=1 cargo run"
            ;;
        *) 
            send_cmd_to_output "echo Unknown language: $QCS_PROJECT_LANG"
            ;;
    esac
}

function script_test() {
    case $QCS_PROJECT_LANG in
        $QCS_LANG_CPP) 
            send_cmd_to_output "cd build; make tests -j8; ./tests"
            ;;
        $QCS_LANG_RUST_LIB|$QCS_LANG_RUST_BIN)
            send_cmd_to_output "RUST_BACKTRACE=1 cargo test"
            ;;
        *) 
            send_cmd_to_output "echo Unknown language: $QCS_PROJECT_LANG"
            ;;
    esac
}

function verify_save_stuff() {
    if [ "$QCS_PROJECT_DIR" = "" ] ; then 
        warn "Project dir is empty."
        warn "Did you set up the project? (set)"
        exit 1
    fi

    if [ "$QCS_PROJECT_LANG" = "" ] ; then 
        warn "Lang is empty"
        warn "Did you set up the project? (set)"
        exit 1
    fi
}


########## Handle args
case $1 in
    "build") 
        verify_save_stuff
        script_build
        ;;
    "run")
        verify_save_stuff
        script_run
        ;;
    "test") 
        verify_save_stuff
        script_test
        ;;
    "set")
        if [ $2 = ""  ] ; then
            warn "--> Specify a language ($QCS_LANGS)."
        else
            for l in "${QCS_LANGS_ARRAY[@]}" ; do
                if [ "$2" == "$l" ] ; then lang=$l ; fi
            done

            if [ "$lang" == "" ] ; then
                warn "Unknown language: $2"
                warn "Please choose one:"
                warn "$QCS_LANGS"
            else
                QCS_PROJECT_LANG=$lang
                QCS_PROJECT_DIR=$PWD
                log "Set project dir to \"$QCS_PROJECT_DIR\""
                log "Set project lang to \"$QCS_PROJECT_LANG\""
            fi
        fi
        ;;

    "output")
        if [ "$TMUX_PANE" != "" ] ; then
            QCS_TMUX_PANE=$TMUX_PANE
            log "Set QCS output pane to ${QCS_TMUX_PANE}"
        else
            warn "TMUX_PANE is not set."
        fi
        ;;

    "dir")
        echo $QCS_PROJECT_DIR
        ;;
    "terminate")
        tmux send-keys -t $QCS_TMUX_PANE C-c
        ;;
    *)
        warn "Invalid arguments (build; run; test; set; output; jump; terminate)"
        ;;
esac

########## Serialize save file data
echo $QCS_PROJECT_DIR > $QCS_SAVE_FILE
echo $QCS_PROJECT_LANG >> $QCS_SAVE_FILE
echo $QCS_TMUX_PANE >> $QCS_SAVE_FILE

