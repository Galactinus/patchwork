#!/bin/bash
# Bash completion for patchwork command

_patchwork_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Available commands
    local commands="init add_patch test apply clear cache_patch deploy_patch build_patch check_for_updates"
    
    # Available options
    local options="--force --help"
    
    # If we're completing the first argument (command)
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
        return 0
    fi
    
    # Get the command being used
    local command="${COMP_WORDS[1]}"
    
    case "${command}" in
        init)
            # For init command, complete directory names
            COMPREPLY=($(compgen -d -- ${cur}))
            ;;
        add_patch)
            # For add_patch command, complete .patch files
            COMPREPLY=($(compgen -f -X '!*.patch' -- ${cur}))
            ;;
        apply)
            # For apply command, offer --force option
            if [[ ${cur} == -* ]]; then
                COMPREPLY=($(compgen -W "--force" -- ${cur}))
            fi
            ;;
        test|clear|cache_patch|deploy_patch|build_patch|check_for_updates)
            # These commands don't take additional arguments
            ;;
        *)
            # Default completion for other cases
            ;;
    esac
    
    return 0
}

# Register the completion function
complete -F _patchwork_completion patchwork.sh
complete -F _patchwork_completion patchwork 