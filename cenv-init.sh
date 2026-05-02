#!/usr/bin/env bash
#
# cenv
  cenv_v="v0.4.2"
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

set -xe

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

# env variables ----------------------------------------------------------------

project_name="$name"
project_repo="https://github.com/simon-danielsson/\$project_name"
author="Simon Danielsson"
author_contact="contact@simondanielsson.se"
c_standard="gnu23"

root="$target_dir"

c_flags_test=(
    "-std=$c_version" "-g" "-O0" "-DDEBUG" "-fsanitize=address"
    "-Wall" "-Wextra" "-Wpedantic" "-Wshadow" "-Werror=format-security"
)

c_flags_debug=(
    "-std=$c_version" "-g" "-O0" "-DDEBUG" "-fsanitize=address" "-Wall"
    "-Wextra" "-Wpedantic" "-Wshadow" "-Werror=format-security"
)

c_flags_release=(
    "-O2" "-DNDEBUG" "-Wextra"
)

# code -------------------------------------------------------------------------

root="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
cd "\$root"

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
    "-DENV_GITTAG=\"\${VERSION}\""
    "-DENV_NAME=\"\${project_name}\""
    "-DENV_AUTHOR=\"\${author}\""
    "-DENV_CONTACT=\"\${author_contact}\""
    "-DENV_REPO=\"\${project_repo}\""
    "-std=\${c_standard}"
)

debug_dir="\$root/build/debug"; mkdir -p \$debug_dir
build_debug() {
    cd "\$root/tools/nob/" || return 1
    cc nob.c -o nob || return 1
    local c_flags=(
        "\${c_flags_debug[@]}"
        "\${nob_extra_flags[@]}"
        )
    APP_VERSION="\$VERSION" ./nob "\$root/src" "\${c_flags[@]}" || return 1
    bin_name="\$project_name-\$VERSION-debug-\$git_head_hash_short"
    mv main "\$debug_dir/\$bin_name" || return 1
    "\$debug_dir/\$bin_name"
}

test_dir="\$root/build/test"; mkdir -p \$test_dir
build_tests() {
    cd "\$root/tools/nob/" || return 1
    cc nob.c -o nob || return 1
    local c_flags=(
        "\${c_flags_test[@]}"
        "\${nob_extra_flags[@]}"
        )
    APP_VERSION="\$VERSION" ./nob "\$root/tests" "\${c_flags[@]}" || return 1
    bin_name="\$project_name-\$VERSION-test-\$git_head_hash_short"
    mv main "\$test_dir/\$bin_name" || return 1
    "\$test_dir/\$bin_name"
}

release_dir="\$root/build/release"; mkdir -p \$release_dir
build_release() {
    cd "\$root/tools/nob/" || return 1
    cc nob.c -o nob || return 1
    local c_flags=(
        "\${c_flags_release[@]}"
        "\${nob_extra_flags[@]}"
        )
    APP_VERSION="\$VERSION" ./nob "\$root/src" "\${c_flags[@]}" || return 1
    bin_name="\$project_name-\$VERSION-release-\$git_head_hash_short"
    mv main "\$release_dir/\$bin_name" || return 1
    # "\$release_dir/\$bin_name"
}

doc() {
    mkdir -p ./tools/cdok/gen
    ./tools/cdok/cdok -s ./src -d ./tools/cdok/gen -o
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
    # update cdok
    cd "\$root/tools"
    rm -rf cdok
    git clone https://github.com/simon-danielsson/cdok
    \$root/tools/cdok/run release
    mv "\$root/tools/cdok/build/release/cdok" "\$root/tools/main"
    cd \$root/tools
    zip -r cdok.zip cdok
    rm -rf cdok
    mkdir -p cdok
    mv main ./cdok/cdok
    mv cdok.zip ./cdok/cdok-src_\$current_date.zip
    printf "\\n\${col_scs}'cdok' was updated successfully!\${CR}\\n"
    cd \$root

    update_header_only_lib "ana.h" "./src/libs" "https://raw.githubusercontent.com/simon-danielsson/ana.h/refs/heads/main/ana.h"
    update_header_only_lib "nob.h" "./tools/nob" "https://raw.githubusercontent.com/tsoding/nob.h/refs/heads/main/nob.h"
}

tidy() {
    printf "Tidying up codebase...\\n"
    find . -type f \\( \
        -name ".DS_Store" -o \
        -name "nvim.log" -o \
        -name "*.o" -o \
        -name "*.obj" -o \
        -name "a.out" \
        \\) -print -delete

    find ./build/debug ./build/tests -type d -name "main.dSYM" -print -exec rm -rf {} +
    printf "Done!\\n"
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
    printf "╰ default command\\n"

    printf "\${col_cmd}cenv \${col_flag}release\${CR}\\n"
    printf "╰ compile into and run from './build/release' with optimizations\\n"

    printf "\${col_cmd}cenv \${col_flag}test\${CR}\\n"
    printf "│ compile into and run from './build/tests' directory with debug options\\n"
    printf "╰ the source folder used for this command is './tests'\\n"

    printf "\\n"

    printf "\${col_cmd}cenv \${col_subc}doc\${CR}\\n"
    printf "│ auto-generate docs from './src' and open in browser\n"
    printf "╰ this command is still in the experimental stage\n"

    printf "\${col_cmd}cenv \${col_subc}update\${CR}\\n"
    printf "│ update bundled tools and libraries from their upstream git sources\\n"
    printf "╰ user-added dependencies are safely ignored\\n"

    printf "\${col_cmd}cenv \${col_subc}tidy\${CR}\\n"
    printf "╰ clean up log, debug and object files\\n"

    printf "\${col_cmd}cenv \${col_subc}help\${CR}\\n"
    printf "╰ display help\\n"

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
    doc)
      doc
      ;;
    tidy)
      printf "\\n\${col_flag}The following files will be found and cleaned:\\n"
      printf ".DS_Store\\nnvim.log\\n*.o\\n*.obj\\na.out\\nmain.dSYM\${CR}\\n\\n"
      printf "Are you sure you want to tidy?\\n[y/n]: "
      read -r confirm

      case "\$confirm" in
        [yY]|[yY][eE][sS])
          tidy
          ;;
        *)
          echo "Tidy cancelled."
          ;;
      esac
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

chmod +x "$target_dir/cenv" || {
    error "Failed to make dev executable"
}

# generate README.md
touch "$target_dir/README.md"; echo "## $name" >> "$target_dir/README.md"

# get latest version of nob.h from repo
mkdir -p "$target_dir/tools/nob"; cd "$target_dir/tools/nob"
curl -O https://raw.githubusercontent.com/tsoding/nob.h/refs/heads/main/nob.h || {
    error "Failed to curl nob.h from the nob.h github repo"
}

# generate nob.c
touch "$target_dir/tools/nob/nob.c"
cat > "$target_dir/tools/nob/nob.c" <<EOF
#include <stdio.h>
#define NOB_IMPLEMENTATION
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"

#include "nob.h"
#include <stdlib.h>
#include <string.h>

#if defined(__APPLE__)
#include <mach-o/dyld.h>
#elif defined(__linux__)
#include <unistd.h>
#endif

char *get_executable_dir(void) {
    char path[PATH_MAX];
    size_t len = 0;

#if defined(__linux__)
    ssize_t r = readlink("/proc/self/exe", path, sizeof(path) - 1);
    if (r == -1)
        return NULL;
    path[r] = '\\0';
    len = (size_t)r;

#elif defined(__APPLE__)
    uint32_t size = sizeof(path);
    if (_NSGetExecutablePath(path, &size) != 0)
        return NULL;

    // mac can return a relative path
    char resolved[PATH_MAX];
    if (realpath(path, resolved) == NULL)
        return NULL;

    strncpy(path, resolved, sizeof(path));
    path[sizeof(path) - 1] = '\\0';
    len = strlen(path);
#endif

    // strip filename to get directory
    for (size_t i = len; i > 0; i--) {
        if (path[i] == '/') {
            path[i] = '\\0';
            break;
        }
    }

    return strdup(path); // caller must free
}

#define BINARY_NAME "main"
#define RELEASE_FOLDER "./build/release/"
#define DEBUG_FOLDER "./build/debug/"
#define TEST_FOLDER "./build/tests/"
#define TEST_SRC_FOLDER "./tests"
#define SRC_FOLDER "./src"

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

    Nob_Cmd cmd = {0};

    nob_cc(&cmd);
    nob_cc_flags(&cmd);

    // arg 1: source dir
    // everything after: flags

    // append flags
    for (int i = 2; i < argc; ++i) {
        nob_cmd_append(&cmd, argv[i]);
    }

    // build binary into in nob folder
    char target_bin[PATH_MAX];
    char *nob_dir = get_executable_dir();
    if (!nob_dir) {
        fprintf(stderr, "failed to get executable dir\\n");
        exit(1);
    }
    snprintf(target_bin, sizeof target_bin, "%s/main", nob_dir);
    nob_cmd_append(&cmd, "-o", target_bin);

    Path_List files = {0};

    nob_walk_dir(argv[1], collect_files, &files);

    for (size_t i = 0; i < files.count; i++) {
        nob_cmd_append(&cmd, files.items[i]);
    }

    if (!nob_cmd_run(&cmd))
        return 1;

    for (size_t i = 0; i < files.count; i++) {
        free(files.items[i]);
    }
    free(nob_dir);
    free(files.items);

    return 0;
}

EOF

# get latest version of analib.h from repo
mkdir -p "$target_dir/src/libs"; cd "$target_dir/src/libs"
curl -O https://raw.githubusercontent.com/simon-danielsson/ana.h/refs/heads/main/ana.h || {
    error "Failed to curl from the ana.h github repo"
}

# get latest version of cenv_toolkit from repo
cd "$target_dir/tools"
git clone --depth 1 https://github.com/simon-danielsson/cdok
cd cdok
printf "building...\n"
./run release
mv ./build/release/cdok "$target_dir/tools/cdok_bin"
cd "$target_dir/tools"
zip -r cdok.zip cdok
rm -rf cdok
mkdir -p cdok
mv cdok_bin ./cdok/cdok
mv cdok.zip ./cdok/cdok-src_$current_date.zip

# generate env.h
mkdir -p "$target_dir/src"; touch "$target_dir/src/env.h"
cat > "$target_dir/src/env.h" <<EOF

// libraries
#define ANALIB_IMPLEMENTATION
#include "./libs/ana.h"

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
#ifndef ENV_GITTAG // git release version
#define ENV_GITTAG "UNDEFINED"
#endif
#ifndef ENV_REPO // link to git repo
#define ENV_REPO "UNDEFINED"
#endif

EOF

# generate main.c
mkdir -p "$target_dir/src"; touch "$target_dir/src/main.c"
cat > "$target_dir/src/main.c" <<EOF
//! main entry point of program
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
/tools/cdok/gen
/tools/cdok/gen/*
/tools/nob/nob
nvim.log
/build
/build/*
.DS_Store
EOF

git init -b main
git add --all
git commit -m "init"
git tag v0.1.0

set +x

col_grn="\\033[1;32m"   # bold blue
col_rst="\\033[0m"      # reset

printf "\n${col_grn}Project \"$name\" was generated successfully!${col_rst}\n"
printf "\nTo get started, run the following commands:\ncd $name\ncenv help\n"

