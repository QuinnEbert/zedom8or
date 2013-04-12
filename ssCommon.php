<?php
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