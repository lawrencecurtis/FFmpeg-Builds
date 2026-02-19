# Simple Makefile that adapts to the host architecture

# Detect the host machine’s CPU family
HOST_ARCH := $(shell uname -m)

# Choose the correct platform string for the scripts
ifeq ($(HOST_ARCH),arm64)
	PLATFORM := linuxamd64   # ARM‑based machine
else
	PLATFORM := linux64      # Non‑ARM machine (x86_64, etc.)
endif

# Default target – runs both scripts with the chosen platform
default:
	@GITHUB_REPOSITORY=blackbeard-rocks/ffmpeg ./makeimage.sh $(PLATFORM) nvcc 8.0
	@GITHUB_REPOSITORY=blackbeard-rocks/ffmpeg ./build.sh $(PLATFORM) nvcc 8.0

