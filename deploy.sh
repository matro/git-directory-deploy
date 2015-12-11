#!/usr/bin/env bash
set -o errexit #abort if any command fails
me=$(basename "$0")

read -r -d '' "help_message" <<EOF || true

Deploy generated files to a git branch.

Usage:

  $me [<options>]

Options:

  -h, --help               Show this help information.
  -v, --verbose            Increase verbosity. Useful for debugging.
  -e, --allow-empty        Allow deployment of an empty directory.
  -m, --message MESSAGE    Specify the message used when committing on the
                           deploy branch.
  -n, --no-hash            Don't append the source commit's hash to the deploy
                           commit's message.
  -c, --config-file PATH   Override default & environment variables' values
                           with those in set in the file at 'PATH'.

Variables:

  * GIT_DEPLOY_DIR      Folder path containing the files to deploy.
  * GIT_DEPLOY_BRANCH   Commit deployable files to this branch.
  * GIT_DEPLOY_REPO     Push the deploy branch to this repository.

These variables have default values defined in the script. The defaults can be
overridden by environment variables. Any environment variables are overridden
by values set in a '.env' file (if it exists), and in turn by those set in a
file specified by the '--config-file' option.
EOF

print_help() {
	printf "%s\n" "$help_message"
}

main() {
	# Set args from a local environment file.
	if [ -e ".env" ]; then
		source .env
	fi

	#append commit hash to the end of message by default
	append_hash=true

	# Parse arg flags
	while : ; do
		if [[ $1 = "-h" || $1 = "--help" ]]; then
			print_help
			return 0
		elif [[ $1 = "-v" || $1 = "--verbose" ]]; then
			verbose=true
			shift
		elif [[ $1 = "-e" || $1 = "--allow-empty" ]]; then
			allow_empty=true
			shift
		elif [[ ( $1 = "-m" || $1 = "--message" ) && -n $2 ]]; then
			commit_message=$2
			shift 2
		elif [[ $1 = "-n" || $1 = "--no-hash" ]]; then
			append_hash=false
			shift
		elif [[ $1 = "-c" || $1 = "--config-file" ]]; then
			source "$2"
			shift 2
		else
			break
		fi
	done

	# Set default options
	deploy_directory=${GIT_DEPLOY_DIR:-dist}
	deploy_branch=${GIT_DEPLOY_BRANCH:-gh-pages}

	#if no user identity is already set in the current git environment, use this:
	default_username=${GIT_DEPLOY_USERNAME:-deploy.sh}
	default_email=${GIT_DEPLOY_EMAIL:-}

	#repository to deploy to. must be readable and writable.
	repo=${GIT_DEPLOY_REPO:-origin}
	
	enable_expanded_output

	if ! git diff --exit-code --quiet --cached; then
		echo Aborting due to uncommitted changes in the index >&2
		return 1
	fi

	commit_title=`git log -n 1 --format="%s" HEAD`
	commit_hash=` git log -n 1 --format="%H" HEAD`
	
	#default commit message uses last title if a custom one is not supplied
	if [[ -z $commit_message ]]; then
		commit_message="publish: $commit_title"
	fi
	
	#append hash to commit message unless no hash flag was found
	if [ $append_hash = true ]; then
		commit_message="$commit_message"$'\n\n'"generated from commit $commit_hash"
	fi
		
	previous_branch=`git rev-parse --abbrev-ref HEAD`

	if [ ! -d "$deploy_directory" ]; then
		echo "Deploy directory '$deploy_directory' does not exist. Aborting." >&2
		return 1
	fi
	
	# must use short form of flag in ls for compatibility with OS X and BSD
	if [[ -z `ls -A "$deploy_directory" 2> /dev/null` && -z $allow_empty ]]; then
		echo "Deploy directory '$deploy_directory' is empty. Aborting. If you're sure you want to deploy an empty tree, use the --allow-empty / -e flag." >&2
		return 1
	fi

	if git ls-remote --exit-code $repo "refs/heads/$deploy_branch" ; then
		# deploy_branch exists in $repo; make sure we have the latest version
		
		disable_expanded_output
		git fetch --force $repo $deploy_branch:$deploy_branch
		enable_expanded_output
	fi

	# check if deploy_branch exists locally
	if git show-ref --verify --quiet "refs/heads/$deploy_branch"
	then incremental_deploy
	else initial_deploy
	fi

	restore_head
}

initial_deploy() {
	git --work-tree "$deploy_directory" checkout --orphan $deploy_branch
	git --work-tree "$deploy_directory" add --all
	commit+push
}

incremental_deploy() {
	#make deploy_branch the current branch
	git symbolic-ref HEAD refs/heads/$deploy_branch
	#put the previously committed contents of deploy_branch into the index
	git --work-tree "$deploy_directory" reset --mixed --quiet
	git --work-tree "$deploy_directory" add --all

	set +o errexit
	diff=$(git --work-tree "$deploy_directory" diff --exit-code --quiet HEAD --)$?
	set -o errexit
	case $diff in
		0) echo No changes to files in $deploy_directory. Skipping commit.;;
		1) commit+push;;
		*)
			echo git diff exited with code $diff. Aborting. Staying on branch $deploy_branch so you can debug. To switch back to master, use: git symbolic-ref HEAD refs/heads/master && git reset --mixed >&2
			return $diff
			;;
	esac
}

commit+push() {
	set_user_id
	git --work-tree "$deploy_directory" commit -m "$commit_message"

	disable_expanded_output
	#--quiet is important here to avoid outputting the repo URL, which may contain a secret token
	git push --quiet $repo $deploy_branch
	enable_expanded_output
}

#echo expanded commands as they are executed (for debugging)
enable_expanded_output() {
	if [ $verbose ]; then
		set -o xtrace
		set +o verbose
	fi
}

#this is used to avoid outputting the repo URL, which may contain a secret token
disable_expanded_output() {
	if [ $verbose ]; then
		set +o xtrace
		set -o verbose
	fi
}

set_user_id() {
	if [[ -z `git config user.name` ]]; then
		git config user.name "$default_username"
	fi
	if [[ -z `git config user.email` ]]; then
		git config user.email "$default_email"
	fi
}

restore_head() {
	if [[ $previous_branch = "HEAD" ]]; then
		#we weren't on any branch before, so just set HEAD back to the commit it was on
		git update-ref --no-deref HEAD $commit_hash $deploy_branch
	else
		git symbolic-ref HEAD refs/heads/$previous_branch
	fi
	
	git reset --mixed
}

filter() {
	sed -e "s|$repo|\$repo|g"
}

sanitize() {
	"$@" 2> >(filter 1>&2) | filter
}

[[ $1 = --source-only ]] || main "$@"
