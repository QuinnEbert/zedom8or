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
		console.log("<?php echo( $ourFile . '?power=' ); ?>"+fnPower);
		if (window.XMLHttpRequest) {
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
		xmlhttp.open("GET","<?php echo( $ourFile . '?power=' ); ?>"+fnPower,false);
		xmlhttp.send();
	}
</script>
<h3>Pioneer VSX-1022-K</h3>
<p><input type="button" onClick="pvRebel_setPower('0')" name="Power Off" value="Power Off" /><input type="button" onClick="pvRebel_setPower('1')" name="Power On" value="Power On" /></p>
<?php
$body = ob_get_contents();
ob_end_clean();
?>