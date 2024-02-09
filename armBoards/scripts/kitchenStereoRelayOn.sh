#! /bin/bash

GPIO_PIN=4
GPIO_MODE="$(gpio mode $GPIO_PIN out)"
GPIO_STATUS="$(gpio read $GPIO_PIN)"

if [ "$GPIO_MODE" != "1" ]; then
    gpio write $GPIO_PIN 1
fi