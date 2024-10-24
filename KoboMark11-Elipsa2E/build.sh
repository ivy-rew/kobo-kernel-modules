#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

fetch(){
  if [ ! -f "kernel.tar.bz2" ]; then
    wget https://raw.githubusercontent.com/kobolabs/Kobo-Reader/refs/heads/master/hw/mt8113-elipsa2e/kernel.tar.bz2.partaa
    wget https://raw.githubusercontent.com/kobolabs/Kobo-Reader/refs/heads/master/hw/mt8113-elipsa2e/kernel.tar.bz2.partab
    cat kernel.tar.bz2.parta* > kernel.tar.bz2
    echo "unpacking"
    tar xf kernel.tar.bz2
  fi
}

gcc="gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf"
linearo(){
  if [ ! -d "$gcc" ]; then
    wget https://releases.linaro.org/components/toolchain/binaries/4.9-2017.01/arm-linux-gnueabihf/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz
    echo "unpacking"
    tar xf "${gcc}.tar.xz"
  fi
}

kernel="$DIR/kernel/linux/v4.9"
compiler="$DIR/${gcc}/bin/arm-linux-gnueabihf-"
alias builder="make ARCH=arm CROSS_COMPILE=$compiler"

config(){
  if [ ! -f "$kernel/.config" ]; then
    cp $DIR/.config $kernel
    cd $kernel
    builder oldconfig
  fi
}

patch(){
  echo "patching"
  sed -E -i 's|^YYLTYPE yylloc;|extern YYLTYPE yylloc;|g' "$kernel/scripts/dtc/dtc-lexer.lex.c"
  silence
}

silence(){
  echo "muting"
  broken=(
    drivers/devfreq
    drivers/misc/mediatek/emi/mt8512
    drivers/misc/mediatek/emi/mt8512/../emi_ctrl_common
    drivers/misc/mediatek/emi/mt8512/../submodule_common
    drivers/misc/mediatek/hwtcon
    drivers/misc/mediatek/hwtcon/hal
    drivers/misc/mediatek/leds
    drivers/misc/mediatek/leds/mt8512
    drivers/misc/mediatek/thermal
    drivers/misc/mediatek/thermal/mt8512
    drivers/misc/mediatek/pmic/fiti
  )

  for brokePat in ${broken[@]}; do
    for broke in $kernel/$brokePat/*.c; do
      first=$(head -n1 $broke)
      if [[ "$first" != "//off" ]]; then
        cp -v $broke $broke.bkp
        echo "//off" > $broke 
      fi
    done
  done
}

build(){
  cd $kernel
  builder
}

modules(){
  sudo apt install libncurses-dev libncursesw-dev
  builder menuconfig
}

prepare(){
  fetch
  linearo
  config
  patch
}

prepare
build
