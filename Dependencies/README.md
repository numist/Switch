# Dependency Management

After a string of bad experiences over the years with:

* `git submodule`
* repositories going away
* sophisticated build tools

I have settled on the dumbest solution I can think of to solve these problems:

All of Switch's dependencies are checked into the repository.

## The Goal

People using this project should be able to get up and running with a `git clone`, `open *.xcworkspace`, and `⌘R`.

## `git` Dependencies

Switch uses:

* [Haxcessibility](https://github.com/numist/Haxcessibility), a use case–driven remote control framework for Mac apps by Mac apps

### Adding a new dependency

1. Create a file with the name of the project directory suffixed with `.giturl` that contains a URI suitable for passing to `git clone`
1. Run `update_dependencies.sh`

### Updating a dependency

1. Run `update_dependencies.sh`

### Determining dependency version

Dependencies are stored without `.git` directories, so `update_dependencies.sh` records the cloned branch and sha to `$PROJECT.gitcheckout`.

<!-- There are none yet!
## Other dependencies

Non-`git` dependencies are checked into an appropriate subdirectory of `Dependencies/` along with a `README.md` and `LICENSE` to explain their provenance.
-->
