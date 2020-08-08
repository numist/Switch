# Dependency Management

Unlike dynamic linking of binaries, weak associations between source projects provide no benefit and ask developers to shoulder a large amount of complexity. After a string of bad experiences over the years with `git submodule`, repositories going away, and using build tools to manage dependencies I have settled on the dumbest solution I can think of: all dependencies are checked into the repository and a shell script is the first line treatment for keeping them up to date. 

The goal? People using this project should be able to get up and running with nothing more than a `git clone` of this project and a `⌘R` in Xcode.

## Adding Dependencies

1) Create a file with the name of the project directory suffixed with `.giturl` that contains a URI suitable for passing to `git clone`
2) Run `update_dependencies.sh`

## Updating Dependencies

2) Run `update_dependencies.sh`

## Determining Dependency Version

For simplicity, dependencies are stored without `.git` directories, stripping them of their SCM metadata. `update_dependencies.sh` writes the updated branch and sha to `$PROJECT.gitcheckout` for posterity.
