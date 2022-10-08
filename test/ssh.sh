#!/bin/sh

ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i operator -p 2222 operator@localhost
