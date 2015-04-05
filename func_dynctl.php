<?php
ini_set('display_errors','On');
error_reporting(E_ALL);
$ctl_dev='';
if (isset($_GET['dynctl']))
	$ctl_dev=$_GET['dynctl'];
if ( ! isset($pioneer) )
	require_once(dirname(__FILE__).'/Z8Config.php');
require_once(dirname(__FILE__).'/PioneerRebel/pioneer.lib.php');
$ourFile = 'PioneerRebel/ssCommon.php';
require_once($ourFile);
require_once(dirname(__FILE__).'/irtFuncs.php');

//FIXME: needs to be centralized!
function get_named_device($devName) {
	global $devices;
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

$our_device = get_named_device($ctl_dev);
//FIXME: need to deal with the case of the device not being found!
$header = 'Control '.$our_device['name'];
ob_start();

?>
<script type="text/javascript">
function z8_js_button_oneshot(device,command) {
	if (window.XMLHttpRequest) {
		xmlhttp=new XMLHttpRequest();
	} else {
		xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
	}
	xmlhttp.open("GET","ssComnPR.php?z8dev="+device+"&z8cmd="+command,false);
	xmlhttp.send();
}
</script>
<?php

echo '<div style="margin:0px;padding:0px 12pt 12pt 12pt;">';

$our_device['compiled_links']['i'] = array();
$our_device['compiled_links']['o'] = array();
if (isset($our_device['data']['links']['inputs'])) { foreach ($our_device['data']['links']['inputs'] as $portName => $linkDev) {
	$our_device['compiled_links']['i'][$portName] = get_named_device($linkDev);
} }
if (isset($our_device['data']['links']['outputs'])) { foreach ($our_device['data']['links']['outputs'] as $portName => $linkDev) {
	$our_device['compiled_links']['o'][$portName] = get_named_device($linkDev);
} }

if (isset($our_device['data']['device_descriptive'])) {
	echo "<p><em>{$our_device['data']['device_descriptive']}</em></p>";
}

echo '<p>Located in the <strong>'.$our_device['data']['room'].'</strong>';
if (isset($our_device['data']['power']))
	echo '<br />Power: '.$our_device['data']['power'];
if (isset($our_device['data']['signaling']))
	echo '<br />Control: '.$our_device['data']['signaling'];
if (isset($our_device['data']['network']))
	echo '<br />Networking: '.$our_device['data']['network'];
echo '</p>';

echo '<table border="1"><tr>';
// Controls
echo '<td align="left" valign="top">';
echo '<h2>Controls</h2>';
//echo '<pre>'.print_r($our_device['data']['commands'],true).'</pre>';
foreach ($our_device['data']['commands'] as $category => $category_commands) {
	/*echo '<h3>'.$category.'</h3><ul>';
	foreach ($category_devices as $category_device) {
		$c_name = $category_device['name'];
		$c_type = $category_device['type'];
		$c_command = $category_device['command'];
		echo '<li>'.$c_name.' <pre>'."\n".$c_type."\n".$c_command.'</pre></li>';
	}
	echo '</ul>';*/
	echo z8_render_ctl_table($category,$category_commands,$our_device['data']['link_as']);
}
echo '</td>';
// Linked Devices
if (count($our_device['compiled_links']['i'])||count($our_device['compiled_links']['o'])||isset($our_device['data']['probes'])) {
	echo '<td align="left" valign="top">';
	if (isset($our_device['data']['probes'])) {
		echo '<h2>Device Status</h2>';
		$first_probe = true;
		foreach ($our_device['data']['probes'] as $probe => $p_cmd) {
			if (!$first_probe) {
				echo '<br />';
			} else {
				$first_probe = false;
			}
			echo ucfirst($probe).': ';
			$cmd_res = `$p_cmd`;
			if (trim($cmd_res)=='0'||trim($cmd_res)=='1') {
				if (trim($cmd_res)=='0') {
					echo 'Off';
				} else {
					echo 'On';
				}
			}
		}
	}
	if (count($our_device['compiled_links']['i'])||count($our_device['compiled_links']['o'])) {
		echo '<h2>Linked Devices</h2>';
		if (count($our_device['compiled_links']['i'])) {
			echo '<h3>On Inputs:</h3><ul>';
			foreach ($our_device['compiled_links']['i'] as $portName => $dev) {
				echo '<li>'.$dev['name'].' ('.$dev['data']['device'].')<br /><strong>on '.$portName.'</strong></li>';
			}
			echo '</ul>';
		}
		if (count($our_device['compiled_links']['o'])) {
			echo '<h3>On Outputs:</h3><ul>';
			foreach ($our_device['compiled_links']['o'] as $portName => $dev) {
				echo '<li>'.$dev['name'].' ('.$dev['data']['device'].')<br /><strong>on '.$portName.'</strong></li>';
			}
			echo '</ul>';
		}
	}
	echo '</td>';
}
echo '</tr>';

if (isset($our_device['data']['analogues'])) {
	if (isset($our_device['data']['analogues']['speakers'])) {
		echo '<tr><td colspan="2"><h2>Connected Analogue Speakers</h2>';
		foreach ($our_device['data']['analogues']['speakers'] as $set_name => $speaker) {
			echo '<ul>';
			echo '<li>';
			echo '<strong>'.$set_name.'</strong>';
			echo '<ul>';
			
			echo '<li><em>'.$speaker['name'].'</em></li>';
			echo '<li>Cabled with: '.$speaker['wire'].'</li>';
			echo '<li>Terminated with: '.$speaker['caps'].'</li>';
			echo '<li>Powered by: '.$speaker['power'].'</li>';
			
			echo '</ul>';
			echo '</li>';
			echo '</ul>';
		}
		echo '</td></tr>';
	}
}

if (isset($_GET['debug'])) {
	echo '<tr><td colspan="2"><h2>Debug Info</h2>';
	echo '<h3>Device Data</h3>';
	echo '<pre>'.print_r($our_device,true).'</pre>';
	echo '</td></tr>';
}

echo '</table>';

echo '</div>';

$body = ob_get_contents();
ob_end_clean();
?>