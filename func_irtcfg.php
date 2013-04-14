<?php
$header = 'USB-UIRT Info';
if ( ! isset($pioneer) )
	require_once(dirname(__FILE__).'/Z8Config.php');
require_once(dirname(__FILE__).'/PioneerRebel/pioneer.lib.php');
ob_start();
$ourFile = 'PioneerRebel/ssCommon.php';
require_once($ourFile);
require_once(dirname(__FILE__).'/irtFuncs.php');
?>
<!-- <pre><?php echo(print_r(lirc_get_remote_names(),true)); ?></pre>
<pre><?php echo(print_r(lirc_get_remote_keys('BS_Vizio'),true)); ?></pre>  -->

<?php $remotes = lirc_get_remote_names(); foreach($remotes as $aRemote) { ?>
<table border="1" cellspacing="1" cellpadding="4" style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;">
<tr><td><h3>Remote: &quot;<?php echo($aRemote); ?>&quot;</h3></td></tr>
<?php $keyList = lirc_get_remote_keys($aRemote); foreach ($keyList as $keyName) { ?>
<tr>
	<td><p>
		<em><?php echo($keyName); ?></em>
	</p></td>
</tr>
<?php } ?>
</table>
<?php }

$body = ob_get_contents();
ob_end_clean();
?>