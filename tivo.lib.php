<?php
	/* WARNING WARNING WARNING
	 * This is *NOT* a Microsoft (or similar) C/C++ (or other) linker library!
	 * It is, in fact, a PHP file require()'d by Quinn Ebert's "Zedom8or"
	 * open source software project.
	 * WARNING WARNING WARNING
	 * 
	 * tivo.lib.php :: TiVo S4 (and others) Telnet Functions
	 * Part of Quinn Ebert's "Zedom8or" Software Project
	 * 
	 * DISCLAIMER:
	 * "Zedom8or" is a software project wholly unaffiliated with TiVo.
	 * In no way is "Zedom8or" authorized, supported,
	 * acknowledged, or endorsed by TiVo.  FURTHERMORE, you use
	 * this software project AT YOUR OWN RISK.  The possibility indeed exists
	 * that bugs exist in this software which could lead to catastrophic
	 * failure of your TiVo equipment.  In no event shall Quinn
	 * Ebert or TiVo be held in any way liable for malfunction,
	 * damage, or destruction to your personal property (including but not
	 * limited to personal property created and/or manufactured by TiVo)
	 * arising from your use of (or failure to use) this project.
	 */
	
	// Send a command, with optional prefixed or suffixed parameter, to the TiVo
	// Returns corresponding controller response on OK or false (boolean) on error
	function tivoBox_SEND_CMD($address,$command='PO',$parameter=false,$param_first=true) {
		$fp = fsockopen($address, 31339, $errno, $errstr, 30);
		if (!$fp) {
			echo __FUNCTION__."() ERROR: $errstr ($errno), planned command was \"$command\"!\n";
			return false;
		} else {
			$cmd = '';
			if (! $parameter) {
				$cmd = $command;
			} else {
				if ($param_first) {
					$cmd = $parameter.$command;
				} else {
					$cmd = $command.$parameter;
				}
			}
			$cmd .= "\r\n";
			fwrite($fp, $cmd);
			//$out = fgets($fp);
			//fclose($fp);
			// Cool-down time
			sleep(15);
			// ^ Yes, the 15-second cooldown is a long damn time, unfortunately,
			//   when one has a low-end (Cisco in my case) Tuning Adapter and an
			//   HDMI connection passing through a Home Theatre amp (and then on
			//   to an HDMI-connected TV) each channel change is going to be slow
			//   due to the combo of the TiVo's meager core CPU hardware, setup
			//   of the HDCP link, and tuning of the channel through the external
			//   hardware.
			return true;
		}
		return false;
	}
	// Send a command to the TiVo unit requesting the viewed channel decrement
	function tivoBox_setChnDec($address) {
		tivoBox_SEND_CMD($address,'IRCODE CHANNELDOWN');
	}
	// Send a command to the TiVo unit requesting the viewed channel increment
	function tivoBox_setChnInc($address) {
		tivoBox_SEND_CMD($address,'IRCODE CHANNELUP');
	}
?>