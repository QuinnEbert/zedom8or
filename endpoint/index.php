<?php
header('Content-Type: application/json');
ini_set('display_errors','Off');
error_reporting(E_ERROR);
require_once(dirname(dirname(__FILE__)).'/Z8Config.php');
require_once(dirname(dirname(__FILE__)).'/PioneerRebel/pioneer.lib.php');
$src = strval(pvRebel_getSource($pioneer));
$vol = strval(pvRebel_getVolVal($pioneer));
if (isset($_GET['volume'])) {
	pvRebel_setVolSet($pioneer,$_GET['volume']);
}
die(json_encode(array('source'=>$src,'volume'=>$vol)));
