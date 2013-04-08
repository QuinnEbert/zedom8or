Quinn Ebert's "Pioneer Rebel" Home Theatre Control Toolkit
==========================================================

Homebrew control tools for the Pioneer VSX-1022-K (and possibly others) Home Theatre receiver (using the Telnet interface).

What's Currently Supported
==========================

* **NEW!**  Features a PHP-based interface optimized for using the Wii-U tablet controller's NetFront-based web browser for switching between my favorite inputs and powering on/off the receiver unit.  ***Note:*** *you must be able to host this on a PHP-equipped web server (probably on your home network) for it to be usable.*
* Doesn't really do much else yet.  Still working on more features/ideas!

What's Currently Planned
========================

* My "geeky goal" of the moment is to ensure my volume-control code is flexible and easy-to-use (the "reasonably usable" volume control stuff until recently has eluded me).
* Refinements to the Wii-U interface (especially adding other inputs and volume control features if-possible).
* I now have a "grand dream" to produce a "Professional" web-based interface geared towards the geek who wants fine-grained control of the VSX-1022-K from their desktop, laptop, tablet or phone.
* More stuff I can't think of at the moment I'm updating this readme...  ;-)

Software Disclaimer
===================

"Pioneer Rebel" is a software project wholly unaffiliated with Pioneer Electronics.  In no way is "Pioneer Rebel" authorized, supported, acknowledged, or endorsed by Pioneer Electronics.  FURTHERMORE, you use this software project AT YOUR OWN RISK.  The possibility indeed exists that bugs exist in this software which could lead to catastrophic failure of your Pioneer Electronics equipment.  In no event shall Quinn Ebert or Pioneer Electronics be held in any way liable for malfunction, damage, or destruction to your personal property (including but not limited to personal property created and/or manufactured by Pioneer Electronics) arising from your use of (or failure to use) this project.

Disclaimer Addendum
===================

I wish to impress that, while I feel like I risked my VSX-1022-K for my own educational benefit on this project, I have not yet bricked it or caused it any harm (to my knowledge).

This being said, I cannot stress enough, you use this software *AT YOUR OWN RISK!*  While I expect most users of my same model of receiver will have the same enjoyable experience using this that I have had while developing and using it, you *ARE* using a wholly-unsupported software product to control a piece of electronic equipment that carries a tremendous amount of electrical current through it.

In my case, I have 5 computers, a 37-inch LCD TV, and 5 game consoles (not to mention a few other pieces of networking and video-related hardware) in my combination office/theater, and between all of that, my receiver uses at least 100W more power than all of that combined at any given time.  In the event that the software were to cause the receiver to short (not that I know this is even possible mind you), you're dealing with an extreme fire hazard, among other potential safety hazards (including an electrocution hazard).

For the final time, this software is provided for your use, at your own peril.  By using this project, you agree automatically that you hold (especially) myself, not to mention Pioneer Electronics, totally non-responsible for any effects of using this project, including holding both myself and Pioneer Electronics wholly non-responsible for any damage to physical property, personal injury, or even death.

Hardware Compatibility
======================

Currently, this is only tested with, and developed against the U.S. English (American) Pioneer VSX-1022-K.  This being said, I've been told that the Telnet interface is common to many different Pioneer products; your mileage may vary.

Known Limitations
=================

* For right now, all web interfaces I add to the project come with a standard disclaimer, along the lines of "you must have a PHP-capable web server to make this interface work.  If you don't know how to do this for yourself, I can't help you unless you pay me to do an install, unless you're in my good favor, and I see fit to help you of my own volition, so tough luck (unless I'm in your debt or like you)." ;-)
* I now know how to grab the volume level of the system directly thanks to [code Mike Schaffer posted](http://xed.cc/kk), so, expect such things to be leveraged sufficiently at some point.