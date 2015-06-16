<?php
// Network address where your VSX-1022-K can be reached:
$pioneer = '192.168.1.17';
// APCUPSD monitoring support...
//           false == don't support APCUPSD monitoring
//            true == support localhost APCUPSD monitoring
//   {host}:{port} == support monitoring APCUPSD remotely
// Specify your choice here:
$apcupsd = false;
// Feature to "prime" a slow Raspberry Pi before sending UIRT
// commands down the line...
//           false == do not send out a "dummy" command first
//            true == send a "dummy" command before signaling
// Specify your choice here:
$primePi = false;
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
// Specify your Z8Remote-controlled devices below:
$remDevs = array(
	'projector' => 'http://pinkiepi/Z8Remote.php'
);
?>