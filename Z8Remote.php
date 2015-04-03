<?php
/*
 * Z8Remote.php >> "The Z8 Remote"
 * Part of Quinn Ebert's Zedom8or Project
 * 
 * PURPOSE:
 * Z8 Remote (somewhat deceptively named) receives requests from other installed instances of Z8
 * to perform commands against the locally configured devices AND provides details of local
 * device configuration to client applications.
 */

// Generic remote command sending:
if (isset($_POST['z8cmd'])&&isset($_POST['z8dev'])) {
	header('Content-Type: text/xml');
	die(z8_exec_devctl_cmd($_POST['z8dev'],$_POST['z8cmd']));
}

// Send configured device information (DEFAULT MODE):
require_once dirname(__FILE__).'/Z8DevCfg.php';
if (isset($_REQUEST['callback']))
	die($_REQUEST['callback'].'('.json_encode(array('devices',$devices)).');');
die(json_encode(array('devices',$devices)));