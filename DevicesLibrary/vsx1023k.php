<?php
class vsx1023k {
	private $ctlHost = null;
	function __construct($setParm) {
		$this->$ctlHost = $setParm;
	}
	public function power_on() {
		pvRebel_setPower($this->$ctlHost,true);
	}
	public function power_off() {
		pvRebel_setPower($this->$ctlHost,false);
	}
}
