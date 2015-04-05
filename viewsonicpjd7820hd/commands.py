#!/usr/bin/python

"""Command set for the Viewsonic PJD7820HD Projector.

This file was automatically created by ./raw_commands_massager.py
from the source file: viewsonic_raw_commands.txt
Each command group in the documentation has a seperate list,
and all commands are available in ALL."""


######################
### Power
######################
POWER = [
  ("Power ON", "0614000400341100005D"),
  ("Power OFF", "0614000400341101005E"),
  ("STATUS Power", "071400050034000011005E"),
]
######################
### Input
######################
INPUT = [
  ("VGA 1", "06140004003413010060"),
  ("VGA 2", "06140004003413010868"),
  ("HDMI", "06140004003413010363"),
  ("Composite", "06140004003413010565"),
  ("S-Video", "06140004003413010666"),
]

ALL = POWER + INPUT
