<!--
 ssCommon.php
 part of Quinn Ebert's "Zedom8or" software project
 
 PURPOSE:
   Common server-side code utilities used by the various
   interfaces in the Zedom8or Project.
 -->
<?php
/*
  CONFIGURATION:
  
  Set the IP or hostname of your VSX-1022-K below, indicate if you want the
  alert to successful command send dialog to appear, and enjoy!
*/
// Network address where your TiVo can be reached:
if ( ! isset($tivobox) ) $tivobox = '192.168.1.5';
// ^ Let $tivobox be overridden by external apps (like Zedom8or/"Z8"):
if (isset($_GET['tivobox'])) $tivobox = $_GET['tivobox'];

/*
 *  CODE BELOW
 */

if ( isset($_GET['powerOff_VizioTV']) ) {
	ob_start();
	system("irsend SEND_START 'BS_Vizio' 'KEY_POWER'");
	sleep(3);
	system("irsend SEND_STOP 'BS_Vizio' 'KEY_POWER'");
	ob_end_clean();
	header('Content-Type: text/xml');
	die("<vzTryOut>\n  <status>OK</status>\n</vzTryOut>\n");
}
?>