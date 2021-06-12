set -gp fish_user_paths bin/
alias scb src/cli.cr
complete --command cb --arguments '(cb --_completion (commandline -cp))' --no-files
complete --command scb --arguments '(scb --_completion (commandline -cp))' --no-files
