<?php
ini_set('display_errors',true);
error_reporting(E_ALL);
?>
<html>
<head>
<title>Zedom8or Batch Command Set Proof-of-Concept Test</title>
</head>
<body bgcolor="black" text="white">
<?php
require_once dirname(dirname(__FILE__)).'/Z8DevCfg.php';

function z8devcfg_get_named_device($devName) {
	global $devices;
	foreach ($devices as $cfgName => $device) {
		if ($device['link_as']==$devName)
			return $device;
		if ($cfgName==$devName)
			return $device;
	}
	return null;
}

function z8_batch_set_compile($cmdPack) {
	$returns = array();
	foreach ($cmdPack as $cmdInfo) {
		$device = z8devcfg_get_named_device($cmdInfo[0]);
		$cmdCat = $cmdInfo[1];
		$cmdSbj = $cmdInfo[2];
		foreach ($device['commands'][$cmdCat] as $cmdsFin) {
			if ($cmdsFin['name']==$cmdSbj) {
				if ($device['control']=='phpClass') {
					$returns[] = array(
						$device['control'],
						$device['class'],
						$cmdsFin['command'],
					);
				} else {
					$returns[] = array(
						$device['control'],
						'',
						$cmdsFin['command'],
					);
				}
			}
		}
	}
	return $returns;
}

$devCmds = array(
	'System Power On' => array(
		array('projector','Power','Power > On'),
		array('receiver','Power','Power On'),
	),
);
?>
<pre><?php echo print_r(z8_batch_set_compile($devCmds),true); ?></pre>
</body>
</html>