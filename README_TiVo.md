Quinn's TiVo Development Notes
==============================

*I'm developing my stuff against a TiVo "Series 4" (as I call it).  This is one of the CableCARD-only units with 4 tuners, 1080P output support via HDMI, and the lower-end hard drive of those such models.*

STATUS (from September 2015)
----------------------------

I no longer have access to my original slice of TiVo hardware (failed hard drive I couldn't get replaced).  Future of this support is in limbo, Roamio is on my radar, but I do not know if it has any similar control support to what I was doing previously...I'm willing to pony up for the hardware if I know I can do something with it...informational tips requested from knowledgeable users (and hardware donations would not be refused but are not needed!)

If you have a Series 4 (or command set compatible) unit what's here should work for you still as far as I know.

Regrettably, this stuff for Z8 was written for the old pre-dynamic device configuration model, and it would be best effort for me to try to upgrade it.  Code donations gladly accepted from those who have the hardware to test.

Nudge Active Tuner Display Channel Up/Down:
-------------------------------------------

*This shouldn't seize the tuner in the case where all four tuners are actively recording (or so I understand it).*

+ IRCODE CHANNELDOWN
+ IRCODE CHANNELUP

Nudge Active Tuner Display Channel Directly:
-------------------------------------------

*This shouldn't seize the tuner in the case where all four tuners are actively recording (or so I understand it).*

+ SETCH 1300

Replace **1300** with the channel desired.