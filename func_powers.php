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
	function cmboDbg_setPower(fnPower) {
		pvRebel_setPower(fnPower);
		vztvDbg_togPower();
	}
	function pvRebel_setPower(fnPower) {
		if (window.XMLHttpRequest) {
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
		xmlhttp.open("GET","<?php echo( $ourFile . '?power=' ); ?>"+fnPower+"&pioneer=<?php echo($pioneer); ?>",true);
		xmlhttp.send();
	}
	function vztvDbg_togPower() {
		if (window.XMLHttpRequest) {
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
		xmlhttp.open("GET","index.php?powerOff_VizioTV=Y",true);
		xmlhttp.send();
	}
</script>
<table border="1" cellspacing="1" cellpadding="4" style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;">
<tr><td><h3>Pioneer VSX-1022-K</h3></td></tr>
<tr><td><p><input type="button" onClick="pvRebel_setPower('0')" name="Power Off" value="Power Off" /><input type="button" onClick="pvRebel_setPower('1')" name="Power On" value="Power On" /></p></td></tr>
</table>
<!-- This is going away...It's just for testing... -->
<table border="1" cellspacing="1" cellpadding="4" style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;">
<tr><td><h3>Vizio VL370M</h3></td></tr>
<tr><td><p><input type="button" onClick="vztvDbg_togPower()" name="Power Toggle" value="Power Toggle" /></p></td></tr>
</table>
<table border="1" cellspacing="1" cellpadding="4" style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;">
<tr><td><h3>COMMAND COMBO: Pioneer VSX-1022-K + Vizio VL370M</h3></td></tr>
<tr><td><p>
<input type="button" onClick="cmboDbg_setPower('0')" name="Power Off the LCD" value="Power Off the LCD" />
<input type="button" onClick="cmboDbg_setPower('1')" name="Power On the LCD" value="Power On the LCD" />
</p></td></tr>
</table>

<?php
$body = ob_get_contents();
ob_end_clean();
?>
