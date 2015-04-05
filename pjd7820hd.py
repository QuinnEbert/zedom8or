#!/usr/bin/python

# This script shows how one might implement a serial command script for a RS232-controlled device
# in my case, for example, this is a ViewSonic PJD7820HD DLP projector.

# NB: Zedom8or makes only two assumptions about these scripts (as of 2015.04.05), these are (1) Z8 assumes that
# your script accepts 'power_status' as argv[1] (assuming you have a 'power' probe on a configured device) and if
# you support this then 'power_status' causes the script to output just a 0 or a 1 indicating power off/on, and (2)
# Z8 also assumes that the PHP side should at least (somehow) consume the stdout of the script if argv[2] is equal
# to '--return' -- that said, at the time of this writing, what/how this last option is consumed and what is done
# with it is still ambiguous (I'm still working on a methodology for that which makes sense).

# Just one more pointer: I use this in my own setup on a Raspberry Pi with Nginx and PHP5-FPM.  In order for this
# script to work properly, you must add 'www-data' user to the 'dialout' group and then (in order) restart the
# 'php5-fpm' service followed by the 'nginx' service.  ;)

import viewsonicpjd7820hd
import sys
projector = viewsonicpjd7820hd.ViewsonicPJD7820HD('/dev/ttyUSB0')
if len(sys.argv)>2:
  if sys.argv[2]=='--return':
    print projector.writeCommandFromNameReadBack(sys.argv[1])
else:
  if sys.argv[1]=='power_status':
    if projector.getPower():
      print "1"
    else:
      print "0"
  elif sys.argv[1]=='input_status':
    inputStr = projector.getInput()
    if inputStr=="0x5 0x14 0x0 0x3 0x0 0x0 0x0 0x3 0x1a":
      print "HDMI"
    elif inputStr=="0x5 0x14 0x0 0x3 0x0 0x0 0x0 0x0 0x17":
      print "VGA port 1"
    elif inputStr=="0x5 0x14 0x0 0x3 0x0 0x0 0x0 0x8 0x1f":
      print "VGA port 2"
    elif inputStr=="0x5 0x14 0x0 0x3 0x0 0x0 0x0 0x5 0x1c":
      print "C-Video"
    elif inputStr=="0x5 0x14 0x0 0x3 0x0 0x0 0x0 0x6 0x1d":
      print "S-Video"
    elif inputStr=="0x0 0x0 0x0 0x0 0x0 0x0":
      print "None (unit powered off)"
    else:
      # This is a catchall based on my hands-on observations:
      print "None (unit starting up)"
  else:
    projector.writeCommandFromName(sys.argv[1])