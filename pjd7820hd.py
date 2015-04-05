#!/usr/bin/python
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
  else:
    projector.writeCommandFromName(sys.argv[1])