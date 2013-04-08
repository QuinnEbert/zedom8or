<!--
 ssCommon.php
 part of Quinn Ebert's "Pioneer Rebel" software project
 
 PURPOSE:
   Common server-side code utilities used by the various
   interfaces in the PioneerRebel Project.
 -->
<?php
/*
  CONFIGURATION:
  
  Set the IP or hostname of your VSX-1022-K below, indicate if you want the
  alert to successful command send dialog to appear, and enjoy!
*/
// Network address where your VSX-1022-K can be reached:
if ( ! isset($pioneer) ) $pioneer = '192.168.1.Xyz';
// ^ Let $pioneer be overridden by external apps (like Zedom8or/"Z8"):
if (isset($_GET['pioneer'])) $pioneer = $_GET['pioneer'];
// Set this to indicate if you want an alert message to show up confirming
// the command was sent to the VSX-1022-K unit:
// 
// POSSIBLE SETTINGS:
//    true : confirmation alert will display
//   false : confirmation alert won't display
$confirm = true;

// Handling code for Ajax button requests:
if (isset($_GET['volDn'])) {
	require_once(dirname(__FILE__).'/pioneer.lib.php');
	header('Content-Type: text/xml');
	pvRebel_setVolDec($pioneer);
	die("<pioneer_rebel>\n  <status>OK</status>\n</pioneer_rebel>\n");
}
if (isset($_GET['volUp'])) {
	require_once(dirname(__FILE__).'/pioneer.lib.php');
	header('Content-Type: text/xml');
	pvRebel_setVolInc($pioneer);
	die("<pioneer_rebel>\n  <status>OK</status>\n</pioneer_rebel>\n");
}
if (isset($_GET['input'])) {
	require_once(dirname(__FILE__).'/pioneer.lib.php');
	header('Content-Type: text/xml');
	pvRebel_setSource($pioneer,$_GET['input']);
	die("<pioneer_rebel>\n  <status>OK</status>\n</pioneer_rebel>\n");
}
if (isset($_GET['power'])) {
	require_once(dirname(__FILE__).'/pioneer.lib.php');
	header('Content-Type: text/xml');
	pvRebel_setPower($pioneer,intval($_GET['power']));
	die("<pioneer_rebel>\n  <status>OK</status>\n</pioneer_rebel>\n");
}
?>