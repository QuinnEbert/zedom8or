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

echo '<p>Located in the <strong>'.$our_device['data']['room'].'</strong></p>';

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
if (count($our_device['compiled_links']['i'])||count($our_device['compiled_links']['o'])) {
	echo '<td align="left" valign="top">';
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
	echo '</td>';
}
echo '</tr></table>';

echo '</div>';

$body = ob_get_contents();
ob_end_clean();
?>