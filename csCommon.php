<?php $ourFile = $_GET['ourFile']; ?>
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
			<?php } ?>
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
			<?php } ?>
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
			<?php } ?>
		}