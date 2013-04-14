<?php
function lirc_get_remote_names() {
	$results = explode("\n",trim(`irsend LIST '' '' '' 2>&1`));
	foreach ($results as $index => $value) {
		$process = explode(': ',$value,2);
		// Deduplicate entry if needed:
		if ($index > 0) {
			for ($check = 0; $check < $index; $check++) {
				if ($returns[$check] == $process[1])
					continue 2;
			}
			$toKey = count($returns);
			$returns[$toKey] = $process[1];
		} else {
			$returns[0] = $process[1];
		}
	}
	return $returns;
}
function lirc_get_remote_keys($remote) {
	$results = explode("\n",trim(`irsend LIST '$remote' '' '' 2>&1`));
	return $results;
	foreach ($results as $index => $value) {
		$process = explode(': ',$value,2);
		// Deduplicate entry if needed:
		if ($index > 0) {
			for ($check = 0; $check < $index; $check++) {
				if ($returns[$check] == $process[1])
					continue 2;
			}
			$toKey = count($returns);
			$returns[$toKey] = $process[1];
		} else {
			$returns[0] = $process[1];
		}
	}
	return $returns;
}
?>