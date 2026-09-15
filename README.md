# GZDoom

A bash script which downloads, compiles and installs GZDoom on Fedora Linux.

## Install (one-liner)

```sh
curl -fsSL https://raw.githubusercontent.com/Boeddelen/GZDoom/main/Installing_GZDoom.sh | bash
```

This builds ZMusic and the latest **stable** GZDoom release from source and
installs it under `~/gzdoom_build`. It takes a while (it's compiling a game
engine), and it's safe to run more than once.

To build the bleeding-edge development version instead of the latest stable
release, set `GZDOOM_CHANNEL=dev`:

```sh
curl -fsSL https://raw.githubusercontent.com/Boeddelen/GZDoom/main/Installing_GZDoom.sh | GZDOOM_CHANNEL=dev bash
```

## Manual use

```sh
git clone https://github.com/Boeddelen/GZDoom.git
cd GZDoom
chmod +x Installing_GZDoom.sh
./Installing_GZDoom.sh
```

The built binary ends up at `~/gzdoom_build/gzdoom/build/gzdoom`.
