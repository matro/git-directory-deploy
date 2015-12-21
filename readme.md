This is a script for deploying generated files to a git branch, such as when building a single-page app using [Yeoman](http://yeoman.io) and deploying to [GitHub Pages](http://pages.github.com). Unlike the [git-subtree approach](https://github.com/yeoman/yeoman.io/blob/source/app/learning/deployment.md#git-subtree-command), it does not require the generated files be committed to the source branch. It keeps a linear history on the deploy branch and does not make superfluous commits or deploys when the generated files do not change.

[![Circle CI](https://circleci.com/gh/X1011/git-directory-deploy.svg?style=svg)](https://circleci.com/gh/X1011/git-directory-deploy)

For an example of use, see [X1011/verge-mobile-bingo](https://github.com/X1011/verge-mobile-bingo). For development info, see [contributing.md](contributing.md).

## installation

Download the script and make sure it is executable: (`wget https://github.com/X1011/git-directory-deploy/raw/master/deploy.sh && chmod +x deploy.sh`). That's it!

## options & settings

The script looks for settings in a few places, in this order:

 1. Environment variables.
 2. Your project's "dotenv" file (`.env`), if it exists.
 3. A configuration file specified in the command-line.
 4. Specific values specified on the command-line.
 
Settings set in later places will override those set earlier. For anything that doesn't get set in any of these places, the script will fall back on its built-in defaults.

### commmand-line:

```
deploy.sh [-c <FILE>] [<options>] [<directory> [<branch> [<repo>]]]
```

### list of options

- `-h`, `--help`: show the program's help info.

- `-c`, `--config-file`: specify a configuration file.
   - This option **_must_ come first** on the command-line.
   - Syntax for this file (and `.env`) should be compatible with [other "dotenv" libraries](https://duckduckgo.com/?q=dotenv): 
   
     ```
     # Comment
     VAR_1=value
     VAR_2="another value"
     ```

- `-m`, `--message <message>`: specify message to be used for the commit on `deploy_branch`. By default, the message is the title of the source commit, prepended with 'publish: '.

- `-n`, `--no-hash`: don't append the hash of the source commit to the commit message.
   - By default, the hash will be appended in a new paragraph, regardless of whether a message was specified with `-m`.
   - Set with `GIT_DEPLOY_APPEND_HASH` (default: `true`).

- `-v`, `--verbose`: echo expanded commands as they are executed, using the xtrace option.
   - This can be useful for debugging, as the output will include the values of internal variables, such as `$commit_title` and `$deploy_directory`. However, the script makes special effort to not output the value of `$repo`, as it may contain a secret authentication token.

- `-e`, `--allow-empty`: allow deployment of an empty directory.
    - By default, the script will abort if the deploy directory is empty. Letting the script complete can be useful for troubleshooting though.

- `<directory> [<branch> [<repo>]]`: the source and target of the deployment. These can also be set with these variables:
   - `GIT_DEPLOY_DIR`: folder containing the files to deploy. If this folder doesn't exist (or is empty), the script will abort. Defaults to `./dist`.
   - `GIT_DEPLOY_BRANCH`: branch to which the deployable files are committed. If this branch doesn't exist, the script will automatically create it. Defaults to `gh-pages`.
   - `GIT_DEPLOY_REPO`: remote repository to deploy to. It can be either a named remote, or a URL. Defaults to `origin`.
      - This remote _must_ be readable and writable, as the script will push the deploy-branch to it, or fail.
      - _Note_ - The default of "origin" will not work on Travis CI, or any other utility that uses the read-only git protocol. In these cases, it is recommended to store a [GitHub token](https://help.github.com/articles/creating-an-access-token-for-command-line-use) in a [secure environment variable](http://docs.travis-ci.com/user/environment-variables/#Secure-Variables) and use it in an HTTPS URL like this: <code>GIT_DEPLOY_REPO=https://$GITHUB_TOKEN@github\.com/<i>user</i>/<i>repo</i>.git</code>
      - **Warning: there is currently [an issue](https://github.com/X1011/git-directory-deploy/issues/7) where the repo URL may be output if an operation fails.**

- _Commiter identity_: attribution info used in script's git commits.
   - `GIT_DEPLOY_USERNAME`: committer name. Defaults to `deploy.sh`.
   - `GIT_DEPLOY_EMAIL`: committer email address. Defaults to `<empty>`.
   - This is useful for running deployments from a CI server, and otherwise showing who made what deployments from where in the commit log.

## run
Do this every time you want to deploy, or have your CI server do it.

1. check out the branch or commit of the source you want to use. The script will use this commit to generate a message when it makes its own commit on the deploy branch.
2. generate the files in `deploy_directory`
3. make sure you have no uncommitted changes in git's index. The script will abort if you do. (It's ok to have uncommitted files in the work tree; the script does not touch the work tree.)
4. if `deploy_directory` is a relative path (the default is), make sure you are in the directory you want to resolve against. (For the default, this means you should be in the project's root.)
5. run `./deploy.sh`
