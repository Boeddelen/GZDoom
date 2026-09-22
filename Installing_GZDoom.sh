#!/bin/bash
#
# Installing_GZDoom.sh
#
# Downloads, compiles and installs GZDoom (3.x or newer) from source on
# Fedora Linux, following the official build instructions at:
#   https://zdoom.org/wiki/Compile_GZDoom_on_Linux
#
# Usage:
#   ./Installing_GZDoom.sh
#   curl -fsSL <raw-url-to-this-script> | bash
#
# Safe to re-run: an existing source checkout is updated (git pull/fetch)
# instead of being re-cloned, and dnf simply skips packages that are
# already installed.

# Stop immediately on any error, on use of an unset variable, and make a
# failure anywhere in a pipeline (e.g. `foo | bar`) fail the whole script
# instead of being silently swallowed. This turns a broken build into a
# clear error message instead of a confusing failure several steps later.
set -euo pipefail

# --- Configuration -------------------------------------------------------

# Where the ZMusic and GZDoom source trees are checked out and built.
ZMUSIC_DIR="$HOME/zmusic_build"
GZDOOM_DIR="$HOME/gzdoom_build"

# "stable" checks out the latest tagged release (recommended - what most
# people mean by "install GZDoom"). "dev" stays on the default branch,
# i.e. the bleeding-edge development version.
# Override with:  GZDOOM_CHANNEL=dev ./Installing_GZDoom.sh
GZDOOM_CHANNEL="${GZDOOM_CHANNEL:-stable}"

# --- Helper: clone a repo, or fetch updates if it's already checked out -
# Uses fetch rather than pull so this works even if a previous run left
# the checkout on a detached commit/tag instead of a branch (see step 3).
clone_or_update() {
    local url="$1" dest="$2"
    if [ -d "$dest/.git" ]; then
        echo "Updating existing checkout: $dest"
        git -C "$dest" fetch --tags
    else
        echo "Cloning $url"
        git clone "$url" "$dest"
    fi
}

# --- 1. Install build dependencies ---------------------------------------
echo "==> Installing build dependencies via dnf"
# -y : don't wait for an interactive [y/N] prompt. This matters when the
#      script is piped into bash (curl ... | bash), because stdin is then
#      the script itself, so nothing is left to answer the prompt.
sudo dnf install -y \
    gcc-c++ make cmake SDL2-devel git zlib-devel bzip2-devel \
    libjpeg-turbo-devel fluidsynth-devel game-music-emu-devel openal-soft-devel \
    libmpg123-devel libsndfile-devel gtk3-devel timidity++ nasm \
    mesa-libGL-devel tar SDL-devel glew-devel libwebp-devel libvpx-devel

# --- 2. Build and install ZMusic (GZDoom's audio backend library) -------
echo "==> Fetching ZMusic source"
mkdir -p "$ZMUSIC_DIR"
clone_or_update "https://github.com/ZDoom/ZMusic.git" "$ZMUSIC_DIR/zmusic"
# Always build the latest commit on the upstream default branch.
git -C "$ZMUSIC_DIR/zmusic" checkout --detach origin/HEAD
mkdir -p "$ZMUSIC_DIR/zmusic/build"

echo "==> Compiling ZMusic"
cd "$ZMUSIC_DIR/zmusic/build"
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
make -j"$(nproc)"

echo "==> Installing ZMusic system-wide (into /usr)"
sudo make install

# --- 3. Fetch the GZDoom source and pick a version -----------------------
echo "==> Fetching GZDoom source"
mkdir -p "$GZDOOM_DIR"
clone_or_update "https://github.com/ZDoom/gzdoom.git" "$GZDOOM_DIR/gzdoom"
mkdir -p "$GZDOOM_DIR/gzdoom/build"
cd "$GZDOOM_DIR/gzdoom"

if [ "$GZDOOM_CHANNEL" = "stable" ]; then
    # Release tags look like "g4.14.2". Sort them as versions and take the
    # highest one, skipping the "g9999" placeholder tag used for the
    # development trunk.
    latest_tag="$(git tag -l 'g[0-9]*' | grep -v 9999 | sort -V | tail -n 1)"
    if [ -z "$latest_tag" ]; then
        echo "Warning: no stable release tag found, building the development branch instead" >&2
        git checkout --detach origin/HEAD
    else
        echo "Checking out latest stable release: $latest_tag"
        git checkout --detach "$latest_tag"
    fi
else
    echo "GZDOOM_CHANNEL=dev - using the development branch"
    git checkout --detach origin/HEAD
fi

# --- 4. Compile GZDoom ----------------------------------------------------
echo "==> Compiling GZDoom"
cd "$GZDOOM_DIR/gzdoom/build"

# Remove a plugin left over from a previous build, if any: a stale copy
# can otherwise stop cmake/make from rebuilding it against the new source.
rm -f output_sdl/liboutput_sdl.so

cmake .. -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"

echo "==> Done. GZDoom has been built at: $GZDOOM_DIR/gzdoom/build/gzdoom"

# Only auto-launch the game when a terminal is attached (i.e. run
# directly); skip it when piped in via curl | bash, or run non-interactively.
if [ -t 0 ]; then
    echo "Starting GZDoom. Prepare for the slaughter."
    "$GZDOOM_DIR/gzdoom/build/gzdoom"
fi
