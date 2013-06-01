<?php
$header = 'Volume Levels';
if ( ! isset($pioneer) )
	require_once(dirname(__FILE__).'/Z8Config.php');
require_once(dirname(__FILE__).'/PioneerRebel/pioneer.lib.php');
ob_start();
$ourFile = 'PioneerRebel/ssCommon.php';
require_once($ourFile);
?>
<script type="text/javascript">
	function pvRebel_setMuting(setMuted) {
		if (window.XMLHttpRequest) {
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
		xmlhttp.open("GET","<?php echo( $ourFile . '?pioneer='.$pioneer.'&muted=' ); ?>"+setMuted,false);
		xmlhttp.send();
	}
	function pvRebel_setVolLev() {
		if (window.XMLHttpRequest) {
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
		xmlhttp.open("GET","<?php echo( $ourFile . '?volLv&pioneer='.$pioneer ); ?>&Lv="+document.getElementById('VolumeTo').value,true);
		xmlhttp.send();
	}
	function pvRebel_setVolDec() {
		if (window.XMLHttpRequest) {
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
		xmlhttp.open("GET","<?php echo( $ourFile . '?volDn&pioneer='.$pioneer ); ?>",true);
		xmlhttp.send();
	}
	function pvRebel_setVolInc() {
		if (window.XMLHttpRequest) {
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
		xmlhttp.open("GET","<?php echo( $ourFile . '?volUp&pioneer='.$pioneer ); ?>",true);
		xmlhttp.send();
	}
</script>
<table border="1" cellspacing="1" cellpadding="4" style="padding: 0px; margin: 0px; margin-left: 24px; margin-bottom: 16px;">
<tr><td><h3>Pioneer VSX-1022-K</h3></td></tr>
<tr><td><p>
	<input type="button" onClick="pvRebel_setVolDec()" name="Volume Down" value="Volume Down" />
	<input type="button" onClick="pvRebel_setVolInc()" name="Volume Up" value="Volume Up" /><br />
	<input type="button" onClick="pvRebel_setMuting('0')" name="Muting Off" value="Muting Off" />
	<input type="button" onClick="pvRebel_setMuting('1')" name="Muting On" value="Muting On" />
	<br />
	<select name="VolumeTo" id="VolumeTo">
	<?php
	for ($counter = 0; $counter <= 80; $counter++) {
		echo("<option value=\"".strval($counter)."\">".strval($counter)."</option>");
	}
	?>
	</select>
	<input type="button" onClick="pvRebel_setVolLevel()" name="Set Volume" value="Set Volume" />
</p></td></tr>
</table>
<?php
$body = ob_get_contents();
ob_end_clean();
?>