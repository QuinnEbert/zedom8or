<?php
	/* WARNING WARNING WARNING
	 * This is *NOT* a Microsoft (or similar) C/C++ (or other) linker library!
	 * It is, in fact, a PHP file require()'d by Quinn Ebert's "Pioneer Rebel"
	 * open source software project.
	 * WARNING WARNING WARNING
	 * 
	 * pioneer.lib.php :: Pioneer VSX-1022-K Telnet Functions
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
	
	// Send a command, with optional prefixed or suffixed parameter, to the 1022-K
	// Returns corresponding controller response on OK or false (boolean) on error
	function pvRebel_SEND_CMD($address,$command='PO',$parameter=false,$param_first=true,$numSend=1) {
		$fp = fsockopen($address, 8102, $errno, $errstr, 30);
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
			$out = '';
			for ($counter = 0; $counter < $numSend; $counter++) {
				fwrite($fp, $cmd);
				$out .= fgets($fp);
				$out .= "\n";
				usleep(250000);
			}
			fclose($fp);
			// Cool-down time (my VSX preferred 100ms between reconnects...)
			usleep(100000);
			return $out;
		}
		return false;
	}
	// Send comamnds to the 1022-K amp unit to *effectively* set Volume Level
	// setting $setting (number divisible by two *or* equals zero) by way of:
	//   1. Get current volume setting
	//   2. Increase or decrease as needed relatively
	function pvRebel_setVolSet($address,$setting) {
		$compare = pvRebel_getVolVal($address);
		if ($setting!=$compare) {
			if ($setting < $compare) {
				pvRebel_SEND_CMD($address,'VD',false,true,($compare-$setting));
			} else {
				pvRebel_SEND_CMD($address,'VU',false,true,($setting-$compare));
			}
		}
	}
	// Send a command to the 1022-K amp unit requesting the volume level decrement
	function pvRebel_setVolDec($address) {
		pvRebel_SEND_CMD($address,'VD');
	}
	// Send a command to the 1022-K amp unit requesting the volume level increment
	function pvRebel_setVolInc($address) {
		pvRebel_SEND_CMD($address,'VU');
	}
	// Send a command to the 1022-K amp unit requesting the input change to $input
	// (which, for now, is the two numerals preceding "FN" in the Telnet command)
	// 
	// See pvRebel_getSource for the most-handy input number cross-reference
	function pvRebel_setSource($address,$fnInput) {
		pvRebel_SEND_CMD($address,$fnInput.'FN');
	}
	// Send a command to the 1022-K amp unit requesting the power on/off status
	// 
	// Returns string "ON" or "OFF" on success indicating power status.  On failure,
	// returns BOOLEAN type false (use === or !== to differentiate 0 from false!!!)
	function pvRebel_getPower($address) {
		$out = pvRebel_SEND_CMD($address,'?P');
		if (strstr($out,'PWR0'))
			return "ON";
		return "OFF";
	}
	// Send a command to the 1022-K amp unit requesting the power turn on or off
	// 
	// Pass $fnPower=true for power-on (requires network over sleep enabled)
	// Pass $fnPower=false for power-off
	function pvRebel_setPower($address,$fnPower) {
		$powerTo = 'F';
		if ($fnPower)
			$powerTo = 'O';
		pvRebel_SEND_CMD($address,'P'.$powerTo);
	}
	// Send a command to the 1022-K amp unit requesting the muting turn on or off
	// 
	// Pass $fnMuted=true for muted-on
	// Pass $fnMuted=false for muted-off
	function pvRebel_setMuting($address,$fnMuted) {
		$mutedTo = 'F';
		if ($fnMuted)
			$mutedTo = 'O';
		pvRebel_SEND_CMD($address,'M'.$mutedTo);
	}
	// Request the current status of audio output muting on the 1022-K amp unit
	// On success returns *1* for un-muted (IE: "VOL XYZ" shown on LCD) or *0* for
	// "MUTING" -- success values are int types.  On failure, returns BOOLEAN type
	// false (remember to use === or !== to differentiate 0 from false!!!)
	function pvRebel_getMuting($address) {
		$out = pvRebel_SEND_CMD($address,'?M');
		if ( $out === false ) return false;
		// It would be best to have a more-rigorous failure handling for this one:
		$out = trim($out);
		if (strtoupper($out)==='R') return false;
		if (strlen($out)!=4) return false;
		$out = substr($out,3);
		if ($out!=='0'&&$out!=='1') return false;
		return intval(trim($out));
	}
	// Request percent of maximum volume currently seen set on the 1022-K (this is
	// gathered by equating the 81 distinct volume levels to the closest integers
	// on a 100% scale, basically, multiplying the numeric volume setting from 0
	// to 80 by 1.25 and rounding the result to the nearest integer)
	// Returns current volume percent as string on OK or false (boolean) on error
	function pvRebel_getVolPct($address) {
		$out = intval(pvRebel_getVolVal($address));
		if (! $out) return false;
		$pct = strval(intval(round((floatval($out)*1.25))));
		return $pct;
	}
	// Request the current numeric volume setting seen by the 1022-K's controller
	// (a value ranging 0 to 80 is the expected value on my 1022-K unit)
	// Returns the current volume as int on OK or false (boolean) on error
	function pvRebel_getVolVal($address) {
		$out = pvRebel_SEND_CMD($address,'?V');
		if (! $out) return false;
		$val = intval((((intval(substr($out,3)))-1)/2));
		return $val;
	}
	// Request the current LCD reading (from a list of known values) that might
	// be displayed on the 1022-K.  The list of known values was hand-compiled
	// by running my unit through its full set of dialable inputs and noting
	// the "FNxy" value that Telnet interface echoed back for the input change
	// Returns the string value on OK or false (boolean) on error
	function pvRebel_getSource($address) {
		$inNames["FN17"] = "IPOD/USB";
		$inNames["FN05"] = "TV";
		$inNames["FN01"] = "CD";
		$inNames["FN02"] = "TUNER";
		$inNames["FN33"] = "ADAPTER";
		$inNames["FN25"] = "BD";
		$inNames["FN04"] = "DVD";
		$inNames["FN06"] = "SAT/CBL";
		$inNames["FN15"] = "DVR/BDR";
		$inNames["FN10"] = "VIDEO";
		$inNames["FN49"] = "GAME";
		$inNames["FN38"] = "NETRADIO";
		$inNames["FN41"] = "PANDORA";
		$inNames["FN44"] = "M.SERVER";
		$inNames["FN45"] = "FAVORITE";
		$inNames["FN46"] = "AIRPLAY";
		$out = pvRebel_SEND_CMD($address,'?FN');
		if (! $out) return false;
		$val = trim($out);
		return $inNames[$val];
	}
?>