<?php
// Network address where your VSX-1022-K can be reached:
$pioneer = '192.168.1.17';
// APCUPSD monitoring support...
//           false == don't support APCUPSD monitoring
//            true == support localhost APCUPSD monitoring
//   {host}:{port} == support monitoring APCUPSD remotely
// Specifiy your choice here:
$apcupsd = 'rashtaka:3551';
// Feature to "prime" a slow Raspberry Pi before sending UIRT
// commands down the line...
//           false == do not send out a "dummy" command first
//            true == send a "dummy" command before signaling
// Specifiy your choice here:
$primePi = true;
?>