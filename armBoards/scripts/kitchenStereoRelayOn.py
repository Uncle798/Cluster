#!/usr/bin/env python3

import os
import lgpio

speaker_on = os.environ.get("SPEAKER")
relay =   23# pin num
chip = lgpio.gpiochip_open(0)
lgpio.gpio_claim_output(chip, relay)

try:
    while speaker_on:
        lgpio.gpio_write(chip, relay, 1)
finally:
    lgpio.gpio_write(chip, relay, 0)
    lgpio.gpiochip_close(chip)