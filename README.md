Z8: reasonable-cost home automation!
========

Using a combination of [PioneerRebel](https://github.com/QuinnEbert/PioneerRebel "PioneerRebel") *(and a compatible receiver)*, [USB-UIRT](http://www.usbuirt.com "USB-UIRT"), [LIRC](http://www.lirc.org "LIRC"), and more, **Z8** aims to produce a low-effort, reasonable-cost home automation package.

***Hey!  Zedom8or is now Z8 (Zed Eight): same repo, improving code, now with a focus on whole-home automation!***
***Hey, I'm not done!  I've finally significantly updated this document (on 05 September 2015)!***

Solid(ish) Features:
--------------------

* ***Tested on Raspberry Pi as a primary platform (both original model B and Raspberry Pi 2).***
* Web-based interface for control.
* Manage Pioneer VSX-1022-K/VSX-1023-K (and compatible) Telnet-controllable home theatre amplifier systems.
* Backend scripts for integrating control of serial-controllable display systems (examples based on my in-home config with a ViewSonic DLP).
* Monitor APCUPSD-compatible UPS battery backup systems in the web interface.

Working Features Still Seeing Heavy Changes:
--------------------------------------------

+ A new `Z8DevCfg.php` file that you can now fully configure to have Z8 fully understand your home automation system.  *The format with this should stay relatively stable but expect a lot more to be added.*
+ Along with `Z8DevCfg.php` comes a still-in-flux system for extending Z8 with your own PHP classes and backend control scripts.  *Feel free to develop against this now, but, expect some changes to how things work over the next 3-4 months or so.*
+ A JSON-outputting API on `/endpoint` that you can use to control your Z8 system from, well, whatever your heart desires.  *The API is growing quickly, but I don't expect to break anything major yet, so don't worry too much about writing things against this!*
+ Working code that demonstrates simple control of your Z8 system on Apple Watch.  *This uses the API mentioned above, right now though, it only does volume control and some minimal status display--this HAS been tested on real hardware!*

Fun Things that Need More Work Someday(TM):
-------------------------------------------

+ A handful of R&D-quality utilities (such as my favorite, a series of apps that monitor audio levels in your theatre space, and attempt to auto-level your receiver to compensate (great if your ears are bad like mine).
+ Probably a tonne of other odds and ends I've forgotten.  :-(

Plans
-----

* One loaded word: "Alexa"
* I will receive access to Phillips Hue and various WeMo hardware around 15 October 2015, if those are as hackable as I've been told, all I can say is, keep an eye out in that timeframe. ;-)
* Leverage your self-learned USB-UIRT remote commands to automate command sequences, de-complicating your theatre enjoyment.

Code Maturity
-------------

The code is very mature for the web UI (but will merit a design refresh sometime soon-ish), for developers the support for device control with your own PHP classes is "basically there," serial device control spec is reasonably solid, LIRC is undergoing a design change to make sense for dynamic home device reconfiguration (but the spec in my head is fairly solid and DevCfg examples are coming any day now), Philips Hue / WeMo / the R&D experiments are the real minefields here right now.

Documentation
-------------

Where feasible, code in Z8 is commented to attempt to provide you with as much assistance as possible while not overwhelming skilled developers, in addition, efforts are beginning to PHPDoc everything to compliance with phpcs's manic standards.  For less-developer-minded end users, Z8 intends to soon become much more user-friendly, and I have future plans to provide Z8 consultation, support, and maintenance services for the users who require additional assistance to get and keep things moving along smoothly.

On-Hold Plans
-------------

* 3D-printable (tested on Solidoodle 2) STL model files for printable cases that can be used to better situate and arrange your R-Pi and/or USB-UIRT.  *The Solidoodle didn't work out, and if you do some searching about customer experiences working with the company, it becomes obvious why--I'll be getting a different printer by November 2015 and should be able to get this plan moving forward again.*

Donations
------

There has been a lot more interest in Zedom8or/PioneerRebel than I'd ever expected.  If you like what I'm doing, please consider donating:

[Donate Now](http://quinnebert.net/z8donate/)

Status
------

**08th Sep, 2015:**

* Zedom8or is now officially called "Z8" (pronounced "Zed Eight").  The repository will remain the same and reasonable documentation/code updates will be happening ASAP to reduce confusion as much as possible.
* Further improved this document.
* Made some small changes to config defaults and produced a preliminary example in Z8DevCfg for LIRC device support with external commands to probe statuses.

**05th Sep, 2015:**

* Improved this document somewhat (there have been several commits since my last update of this doc, mind you!)

**01st Mar, 2015:**

* *Trying to pick back up with this project after a couple of full-time job changes (gotta love startups), a move out of my home state, and a few months of dealing with some health issues.*
* Posted a "proposed" `Z8DevCfg.php` file to try to start to put together a "reconfigurable" way of having devices appear in the web interface (yeah, I know this has taken waaay too long to get around to).
* Since I last updated this doc section, of note, I have added (based on a fork) a RS232-based way of beginning to control esp. serial-controllable projectors (and such).
* Also, since I last updated this doc section, I have lost access to a functional 3D printer (I have plans to rectify this late in the summer).  Once that's dealt with I hope to start iterating properly on case designs (again, after far too long).

**08th Apr, 2013:**

* ***My USB-UIRT is scheduled to deliver today, hope to get in some dev time with it, in the late evening.***
* Cleaned up styling on various pages for total/near-total consistency (esp. less inline styles).
* Updated this README file.
* Drafted COPYRIGHT file, solely for the commissioned logo (for now).

**07th Apr, 2013:**

* Got a tonne done with the web UI stuff (already have functional status info and VSX-1022-K power-on/off).

**06th Apr, 2013:**

* Updated the README a good bit.

**05th Apr, 2013:**

* Created the project repo, currently empty (besides this README document).
* *Awaiting my USB-UIRT to begin tinkering.*
