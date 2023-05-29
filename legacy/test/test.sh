#!/bin/sh
cat /dev/zero | ssh-keygen -q -N "" -f operator
nix-build `dirname $0` --argstr machine $1 &&
  QEMU_NET_OPTS=hostfwd=tcp::2222-:22 ./result/bin/run-$1-vm
