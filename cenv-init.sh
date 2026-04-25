#!/usr/bin/env bash
#
# cenv
  cenv_v="v0.2.7"
#
# Copyright © 2026 Simon Danielsson
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files, to deal in the Software
# without restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of the
# Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#

set -e

error() {
    echo "[ERROR] - $1"; exit 1
}

# Usage check
if [ -z "$1" ]; then
    echo "$ ./cenv-init.sh <project_name>"
    exit 1
fi

name="$1"
target_dir="$(pwd -P)/$name"
current_date=$(date +"%F")

if [ -e "$target_dir" ]; then
    error "Directory already exists: $target_dir"
fi

mkdir -p "$target_dir"

# generate run (build script)
touch "$target_dir/cenv"
cat > "$target_dir/cenv" <<EOF
#!/usr/bin/env bash
# =============================================================================
# cenv (https://github.com/simon-danielsson/cenv)
# $cenv_v
#
# Copyright © 2026 Simon Danielsson
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files, to deal in the Software
# without restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of the
# Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

# =============================================================================
# ENVIRONMENT VARIABLES (avoid spaces inside values)

project_name="$name"
project_repo="https://github.com/simon-danielsson/\$project_name"
author="Simon_Danielsson"
author_contact="contact@simondanielsson.se"
c_standard="gnu23"

# =============================================================================
# CODE

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
cd "\$SCRIPT_DIR"

mkdir -p build
mkdir -p build/release
mkdir -p build/debug
mkdir -p build/tests

col_scs="\\033[1;32m"   # bold green
col_cmd="\\033[1;34m"   # bold blue
col_subc="\\033[1;33m"   # bold yellow
col_git="\\033[1;36m"   # bold cyan
col_flag="\\033[1;31m"   # bold red
CR="\\033[0m"      # reset

current_date=\$(date +"%F")

latest_git_commit=\$(git log -1 --format='%ad' --date=format:'%d %b %Y')
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    git_head_hash_short=\$(git rev-parse --short HEAD)
    git_head_hash_long=\$(git rev-parse HEAD)
else
    git_head_hash_short="nogit"
    git_head_hash_long="0.0.0"
fi

get_version() {
    git describe --tags --abbrev=0 2>/dev/null || echo "v0.1.0"
}
VERSION="\$(get_version)"

nob_extra_flags=(
  "-DENV_GITHASH=\"\${git_head_hash_long}\""
  "-DENV_GITVERSION=\"\${VERSION}\""
  "-DENV_NAME=\"\${project_name}\""
  "-DENV_AUTHOR=\"\${author}\""
  "-DENV_CONTACT=\"\${author_contact}\""
  "-DENV_REPO=\"\${project_repo}\""
  "-std=\${c_standard}"
)

build_release() {
    printf "Compiling release build (%s)...\\n" "\$VERSION"
    cc -o ./tools/nob/nob ./tools/nob/nob.c
    APP_VERSION="\$VERSION" ./tools/nob/nob release \${nob_extra_flags[*]}
    mv ./build/release/main ./build/release/\$project_name-\$VERSION-\$git_head_hash_short
    ./build/release/\$project_name-\$VERSION-\$git_head_hash_short
}

build_debug() {
    printf "Compiling debug build (%s)...\n" "\$VERSION"
    cc -o ./tools/nob/nob ./tools/nob/nob.c
    APP_VERSION="\$VERSION" ./tools/nob/nob debug \${nob_extra_flags[*]}
    mv ./build/debug/main ./build/debug/\$project_name-DEBUG-\$VERSION-\$git_head_hash_short
    ./build/debug/\$project_name-DEBUG-\$VERSION-\$git_head_hash_short

}

build_tests() {
    printf "Compiling tests (%s)...\n" "\$VERSION"
    cc -o ./tools/nob/nob ./tools/nob/nob.c
    APP_VERSION="\$VERSION" ./tools/nob/nob test \${nob_extra_flags[*]}
    mv ./build/tests/main ./build/tests/\$project_name-TEST-\$VERSION-\$git_head_hash_short
    ./build/tests/\$project_name-TEST-\$VERSION-\$git_head_hash_short
}

tag() {
    if [ -z "\$1" ]; then
        echo "Usage: tag <version>"
        return 1
    fi
    git tag -a "\$1" -m "\$1"
}

todo() {
    ./tools/jobb/jobb ./src
    ./tools/jobb/jobb ./tests
}

update_header_only_lib() {
    lib_name="\$1"; lib_path="\$2"; lib_repo_raw="\$3"; root=\$(pwd)
    cd "\$lib_path"
    mv \$lib_name \$lib_name.bak
    printf "\\nFetching latest version of \$lib_name...\\n"
    curl -O \$lib_repo_raw || {
        error "Failed to curl \$lib_name from the \$lib_name github repo"
    }
    if [ -f "\$lib_name" ]; then
        rm \$lib_name.bak
        printf "\\n\${col_scs}'\$lib_name' was updated successfully!\${CR}\\n"
    else
        mv \$lib_name.bak \$lib_name
        printf "\\n\${col_flag}'\$lib_name' couldn't be updated!\${CR}\\n"
    fi
    cd \$root
}

update() {
    update_header_only_lib "stb_sprintf.h" "./libs" "https://raw.githubusercontent.com/nothings/stb/refs/heads/master/stb_sprintf.h"
    update_header_only_lib "analib.h" "./libs" "https://raw.githubusercontent.com/simon-danielsson/analib.h/refs/heads/main/analib.h"
    update_header_only_lib "nob.h" "./tools/nob" "https://raw.githubusercontent.com/tsoding/nob.h/refs/heads/main/nob.h"
}

doc() {
    ./tools/cdok/cdok ./src
}

restore() {
    git reset --hard HEAD
    git clean -fdx
}

help() {
    printf "\\n"
    printf "Project name     :  \$project_name\\n"
    printf "Current version  :  \$VERSION\\n"
    printf "Latest commit    :  \$latest_git_commit\\n"
    printf "First created    :  $(date +"%d %b %Y")\\n"
    printf "C Standard       :  \$c_standard\\n"

    printf "\\n"

    printf "\${col_cmd}cenv \${col_flag}debug\${CR}\\n"
    printf "│ compile into and run from './build/debug' with debug options\\n"
    printf "╰ if the 'run' command is ran without flags, it defaults to the debug build\\n"

    printf "\${col_cmd}cenv \${col_flag}release\${CR}\\n"
    printf "╰ compile into and run from './build/release' with optimizations\\n"

    printf "\${col_cmd}cenv \${col_flag}test\${CR}\\n"
    printf "│ compile into and run from './build/tests' directory with debug options\\n"
    printf "╰ the source folder used for this command is './tests'\\n"

    printf "\\n"

    printf "\${col_cmd}cenv \${col_subc}doc\${CR}\\n"
    printf "│ (./tools/cdok) auto-generate docs from './src' and open in browser\\n"
    printf "╰ not implemented yet...\\n"

    printf "\${col_cmd}cenv \${col_subc}todo\${CR}\\n"
    printf "╰ (./tools/jobb) find 'TODO' statements in codebase\\n"

    printf "\${col_cmd}cenv \${col_subc}update\${CR}\\n"
    printf "│ update libraries\\n"
    printf "│ *(tool binaries are updated manually to avoid breaking changes\\n"
    printf "│ screwing up the codebase - this will be solved in the future by\\n"
    printf "╰ supplying an in-house tooling binary that can be more regulated)\\n"

    printf "\${col_cmd}cenv \${col_subc}help\${CR}\\n"
    printf "╰ display help\\n"

    printf "\\n"

    printf "\${col_cmd}cenv \${col_git}restore\${CR}\\n"
    printf "╰ (git) force hard restore to latest commit\\n"

    printf "\${col_cmd}cenv \${col_git}tag <version>\${CR}\\n"
    printf "│ (git) create new annotated tag\\n"
    printf "╰ ex.: run tag v1.2.1\\n"
    printf "\\n"
}

if [ -z "\$1" ]; then
    # if no arguments
  build_debug
else
  case "\$1" in
    release)
      build_release
      ;;
    debug)
      build_debug
      ;;
    test)
      build_tests
      ;;
    help)
      help
      ;;
    todo)
      todo
      ;;
    tag)
      tag "\$2"
      ;;
    doc)
      doc
      ;;
    restore)
      restore
      ;;
    update)
      printf "\\n\${col_flag}You're about to run an update which can break\\n"
      printf "your setup or introduce unwanted changes!\\n"
      printf "Make a commit to git before continuing.\${CR}\\n\\n"
      printf "Are you sure you want to run an update?\\n[y/n]: "
      read -r confirm

      case "\$confirm" in
        [yY]|[yY][eE][sS])
          update
          ;;
        *)
          echo "Update cancelled."
          ;;
      esac
      ;;

    *)
      echo "Error: unknown argument '\$1'"
      exit 1
      ;;
  esac
fi

EOF

# make dev executable
chmod +x "$target_dir/cenv" || {
    error "Failed to make dev executable"
}

# generate README.md
touch "$target_dir/README.md"; echo "## $name" >> "$target_dir/README.md"

# get latest version of nob.h from repo
mkdir -p "$target_dir/tools/nob"; cd "$target_dir/tools/nob"
curl -O https://raw.githubusercontent.com/tsoding/nob.h/refs/heads/main/nob.h || {
    error "Failed to curl nob.h from the nob.h github repo"
mkdir
}

# generate nob.c
touch "$target_dir/tools/nob/nob.c"
cat > "$target_dir/tools/nob/nob.c" <<EOF

#define NOB_IMPLEMENTATION
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"

#include "nob.h"
#include <stdlib.h>
#include <string.h>

#define BINARY_NAME "main"
#define RELEASE_FOLDER "./build/release/"
#define DEBUG_FOLDER "./build/debug/"
#define TEST_FOLDER "./build/tests/"
#define SRC_FOLDER "./src"
#define TEST_SRC_FOLDER "./tests"

typedef struct {
    char **items;
    size_t count;
    size_t capacity;
} Path_List;

static bool has_c_extension(const char *path) {
    size_t len = strlen(path);
    return len >= 2 && strcmp(path + len - 2, ".c") == 0;
}

static void path_list_append(Path_List *arr, const char *str) {
    if (arr->count >= arr->capacity) {
        size_t new_cap = arr->capacity == 0 ? 8 : arr->capacity * 2;
        char **new_items = realloc(arr->items, new_cap * sizeof(char *));
        NOB_ASSERT(new_items != NULL);
        arr->items = new_items;
        arr->capacity = new_cap;
    }
    arr->items[arr->count++] = strdup(str);
    NOB_ASSERT(arr->items[arr->count - 1] != NULL);
}

static bool collect_files(Nob_Walk_Entry entry) {
    Path_List *arr = (Path_List *)entry.data;
    if (entry.type == FILE_REGULAR && has_c_extension(entry.path)) {
        path_list_append(arr, entry.path);
    }
    return true;
}

int main(int argc, char **argv) {
    NOB_GO_REBUILD_URSELF(argc, argv);

    bool debug = false;
    bool release = false;
    bool test = false;

    Nob_Cmd cmd = {0};

    nob_cc(&cmd);
    nob_cc_flags(&cmd);

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "debug") == 0) {
            debug = true;
        } else if (strcmp(argv[i], "release") == 0) {
            release = true;
        } else if (strcmp(argv[i], "test") == 0) {
            test = true;
        } else if (i > 1) {
            // load user flags from cenv script
            nob_cmd_append(&cmd, argv[i]);
        }
    }

    if (debug || test) {
        nob_cmd_append(&cmd, "-g", "-O0", "-DDEBUG", "-fsanitize=address",
                "-Wall", "-Wextra", "-Wpedantic",
                "-Wshadow", "-Werror=format-security");
    }

    if (debug) {
        nob_cmd_append(&cmd, "-o", DEBUG_FOLDER BINARY_NAME);
    }

    if (test) {
        nob_cmd_append(&cmd, "-o", TEST_FOLDER BINARY_NAME);
    }

    if (release) {
        nob_cmd_append(&cmd, "-O2", "-DNDEBUG", "-Wextra");
        nob_cmd_append(&cmd, "-o", RELEASE_FOLDER BINARY_NAME);
    }

    Path_List files = {0};
    if (test) {
        nob_walk_dir(TEST_SRC_FOLDER, collect_files, &files);
    }

    if (debug || release) {
        nob_walk_dir(SRC_FOLDER, collect_files, &files);
    }

    for (size_t i = 0; i < files.count; i++) {
        nob_cmd_append(&cmd, files.items[i]);
    }

    if (!nob_cmd_run(&cmd))
        return 1;

    for (size_t i = 0; i < files.count; i++) {
        free(files.items[i]);
    }
    free(files.items);

    return 0;
}
EOF

# get latest version of analib.h from repo
mkdir -p "$target_dir/libs"; cd "$target_dir/libs"
curl -O https://raw.githubusercontent.com/simon-danielsson/analib.h/refs/heads/main/analib.h || {
    error "Failed to curl from the analib.h github repo"
}

# get latest version of stb_sprintf.h from repo
mkdir -p "$target_dir/libs"; cd "$target_dir/libs"
curl -O https://raw.githubusercontent.com/nothings/stb/refs/heads/master/stb_sprintf.h || {
    error "Failed to curl from the stb_sprintf.h github repo"
}

# get latest version of cdok from repo
# cd "$target_dir/tools"
# git clone --depth 1 https://github.com/simon-danielsson/cdok
# cd cdok
# printf "building...\n"
# ./run release
# mv ./build/release/* $target_dir/tools/main
# cd "$target_dir/tools"
# zip -r cdok.zip cdok
# rm -rf cdok
# mkdir -p cdok
# mv main ./cdok/cdok
# mv cdok.zip ./cdok/cdok-src_$current_date.zip
#
# # get latest version of jobb from repo
# cd "$target_dir/tools"
# git clone --depth 1 https://github.com/simon-danielsson/jobb
# cd jobb
# ./dev compile
# mv ./build/main ..
# cd "$target_dir/tools"
# zip -r jobb.zip jobb
# rm -rf jobb
# mkdir -p jobb
# mv main ./jobb/jobb
# mv jobb.zip ./jobb/jobb-src_$current_date.zip
#
# generate main.h
mkdir -p "$target_dir/src"; touch "$target_dir/src/env.h"
cat > "$target_dir/src/env.h" <<EOF

// libraries
#define ANALIB_IMPLEMENTATION
#include "../libs/analib.h"
#define STB_SPRINTF_IMPLEMENTATION
#include "../libs/stb_sprintf.h"

// standard libraries
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

// diagnostics
#pragma GCC diagnostic ignored "-Wunused-variable"

// define environment variables with fallbacks
// (these are overridden and expanded at compile-time)
#ifndef ENV_NAME // project name
#define ENV_NAME "UNDEFINED"
#endif
#ifndef ENV_AUTHOR // author of this project
#define ENV_AUTHOR "UNDEFINED"
#endif
#ifndef ENV_CONTACT // contact info to author
#define ENV_CONTACT "UNDEFINED"
#endif
#ifndef ENV_GITHASH // git hash
#define ENV_GITHASH "UNDEFINED"
#endif
#ifndef ENV_GITVERSION // git release version
#define ENV_GITVERSION "UNDEFINED"
#endif
#ifndef ENV_REPO // link to git repo
#define ENV_REPO "UNDEFINED"
#endif

EOF

# generate main.c
mkdir -p "$target_dir/src"; touch "$target_dir/src/main.c"
cat > "$target_dir/src/main.c" <<EOF
#include "env.h"

// TODO: write a program
int main(void) {
    printf("Hello, %s!", ENV_AUTHOR);
    return 0;
}
EOF

# generate tests folder
mkdir -p "$target_dir/tests"; touch "$target_dir/tests/test_main.c"
cat > "$target_dir/tests/test_main.c" <<EOF
#include "../src/env.h"

// TODO: write a test
int main(void) {
    printf("this is a test");
    return 0;
}
EOF

# generate license
touch "$target_dir/LICENSE"
cat > "$target_dir/LICENSE" <<EOF
Copyright © $(date +"%Y") Simon Danielsson

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files, to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
EOF

# initalize git
cd "$target_dir"; touch "$target_dir/.gitignore"
cat > "$target_dir/.gitignore" <<EOF
build.sh
nob/nob
nvim.log
/build
/build/*
.DS_Store
EOF

git init -b main
git add --all
git commit -m "init"
git tag v0.1.0

col_grn="\\033[1;32m"   # bold blue
col_rst="\\033[0m"      # reset

printf "\n${col_grn}Project \"$name\" was generated successfully!${col_rst}\n"
printf "\nTo get started, run the following commands:\ncd $name\ncenv help\n"

