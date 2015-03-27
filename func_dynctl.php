<?php
$ctl_dev='';
if (isset($_GET['dynctl']))
	$ctl_dev=$_GET['dynctl'];
if ( ! isset($pioneer) )
	require_once(dirname(__FILE__).'/Z8Config.php');
require_once(dirname(__FILE__).'/PioneerRebel/pioneer.lib.php');
$ourFile = 'PioneerRebel/ssCommon.php';
require_once($ourFile);
require_once(dirname(__FILE__).'/irtFuncs.php');
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

echo '<div style="margin:0px;padding:0px 12pt 12pt 12pt;">';

$our_device['compiled_links']['i'] = array();
$our_device['compiled_links']['o'] = array();
if (isset($our_device['data']['links']['inputs'])) { foreach ($our_device['data']['links']['inputs'] as $linkDev) {
	$our_device['compiled_links']['i'][] = get_named_device($linkDev);
} }
if (isset($our_device['data']['links']['outputs'])) { foreach ($our_device['data']['links']['outputs'] as $linkDev) {
	$our_device['compiled_links']['o'][] = get_named_device($linkDev);
} }

echo '<p>Located in the <strong>'.$our_device['data']['room'].'</strong></p>';

echo '<table border="1"><tr>';
// Controls
echo '<td align="left" valign="top">';
echo '<h2>Controls</h2>';
echo '<pre>'.print_r($our_device['data'],true).'</pre>';
echo '</td>';
// Linked Devices
if (count($our_device['compiled_links']['i'])||count($our_device['compiled_links']['o'])) {
	echo '<td align="left" valign="top">';
	echo '<h2>Linked Devices</h2>';
	if (count($our_device['compiled_links']['i'])) {
		echo '<h3>On Inputs:</h3><ul>';
		foreach ($our_device['compiled_links']['i'] as $dev) {
			echo '<li>'.$dev['name'].' ('.$dev['data']['device'].')</li>';
		}
		echo '</ul>';
	}
	if (count($our_device['compiled_links']['o'])) {
		echo '<h3>On Outputs:</h3><ul>';
		foreach ($our_device['compiled_links']['o'] as $dev) {
			echo '<li>'.$dev['name'].' ('.$dev['data']['device'].')</li>';
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