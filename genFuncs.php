<?php

ini_set('error_log','z8_devel.log');
ini_set('log_errors',true);
ini_set('error_reporting',E_ALL);

if (!function_exists('z8_exec_devctl_cmd')) {
	function z8_exec_devctl_cmd($z8dev,$z8cmd) {
		// Load Z8 general config:
		require dirname(__FILE__).'/Z8Config.php';
		// Load the device config:
		require dirname(__FILE__).'/Z8DevCfg.php';
		// Load phpClass device classes:
		foreach ($devices as $device) {
			if ($device['control'] == 'phpClass') {
				$modFile = dirname(__FILE__).'/DevicesLibrary/'.$device['class'].'.php';
				if (!file_exists($modFile)) {
					die('Cannot load module: '.$modFile);
				} else {
					require_once $modFile;
				}
			}
		}
		// Get the device specifics:
		$our_device = get_named_device($z8dev);
		// Is it a local or remote device?
		$remote_device = false;
		if (isset($our_device['data']['link_as'])) {
			$remdev_key = $our_device['data']['link_as'];
			if (isset($remDevs[$remdev_key])) {
				$remote_device = true;
			}
		}
		if ($remote_device) {
			// Remote Device:
		
			$dest = $remDevs[$remdev_key];
			$rqDF = array(
				'z8cmd' => $z8cmd,
				'z8dev' => $z8dev
			);
			$curl = curl_init();
			curl_setopt($curl,CURLOPT_URL,$dest);
			curl_setopt($curl,CURLOPT_POST,sizeof($rqDF));
			curl_setopt($curl,CURLOPT_POSTFIELDS,$rqDF);
			$rslt = curl_exec($curl);
			curl_close($curl);
		} else {
			// Local Device:
		
			// Is it a phpClass device or not?
			if ($our_device['data']['control']!='phpClass') {
				// "Straight" device, run command via system():
				ob_start();
				//FIXME: this is a security breach waiting to happen (check the command against Dev Config!!!)
				system($z8cmd);
				ob_end_clean();
			} else {
				// phpClass device, run command via class:
				$ctlMeth = new $our_device['data']['class']('192.168.1.17'); // <= FIXME: temporary hack for my VSX only!!!
				$ctlMeth->$z8cmd();
			}
		}
		return "<pioneer_rebel>\n  <status>OK</status>\n</pioneer_rebel>\n";
	}
}

if (!function_exists('get_named_device')) {
	function get_named_device($devName) {
		// Load Z8 general config:
		require dirname(__FILE__).'/Z8Config.php';
		// Load the device config:
		require dirname(__FILE__).'/Z8DevCfg.php';
		foreach ($devices as $device_name => $device) {
			if ($device['link_as']==$devName) {
				$our_device = array(
					'name' => $device_name,
					'data' => $device,
				);
				return $our_device;
			}
		}
		return null;
	}
}
