<?php
// Network address where your VSX-1022-K can be reached:
$pioneer = '192.168.1.17';
// APCUPSD monitoring support...
//           false == don't support APCUPSD monitoring
//            true == support localhost APCUPSD monitoring
//                    (also valid for local APCUPSD server
//                     monitoring a remote unit)
//   {host}:{port} == support monitoring APCUPSD remotely
// Specify your choice here:
$apcupsd = false;
// Feature to "prime" a slow Raspberry Pi before sending UIRT
// commands down the line...
//           false == do not send out a "dummy" command first
//            true == send a "dummy" command before signaling
// Specify your choice here ('true' should be OK for all user
// systems, but if you see it cause trouble, set to 'false'):
$primePi = true;
// Z8Remote remote command sending...
//
// This is an array with devices configured like:
//
//   $remDevs = array(
//       '<link_as>' => '<http://full.path/to/Z8Remote.php>'
//   );
//
// ...only list Z8Remote devices in this config array...
//
// Z8Remote allows you to configure different devices to be
// commanded by different devices running Z8.  Install Z8 on
// whatever device can conveniently control what you want,
// decide what Z8 copy you want to use as your control centre
// (of sorts), and then configure this array to point to the
// Z8Remote.php copy on each of those remote systems with the
// '<link_as>' value set to reference the device to control
// on the remote copy of Z8.  WARNING: you *do* need to set
// up the <link_as> Z8DevCfg on both Z8 installs so that the
// "control centre" can tell you more about the remotely
// controlled device.
//
// ADDITIONAL WARNING: Z8Remote does not yet officially have
// support for passing along status information of the remote
// device however this should be addressed soon (this warning
// was written 08 September 2015).
//
// Specify your Z8Remote-controlled devices below:
$remDevs = array(
	'projector' => 'http://pinkiepi/z8/Z8Remote.php',
    'bedroomtv' => 'http://dashiepi/z8/Z8Remote.php',
);
?>