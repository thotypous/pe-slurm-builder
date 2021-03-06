#!/bin/bash -xe
export DEBIAN_FRONTEND=noninteractive

ulimit -n $(ulimit -Hn)

sed -i s,archive.ubuntu.com,mirror.ufscar.br,g /etc/apt/sources.list

apt-get update -y

TZ=Etc/UTC apt-get install --no-install-recommends -y git ca-certificates sudo tzdata ssh

cd
git clone https://github.com/akhilnarang/scripts
cd scripts
yes "" | ./setup/android_build_env.sh

mkdir -p ~/bin
mkdir -p ~/android/pe

curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod +x ~/bin/repo

export PATH="$HOME/bin:$PATH"

git config --global user.email "builder@domain.invalid"
git config --global user.name "Builder"

cd ~/android/pe
yes "" | repo init -u https://github.com/PixelExperience/manifest -b twelve

repo sync -j$(nproc) -c -j$(nproc) --force-sync --no-clone-bundle --no-tags

source build/envsetup.sh
lunch aosp_walleye-userdebug

croot
mka bacon -j$(nproc)
