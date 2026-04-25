<h2 align="center">
  <em>cenv</em>
</h2>
  
<p align="center">
  <em>C project generator and<br>development suite.</em>
</p>
  
<p align="center">
    <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License" />
  <img src="https://img.shields.io/github/last-commit/simon-danielsson/cenv/main?style=flat-square&color=blue" alt="Last commit" />
</p>
  
<p align="center">
  <a href="#info">Info</a> •
  <a href="#usage">Usage</a> •
  <a href="#license">License</a>
</p>  
  
---
<div id="info"></div>

## Info
  
cenv follows the philosophy that everything one needs to build and maintain a C project should exist within the codebase itself. There are no extra dependencies you need to install to use this script - the only prerequisites is git, curl and an up-to-date C compiler. The catalyst for this project was [nob.h](https://github.com/tsoding/nob.h), which cenv and my entire C development workflow is based around.
  
> [!IMPORTANT]  
> 1. cenv is heavily opinionated and built only for myself. I can't
>    guarantee that this will work properly on your computer.
> 2. My goal is to give cenv a complete development suite but I have not yet finished
>    building the tooling or setting up the signal flow (it is functional though).
  

---
<div id="usage"></div>

## Usage
  
Add the init script and the cenv binary as aliases in your `.bashrc`:  
  
``` bash
# ~/.bashrc
alias cinit="~/dev/bash/cenv/cenv-init.sh"
cenv() {
  ./cenv "$@"
}
```
  
Run in your destination folder with the project name as an argument.  
  
``` bash
cinit my_project
cd my_project
cenv help
```
 
---
<div id="license"></div>

## License
  
This project is licensed under the [MIT License](https://github.com/simon-danielsson/cenv/blob/main/LICENSE).  
 
