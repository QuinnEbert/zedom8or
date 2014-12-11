#!/usr/bin/python
import viewsonicpjd7820hd

# Create a projector object attached to the first USB Serial port.
projector = viewsonicpjd7820hd.ViewsonicPJD7820HD('/dev/ttyUSB0')

# Turn the projector on
projector.writeCommandFromName('Power ON')

# Select the first HDMI input
#projector.writeCommandFromName('HDMI-1')

# Done watching a movie, shut it off.
#projector.writeCommandFromName('Power OFF')

