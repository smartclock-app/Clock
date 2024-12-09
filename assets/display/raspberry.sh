#!/bin/bash

if [[ "$1" = "-q" ]]
then
  vcgencmd display_power
  exit 0
fi

if [[ "$1" = "-p" ]]
then

  if [[ "$2" = "on" ]]
  then
    vcgencmd display_power 1
  elif [ "$2" = "off" ]
  then
    vcgencmd display_power 0
  fi

else

  power=$(vcgencmd display_power)

  if [ "$power" = "display_power=1" ]
  then
    vcgencmd display_power 0
  else
    vcgencmd display_power 1
  fi

fi