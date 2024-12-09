#!/bin/bash

if [[ "$1" = "-q" ]]
then
  pmset -g powerstate IODisplayWrangler | tail -1
  exit 0
fi

if [[ "$1" != "-p" ]]
then
  echo "Invalid option"
  exit 1
fi

if [[ "$2" = "on" ]]
then
  caffeinate -u -t 1
  echo "display_power=1"
elif [ "$2" = "off" ]
then
  pmset displaysleepnow
  echo "display_power=0"
fi