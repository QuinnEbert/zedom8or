<?php
$header = 'Power Switches';
if ( ! isset($pioneer) )
	require_once(dirname(__FILE__).'/Z8Config.php');
require_once(dirname(__FILE__).'/PioneerRebel/pioneer.lib.php');
ob_start();
$ourFile = 'PioneerRebel/ssCommon.php';
require_once($ourFile);
?>
<script type="text/javascript">
	function pvRebel_setPower(fnPower) {
		if (window.XMLHttpRequest) {
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
		xmlhttp.open("GET","<?php echo( $ourFile . '?power=' ); ?>"+fnPower+"&pioneer=<?php echo($pioneer); ?>",false);
		xmlhttp.send();
	}
</script>
<table border="1" cellspacing="1" cellpadding="4" style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;">
<tr><td><h3>Pioneer VSX-1022-K</h3></td></tr>
<tr><td><p><input type="button" onClick="pvRebel_setPower('0')" name="Power Off" value="Power Off" /><input type="button" onClick="pvRebel_setPower('1')" name="Power On" value="Power On" /></p></td></tr>
</table>
<?php
$body = ob_get_contents();
ob_end_clean();
?>