Quinn's TiVo Development Notes
==============================

*I'm developing my stuff against a TiVo "Series 4" (as I call it).  This is one of the CableCARD-only units with 4 tuners, 1080P output support via HDMI, and the lower-end hard drive of those such models.*

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