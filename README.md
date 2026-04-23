<h2 align="center">
  <em>cinit.sh</em>
</h2>
  
<p align="center">
  <em>Tiny C project generator</em>
</p>
  
<p align="center">
    <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License" />
  <img src="https://img.shields.io/github/last-commit/simon-danielsson/jobb/main?style=flat-square&color=blue" alt="Last commit" />
</p>
  
<p align="center">
  <a href="#info">Info</a> •
  <a href="#usage">Usage</a> •
  <a href="#license">License</a>
</p>  
  
---
<div id="info"></div>

## Info
  
cinit.sh follows the philosophy that everything one needs to build and maintain a C project should exist within the codebase itself. There are no extra dependencies you need to install to use this script - the only prerequisite is an up-to-date C compiler. The catalyst for this project was [nob.h](https://github.com/tsoding/nob.h), which cinit.sh and my entire C development workflow is based around.
  
> [!IMPORTANT]  
> 1. cinit.sh is heavily opinionated and built only for myself.
> 2. My goal is to give cinit.sh a complete development suite but I have not yet finished
>    building the tooling or setting up the signal flow (it is functional though).
  

---
<div id="usage"></div>

## Usage
  
Add cinit.sh as an alias in your `.bashrc`:  
  
``` bash
# ~/.bashrc
alias cinit="~/dev/bash/cinit/cinit.sh"
```
  
Run in your destination folder with the project name as an argument.  
  
``` bash
# ~/.bashrc
cinit my_project
```
 
---
<div id="license"></div>

## License
  
This project is licensed under the [MIT License](https://github.com/simon-danielsson/cinit.sh/blob/main/LICENSE).  
 
