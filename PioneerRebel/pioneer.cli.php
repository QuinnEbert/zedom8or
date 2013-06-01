#!/usr/bin/php
<?php
	/* pioneer.cli.php :: Pioneer VSX-1022-K (Future) CLI Tool
	 * Part of Quinn Ebert's "Pioneer Rebel" Software Project
	 * 
	 * DISCLAIMER:
	 * "Pioneer Rebel" is a software project wholly unaffiliated with Pioneer
	 * Electronics.  In no way is "Pioneer Rebel" authorized, supported,
	 * acknowledged, or endorsed by Pioneer Electronics.  FURTHERMORE, you use
	 * this software project AT YOUR OWN RISK.  The possibility indeed exists
	 * that bugs exist in this software which could lead to catastrophic
	 * failure of your Pioneer Electronics equipment.  In no event shall Quinn
	 * Ebert or Pioneer Electronics be held in any way liable for malfunction,
	 * damage, or destruction to yourself or your personal property (including
	 * but not limited to personal property created and/or manufactured by
	 * Pioneer Electronics) arising from your use of (or failure to use) it.
	 */
	
	require 'pioneer.lib.php';
	
	//$olA = pvRebel_getVolVal('192.168.1.Xyz');
	//$olB = pvRebel_getVolPct('192.168.1.Xyz');
	//$olC = pvRebel_getMuting('192.168.1.Xyz');
	//$olD = pvRebel_getSource('192.168.1.Xyz');
	//echo("VAL: $olA\nPCT: $olB\n");
	/*if ($olC!==false) {
		// Just remember, 1022-K uses '0' for muted and '1' for un-muted,
		// reverse of what you might expect:
		if ( $olC ) {
			echo("The receiver isn't muted!\n");
		} else {
			echo("The receiver *is* muting!\n");
		}
	}*/
	//echo("$olD\n");
	//pvRebel_setVolSet('192.168.1.Xyz',60);
?>