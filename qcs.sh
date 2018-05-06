#!/bin/bash

function log() {
    echo "--> $1"
}

function warn() {
    >&2 log "$@"
}

if [ "$QCS_SAVE_FILE" = "" ] ; then
    warn "QCS_SAVE_FILE not exported."
    exit 1
fi

QCS_LANGS="cpp rust-bin rust-lib"
QCS_LANGS_ARRAY=($QCS_LANGS)

QCS_LANG_CPP=${QCS_LANGS_ARRAY[0]}
QCS_LANG_RUST_BIN=${QCS_LANGS_ARRAY[1]}
QCS_LANG_RUST_LIB=${QCS_LANGS_ARRAY[2]}

data="$(cat $QCS_SAVE_FILE)"
arr=($data)

QCS_PROJECT_DIR=${arr[0]}
QCS_PROJECT_LANG=${arr[1]}
QCS_TMUX_PANE=${arr[2]}

QCS_OLD_DIR=$PWD

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

cd $QCS_PROJECT_DIR

function send_to_output() {
    if [ "$QCS_TMUX_PANE" = "" ] ; then
        warn "No TMUX pane selected. (output)"
    else
        tmux send-keys -t $QCS_TMUX_PANE "cd "$QCS_PROJECT_DIR"; clear; $@" C-m
    fi
}

case $1 in
    "build")
        case $QCS_PROJECT_LANG in
            $QCS_LANG_CPP) 
                send_to_output "make -j8"
                ;;
            $QCS_LANG_RUST_BIN|$QCS_LANG_RUST_LIB)
                send_to_output "cargo check"
                ;;
            *) 
                send_to_output "echo Unknown language: $QCS_PROJECT_LANG"
                ;;
        esac
        ;;

    "run")
        case $QCS_PROJECT_LANG in
            $QCS_LANG_CPP) 
                send_to_output "echo Running CPP projects is unsupported."
                ;;
            $QCS_LANG_RUST_LIB)
                send_to_output "RUST_BACKTRACE=1 cargo build --lib"
                ;;
            $QCS_LANG_RUST_BIN)
                send_to_output "RUST_BACKTRACE=1 cargo run"
                ;;
            *) 
                send_to_output "echo Unknown language: $QCS_PROJECT_LANG"
                ;;
        esac
        ;;

    "test")
        case $QCS_PROJECT_LANG in
            $QCS_LANG_CPP) 
                send_to_putput "echo Testing CPP projects is unsupported."
                ;;
            $QCS_LANG_RUST_LIB|$QCS_LANG_RUST_BIN)
                send_to_output "RUST_BACKTRACE=1 cargo test"
                ;;
            *) 
                send_to_output "echo Unknown language: $QCS_PROJECT_LANG"
                ;;
        esac
        ;;

    "set")
        if [ $2 = ""  ] ; then
            warn "--> Specify a language ($QCS_LANGS)."
        else
            for l in "${QCS_LANGS_ARRAY[@]}" ; do
                if [ "$1" == "$l" ] ; then lang=$l ; fi
            done

            if [ "$lang" == "" ] ; then
                warn "Unknown language: $1"
                warn "Please choose one:"
                warn "$QCS_LANGS"
            fi
        fi
        ;;

    "output")
        if [ $TMUX_PANE != "" ] ; then
            QCS_TMUX_PANE=$TMUX_PANE
            log "Set QCS output pane to ${QCS_TMUX_PANE}"
        else
            warn "TMUX_PANE is not set."
        fi
        ;;

    "dir")
        echo $QCS_PROJECT_DIR
        ;;

    *)
        warn "Invalid arguments (build; run; test; set; output; jump)"
        ;;
esac

cd $QCS_OLD_DIR

echo $QCS_PROJECT_DIR > $QCS_SAVE_FILE
echo $QCS_PROJECT_LANG >> $QCS_SAVE_FILE
echo $QCS_TMUX_PANE >> $QCS_SAVE_FILE

