#!/bin/bash

export DISPLAY=:0
xset s noblank

if [[ "$1" = "-q" ]]
then
  power=$(xset q | tail -1)

  if [ "$power" = "  Monitor is On" ]
  then
    echo "display_power=1"
  else
    echo "display_power=0"
  fi

  exit 0
fi

if [[ "$1" = "-p" ]]
then

  if [[ "$2" = "on" ]]
  then
    xset dpms force on
  elif [ "$2" = "off" ]
  then
    xset dpms force off
  fi

else

  power=$(xset q | tail -1)

  if [ "$power" = "  Monitor is On" ]
  then
    xset dpms force off
  else
    xset dpms force on
  fi

fi