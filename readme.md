This is a script for deploying generated files to a git branch, such as when building a single-page app using [Yeoman](http://yeoman.io) and deploying to [GitHub Pages](http://pages.github.com). Unlike the [git-subtree approach](https://github.com/yeoman/yeoman.io/blob/source/app/learning/deployment.md#git-subtree-command), it does not require the generated files be committed to the source branch. It keeps a linear history on the deploy branch and does not make superfluous commits or deploys when the generated files do not change.

[![Circle CI](https://circleci.com/gh/X1011/git-directory-deploy.svg?style=svg)](https://circleci.com/gh/X1011/git-directory-deploy)

For an example of use, see [X1011/verge-mobile-bingo](https://github.com/X1011/verge-mobile-bingo). For development info, see [contributing.md](contributing.md).

## installation

Download the script and make sure it is executable: (`wget https://github.com/X1011/git-directory-deploy/raw/master/deploy.sh && chmod +x deploy.sh`). That's it!

## configuration

These are the variables that the script uses for its settings:

- `GIT_DEPLOY_DIR`
   - Folder containing the files to deploy
   - Default: `./dist`
- `GIT_DEPLOY_BRANCH`
   - Dranch to which the deployed files are committed
   - Default: `gh-pages`
- `GIT_DEPLOY_USERNAME`
   - Name used for git commits made by the script
   - Default: `deploy.sh`
   - Useful for running on a CI server.
- `GIT_DEPLOY_EMAIL`
   - Email address used for git commits.
   - Default: `<empty>`
   - Useful for running on a CI server.
- `GIT_DEPLOY_REPO`
   - Remote repository to deploy to. It can be either a named remote, or a URL.
   - Default: `origin`
   - This remote _must_ be readable and writable.
   - _Note_ - The default of "origin" will not work on Travis CI, since it uses the read-only git protocol. In that case, it is recommended to store a [GitHub token](https://help.github.com/articles/creating-an-access-token-for-command-line-use) in a [secure environment variable](http://docs.travis-ci.com/user/environment-variables/#Secure-Variables) and use it in an HTTPS URL like this: <code>repo=https://$GITHUB_TOKEN@github\.com/<i>user</i>/<i>repo</i>.git</code>
   - **Warning: there is currently [an issue](https://github.com/X1011/git-directory-deploy/issues/7) where the repo URL may be output if an operation fails.**

These variables can be set in a number of different places, and will be set or overridden like this:

1. If nothing is specified the script uses its internal defaults.
2. An environment variable overrides the script's defaults.
3. A variable set in an `.env` file where you're running the script overrides an environment variable.
4. A variable set in a file specified on the command-line (see the `-c`/`--config` option) overrides `.env` and the environment.
5. Command-line options override everything.

## run
Do this every time you want to deploy, or have your CI server do it.

1. check out the branch or commit of the source you want to use. The script will use this commit to generate a message when it makes its own commit on the deploy branch.
2. generate the files in `deploy_directory`
3. make sure you have no uncommitted changes in git's index. The script will abort if you do. (It's ok to have uncommitted files in the work tree; the script does not touch the work tree.)
4. if `deploy_directory` is a relative path (the default is), make sure you are in the directory you want to resolve against. (For the default, this means you should be in the project's root.)
5. run `./deploy.sh`

### options

This is the syntax for setting the script's options on the command-line:

`deploy.sh [-c <FILE>] [<options>]`

Available options:

`-h`, `--help`: show the program's help info.

`-c`, `--config-file`: specify a file that overrides the script's default configuration, or those values set in `.env`. The syntax for this file should be normal `var=value` declarations. __This option _must_ come first on the command-line__.

`-m`, `--message <message>`: specify message to be used for the commit on `deploy_branch`. By default, the message is the title of the source commit, prepended with 'publish: '.

`-n`, `--no-hash`: don't append the hash of the source commit to the commit message on `deploy_branch`. By default, the hash will be appended in a new paragraph, regardless of whether a message was specified with `-m`.

`-v`, `--verbose`: echo expanded commands as they are executed, using the xtrace option. This can be useful for debugging, as the output will include the values of variables that are being used, such as $commit_title and $deploy_directory. However, the script makes special effort to not output the value of $repo, as it may contain a secret authentication token.

`-e`, `--allow-empty`: allow deployment of an empty directory. By default, the script will abort if `deploy_directory` is empty.
