<?php
$header = 'Status';
if ( ! isset($pioneer) )
	require_once(dirname(__FILE__).'/Z8Config.php');
require_once(dirname(__FILE__).'/PioneerRebel/pioneer.lib.php');
$prState = array(
	'Input Source' => pvRebel_getSource($pioneer),
	'Volume Level' => pvRebel_getVolPct($pioneer).'%'
);
//print_r($prState,false);
ob_start();
?>
<table style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;" width="50%" border="1" cellspacing="1" cellpadding="4">
<tr><td colspan="2"><h3 style="margin-bottom: 1px; margin-left: 0px; padding-left: 4px;">Pioneer VSX-1022-K</h3></td></tr>
<?php
foreach ($prState as $key=>$value) {
	echo('<tr>');
	echo('<td width="35%" style="padding-left: 9px;"><strong>'.$key.'</strong></td>');
	echo('<td width="65%" style="padding-left: 9px;">'.$value.'</td>');
	echo('</tr>');
}
?>
</table>
<table style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;" width="50%" border="1" cellspacing="1" cellpadding="4">
<tr><td colspan="2"><h3 style="margin-bottom: 1px; margin-left: 0px; padding-left: 4px;">APC Backup Battery</h3></td></tr>
<?php
if (strlen(rtrim(`which apcaccess`))) {
	$command = rtrim(`which apcaccess`);
	if ($apcupsd!==false) {
		if ($apcupsd!==true) {
			$command .= " status {$apcupsd}";
		}
		$results = explode("\n",trim(`$command`));
		foreach ($results as $aResult) {
			$keyVals = explode(':',$aResult,2);
			$k = trim($keyVals[0]);
			$v = trim($keyVals[1]);
			echo("<tr><td width=\"35%\">{$k}</td><td width=\"65%\">{$v}</td></tr>");
		}
	} else {
		echo('<tr><td colspan="2"><em>APCUPSD is not enabled!</em></td></tr>');
	}
} else {
	echo('<tr><td colspan="2"><em>APCUPSD is not found!</em></td></tr>');
}
?>
</table>
<?php
$body = ob_get_contents();
ob_end_clean();
?>