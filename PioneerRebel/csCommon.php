<?php
/**
 * PioneerRebel Client-Side Common "Directed" JS Code
 * 
 * This PioneerRebel file is a version specific to Zedom8or
 * 
 * PHP version 5.2.3
 * 
 * @category PioneerRebel_Inheritance
 * @package  Zedom8or
 * @author   Quinn Ebert <use-form@quinnebert.net>
 * @license  http://creativecommons.org/licenses/by-nc-sa/4.0/ CC BY-NC-SA 4.0
 * @link     https://github.com/QuinnEbert/zedom8or
 */

$ourFile = $_GET['ourFile']; ?>
		function pvRebel_setSource(fnInput) {
			if (window.XMLHttpRequest) {
				xmlhttp=new XMLHttpRequest();
			} else {
				xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
			}
			xmlhttp.open("GET","<?php echo( $ourFile . '?input=' ); ?>"+fnInput,false);
			xmlhttp.send();
<?php if ($confirm) { ?>
			alert("Input changed!");
<?php
}
?>
		}
		function pvRebel_setMuting(setMuted) {
			if (window.XMLHttpRequest) {
				xmlhttp=new XMLHttpRequest();
			} else {
				xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
			}
			xmlhttp.open("GET","<?php echo( $ourFile . '?muted=' ); ?>"+setMuted,false);
			xmlhttp.send();
<?php if ($confirm) { ?>
			alert("Muted changed!");
<?php
}
?>
		}
		function pvRebel_setPower(fnPower) {
			if (window.XMLHttpRequest) {
				xmlhttp=new XMLHttpRequest();
			} else {
				xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
			}
			xmlhttp.open("GET","<?php echo( $ourFile . '?power=' ); ?>"+fnPower,false);
			xmlhttp.send();
<?php if ($confirm) { ?>
			alert("Power changed!");
<?php
}
?>
		}