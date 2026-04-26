<p align="center">
    <img src="media/logo.png" alt="cenv" width="200"/>
</p>

<p align="center">
  <em>C without ceremony.</em>
</p>
  
<p align="center">
    <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License" />
  <img src="https://img.shields.io/github/last-commit/simon-danielsson/cenv/main?style=flat-square&color=blue" alt="Last commit" />
</p>
  
<p align="center">
  <a href="#info">Info</a> •
  <a href="#install">Install</a> •
  <a href="#usage">Usage</a> •
  <a href="#license">License</a>
</p>  
  
---
<div id="info"></div>

## Info
  
The main philosophy of cenv is that everything required to build and maintain a C project should exist within the codebase itself. It is a opinionated development environment built for developing small/medium sized C projects fast and iteratively.
  
Prerequisites:  
- git  
- curl  
- a C compiler  
  
> [!IMPORTANT]  
> 1. No support for Windows.
> 2. Since cenv is heavily opinionated and built for my own specific workflow, I can't
> guarantee that this will function properly on your computer.
  

---
<div id="install"></div>

## Install
  
Clone [cenv-init.sh](./cenv-init.sh) and add it as an alias in your `.bashrc`:  
  
``` bash
# ~/.bashrc

# cinit script
alias cinit="$HOME/path/to/cenv-init.sh"

# this function is to make the cenv build script 
# easier to run within generated projects 
cenv() {
  ./cenv "$@"
}
```
  
---
<div id="usage"></div>
  
## Usage
  
Run cinit in your destination folder with the project name as an argument, then run the help command to get started:  
  
``` bash
cinit my_project
cd my_project
cenv help
```
 
When you run `cenv help` you will see the following commands:

``` terminal

cenv debug
│ compile into and run from './build/debug' with debug options
╰ if 'cenv' is ran without flags, it defaults to the debug build
cenv release
╰ compile into and run from './build/release' with optimizations
cenv test
│ compile into and run from './build/tests' directory with debug options
╰ the source folder used for this command is './tests'

cenv doc
│ auto-generate docs from './src' and open in browser
╰ this command is still in the experimental stage
cenv todo
╰ find and print all 'TODO' statements in codebase
cenv update
│ update bundled cenv tools and header-only libraries from their
╰ known upstream git sources - user-added dependencies are safely ignored
cenv help
╰ display help

cenv restore
╰ (git) HARD reset to latest commit
cenv tag <version>
│ (git) create new annotated tag
╰ ex.: run tag v1.2.1

```
 
---
<div id="license"></div>

## License
  
This project is licensed under the [MIT License](https://github.com/simon-danielsson/cenv/blob/main/LICENSE).  
 
