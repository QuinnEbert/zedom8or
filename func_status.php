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
<?php
$body = ob_get_contents();
ob_end_clean();
?>