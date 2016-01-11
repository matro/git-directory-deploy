This is a script for deploying generated files to a git branch, such as when building a single-page app using [Yeoman](http://yeoman.io) and deploying to [GitHub Pages](http://pages.github.com). Unlike the [git-subtree approach](https://github.com/yeoman/yeoman.io/blob/source/app/learning/deployment.md#git-subtree-command), it does not require the generated files be committed to the source branch. It keeps a linear history on the deploy branch and does not make superfluous commits or deploys when the generated files do not change.

[![Circle CI](https://circleci.com/gh/X1011/git-directory-deploy.svg?style=svg)](https://circleci.com/gh/X1011/git-directory-deploy)

For an example of use, see [X1011/verge-mobile-bingo](https://github.com/X1011/verge-mobile-bingo). For development info, see [contributing.md](contributing.md).

## installation

Download the script and make sure it is executable: (`wget https://github.com/X1011/git-directory-deploy/raw/master/deploy.sh && chmod +x deploy.sh`). That's it!

## usage

To use this script in a deployment, follow this basic workflow:

1. `git checkout` the commit (or branch or tag) of your project that you want to deploy.
2. Generate a complete copy of the files you want to deploy in some folder within your project.
   - This folder should probably be in your project's `.gitignore`. You don't want to accidentally commit this folder to your main branch hierarchy, after all. That's what this script is for!
   - Populating your "deploy folder" is out of this script's scope, and largely depends on the specifics of your project. This is where you'd run something like `make build`, a static site generator, etc.
3. Make sure your working directory is clean.
   - If you have uncommitted changes in git's _index_, the script will abort. The script needs a clean index in order to function.
   - If you have uncommitted files in the _work tree_, that's okay; the script does not touch the work tree, and checking for this should instead be the responsibility of your project's build process.
4. Run `deploy.sh` from your project's root.
   - If your project's needs match the script's defaults then that's it!
   - Different projects have different needs, names for the "deploy folder", "deploy branch", and other details. You may even see fit to deploy multiple parts of your project with this script, using vastly different settings. All of this is possible, by using configuration files and command-line options detailed below.
   - The key though, is that the script looks for _everything_ at paths relative to where you run it. Make sure you're running the script in the correct folder.

Following this workflow by hand can be tedious and error-prone, especially if you're using non-default settings. Rather than just running the script, we definitely recommend using this script in an automated build/deployment routine of some kind. Then, you (or your CI server) can make a deployment in a single step.

### the commmand-line:

```
deploy.sh [-c <CONFIG_FILE>] [<options>] [<directory> [<branch> [<repo>]]]
```

### configuration

The script looks for settings in a few places, in this order:

 1. Environment variables.
 2. An `.env` file (if it exists).
 3. A configuration file, if it is specified on the command-line.
 4. Values specified on the command-line.
 
Settings set in later places will override those set earlier. For anything that doesn't get set in any of these places, the script will fall back on its built-in defaults.

### options & settings

- `-h`, `--help`: show the program's help info.

- `-c`, `--config-file`: specify a configuration file.
   - This option **_must_ come first** on the command-line.
   - Syntax for this file (and `.env`) should be compatible with [other "dotenv" libraries](https://duckduckgo.com/?q=dotenv): 
   
     ```
     # Comment
     VAR_1=value
     VAR_2="another value"
     ```

- `-m`, `--message <message>`: specify message to be used when committing to the deployed branch.
   - By default, the message is the title of the source commit, prepended with `publish: `.

- `-n`, `--no-hash`: skip appending the hash of the source commit to the commit message.
   - The hash would otherwise be appended as a new paragraph in the commit message, keeping it separate from the text (see `-m`).
   - Setting: `GIT_DEPLOY_APPEND_HASH` (default: `true`).

- `-v`, `--verbose`: echo expanded commands as they are executed.
   - This can be useful for debugging, as the output will include the values of internal variables, such as `$commit_title` and `$deploy_directory`. However, the script makes special effort to not output the value of `$repo`, as it may contain a secret authentication token.

- `-e`, `--allow-empty`: allow committing and deployment of an empty directory.
    - Without this option, the script will abort if the deploy directory is empty. This is normally a good safety feature, but overriding it can sometimes or useful or necessary.

- `<directory> [<branch> [<repo>]]`: the source and target of the deployment. These can also be set with these variables:
   - `GIT_DEPLOY_DIR`: folder containing the files to deploy.
      - If this folder doesn't exist (or is empty, see `-e`), the script will abort. It's up to your project's init/build processes to create and populate this folder.
      - Default: `./dist`
   - `GIT_DEPLOY_BRANCH`: branch to which the deployable files are committed.
      - If this branch doesn't exist, the script will automatically create it. After this branch is committed to, it will also be automatically pushed.
      - Default: `gh-pages`
   - `GIT_DEPLOY_REPO`: remote repository to deploy to.
      - It can be either a named remote, or any URL that Git can push to.
      - This remote _must_ be readable and writable, as the script will push the deploy-branch to it. If remote is read-only, the script will fail.
      - Default: `origin`
      - _Note_ - The default of "origin" will not work on Travis CI, or any other utility that uses the read-only git protocol. In these cases, it is recommended to store a [GitHub token](https://help.github.com/articles/creating-an-access-token-for-command-line-use) in a [secure environment variable](http://docs.travis-ci.com/user/environment-variables/#Secure-Variables) and use it in an HTTPS URL like this:
      <code>
      GIT_DEPLOY_REPO=https://<strong>$GITHUB_TOKEN</strong>@github\.com/<em>user</em>/<em>repo</em>.git
      </code>
      - **Warning** - there is currently [an issue](https://github.com/X1011/git-directory-deploy/issues/7) where the repo URL may be output if an operation fails.

- _Commiter identity_: attribution info used in script's git commits.
   - `GIT_DEPLOY_USERNAME`: committer name. Defaults to `deploy.sh`.
   - `GIT_DEPLOY_EMAIL`: committer email address. Defaults to `<empty>`.
   - Setting these in your different environments (such as your CI server vs local machine) is useful showing who made what deployments from where in the commit log.
