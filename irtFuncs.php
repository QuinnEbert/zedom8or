<?php
function lirc_get_remote_names() {
	$results = explode("\n",trim(`irsend LIST '' '' '' 2>&1`));
	foreach ($results as $index => $value) {
		$process = explode(': ',$value,2);
		$returns[$index] = $process[1];
	}
	return $returns;
}
?>