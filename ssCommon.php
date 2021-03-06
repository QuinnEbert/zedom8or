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

require(dirname(__FILE__).'/Z8DevCfg.php');
require(dirname(__FILE__).'/Z8Config.php');
require_once(dirname(__FILE__).'/irtFuncs.php');
require_once(dirname(__FILE__).'/PioneerRebel/pioneer.lib.php');

// Load in stuff from 'DevicesLibrary' for any phpClass-using devices:
foreach ($devices as $device) {
	if ($device['control'] == 'phpClass') {
		$useFile = dirname(__FILE__).'/DevicesLibrary/'.$device['class'].'.php';
		if (!file_exists($useFile))
			die('FATAL: the "'.$useFile.'" class file couldn\'t be loaded!');
		require_once($useFile);
	}
}

if (!function_exists('strhasprefix')) {
	function strhasprefix($haystack,$needle) {
		return (strstr($haystack,$needle)==$haystack);
	}
}

if (!function_exists('z8_render_ctl_command')) {
	function z8_render_ctl_command($control,$callback_name) {
		if (strhasprefix($control['type'],'button_oneshot')) {
			return '<input type="button" name="'.$control['name'].'" value="'.$control['name'].'" onclick="javascript:z8_js_button_oneshot(\''.$callback_name.'\',\''.str_replace('\'',"\\".'\'',$control['command']).'\');" />';
		}
		return 'Foo';
	}
}

if (!function_exists('z8_render_ctl_table')) {
	function z8_render_ctl_table($title,$controls,$callback_name) {
		/* NOTE TO MYSELF:
		   
		   $controls should be any array like:
		   
		   $controls = array(
		       [0] => array(
		           'device_link' => ...'link_as' name for device (used for JS linkage)...,
		           'type' => ...command type...,
		           'name' => ...command name...,
		           'command' => ...command string...,
		       )
		   );
		 */
		$returns = '<table class="ctlTable" border="3"><tr><td>'.$title.'</td></tr><tr><td>';
		$lastDev = (count($controls)-1);
		for ($i = 0; $i <= $lastDev; $i++) {
			$returns .= z8_render_ctl_command($controls[$i],$callback_name);
			if ($i < $lastDev)
				$returns .= '<br />';
		}
		$returns .= '</td></tr></table>';
		return $returns;
	}
}

if (!function_exists('primeRPi')) {
	function primeRPi() {
		require(dirname(__FILE__).'/Z8Config.php');
		if (!isset($primePi)) $primePi = false;
		if ($primePi) {
			ob_start();
			$notUsed = lirc_get_remote_names();
			ob_end_clean();
		}
	}
}

//FIXME: this was only originally meant for testing!
if ( isset($_GET['VizioTV_GoVGA']) ) {
	primeRPi();
	ob_start();
	system('irsend SEND_START BS_Vizio KEY_TRAIN');
	sleep(1);
	system('irsend SEND_STOP BS_Vizio KEY_TRAIN');
	sleep(10);
	for ($i = 1; $i <= 6; $i++) {
		system('irsend SEND_START BS_Vizio KEY_INPUT');
		sleep(1);
		system('irsend SEND_STOP BS_Vizio KEY_INPUT');
	}
	ob_end_clean();
	header('Content-Type: text/xml');
	die("<vzTryOut>\n  <status>OK</status>\n</vzTryOut>\n");
}
//FIXME: this was only originally meant for testing!
if ( isset($_GET['VizioTV_GoPioneer']) ) {
	primeRPi();
	ob_start();
	system('irsend SEND_START BS_Vizio KEY_TRAIN');
	sleep(1);
	system('irsend SEND_STOP BS_Vizio KEY_TRAIN');
	sleep(10);
	for ($i = 1; $i <= 7; $i++) {
		system('irsend SEND_START BS_Vizio KEY_INPUT');
		sleep(1);
		system('irsend SEND_STOP BS_Vizio KEY_INPUT');
	}
	ob_end_clean();
	header('Content-Type: text/xml');
	die("<vzTryOut>\n  <status>OK</status>\n</vzTryOut>\n");
}
if ( isset($_GET['VizioTV_GoTaKa']) ) {
	primeRPi();
	ob_start();
	system('irsend SEND_START BS_Vizio KEY_TRAIN');
	sleep(1);
	system('irsend SEND_STOP BS_Vizio KEY_TRAIN');
	sleep(10);
	for ($i = 1; $i <= 9; $i++) {
		system('irsend SEND_START BS_Vizio KEY_INPUT');
		sleep(1);
		system('irsend SEND_STOP BS_Vizio KEY_INPUT');
	}
	ob_end_clean();
	header('Content-Type: text/xml');
	die("<vzTryOut>\n  <status>OK</status>\n</vzTryOut>\n");
}
//FIXME: this was only originally meant for testing!
if ( isset($_GET['powerOff_VizioTV']) ) {
	primeRPi();
	ob_start();
	system("irsend SEND_START 'BS_Vizio' 'KEY_POWER'");
	sleep(3);
	system("irsend SEND_STOP 'BS_Vizio' 'KEY_POWER'");
	ob_end_clean();
	header('Content-Type: text/xml');
	die("<vzTryOut>\n  <status>OK</status>\n</vzTryOut>\n");
}
//FIXME: this was only originally meant for testing!
if ( isset($_GET['powerOn_ViewsonicTV']) ) {
	ob_start();
	system('./pjd7820hd.py');
	ob_end_clean();
	header('Content-Type: text/xml');
	die("<vsTryOut>\n  <status>OK</status>\n</vsTryOut>\n");
}
?>