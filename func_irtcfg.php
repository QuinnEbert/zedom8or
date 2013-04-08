<?php
$header = 'USB-UIRT Info';
if ( ! isset($pioneer) )
	require_once(dirname(__FILE__).'/Z8Config.php');
require_once(dirname(__FILE__).'/PioneerRebel/pioneer.lib.php');
ob_start();
$ourFile = 'PioneerRebel/ssCommon.php';
require_once($ourFile);
?>
<table border="1" cellspacing="1" cellpadding="4" style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;">
<tr><td colspan="2"><h3>Remote Name</h3></td></tr>
<tr>
	<td><p>
		<em>{$keyName}</em>
	</p></td>
	<td><p>
		<em>Configured</em>
	</p></td>
</tr>
</table>
<?php
$body = ob_get_contents();
ob_end_clean();
?>