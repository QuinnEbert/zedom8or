<?php
$header = 'Input Switches';
if ( ! isset($pioneer) )
	require_once(dirname(__FILE__).'/Z8Config.php');
require_once(dirname(__FILE__).'/PioneerRebel/pioneer.lib.php');
ob_start();
$ourFile = 'PioneerRebel/ssCommon.php';
require_once($ourFile);
?>
<script type="text/javascript">
	function pvRebel_setSource(fnInput) {
		if (window.XMLHttpRequest) {
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
		xmlhttp.open("GET","<?php echo( $ourFile . '?input=' ); ?>"+fnInput+"&pioneer=<?php echo($pioneer); ?>",true);
		xmlhttp.send();
	}
	function vztvDbg_GoPioneer() {
		if (window.XMLHttpRequest) {
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
		xmlhttp.open("GET","index.php?VizioTV_GoPioneer=Y",true);
		xmlhttp.send();
	}
	function comboDbg_GoVGA() {
		pvRebel_setSource('05');
		if (window.XMLHttpRequest) {
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
		xmlhttp.open("GET","index.php?VizioTV_GoVGA=Y",true);
		xmlhttp.send();
	}
</script>
<?php
$inNames["17"] = "iPod/USB Device";
$inNames["05"] = "TV Loopback";
$inNames["01"] = "CD Player";
$inNames["02"] = "FM/AM Tuner";
$inNames["33"] = "Bluetooth Adapter";
$inNames["25"] = "Blu-ray Player";
$inNames["04"] = "DVD Player";
$inNames["06"] = "Satellite/Cable";
$inNames["15"] = "DVR/BD Recorder";
$inNames["10"] = "Video Input";
$inNames["49"] = "Game System";
$inNames["38"] = "Internet Radio";
$inNames["41"] = "Pandora Radio";
$inNames["44"] = "LAN Media";
$inNames["45"] = "Favorites";
$in_code = '';
foreach ($inNames as $num => $value) {
	$in_code .= '<input style="width: 100%;" type="button" onClick="pvRebel_setSource(\''.strval($num).'\')" name="'.strval($value).'" value="'.strval($value).'" />'."\n";
}
$in_code = str_replace("\n","<br />",rtrim($in_code));
?>
<table border="1" cellspacing="1" cellpadding="4" style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;">
<tr><td><h3>Pioneer VSX-1022-K</h3></td></tr>
<tr><td style="margin-right:0px;padding-right:9px;"><p style="margin-right:0px;padding-right:0px;"><?php echo($in_code); ?></p></td></tr>
</table>
<table border="1" cellspacing="1" cellpadding="4" style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;">
<tr><td><h3>Vizio VL370M</h3></td></tr>
<tr><td style="margin-right:0px;padding-right:9px;"><p style="margin-right:0px;padding-right:0px;"><input type="button" onClick="vztvDbg_GoPioneer()" name="Switch to Pioneer VSX-1022-K" value="Switch to Pioneer VSX-1022-K" /></p></td></tr>
</table>
<table border="1" cellspacing="1" cellpadding="4" style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;">
<tr><td><h3>COMMAND COMBO: Pioneer VSX-1022-K + Vizio VL370M</h3></td></tr>
<tr><td style="margin-right:0px;padding-right:9px;"><p style="margin-right:0px;padding-right:0px;"><input type="button" onClick="comboDbg_GoVGA()" name="Switch system to VGA" value="Switch system to VGA" /></p></td></tr>
</table>
<?php
$body = ob_get_contents();
ob_end_clean();
?>