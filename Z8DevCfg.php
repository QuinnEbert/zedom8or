<?php
$devices = array(
	'ViewSonic PJD7820HD' => array(
		'control' => 'commands',
		'commands' => array(
			array('name'=>'Power On','command'=>'./pjd7820hd.py \'Power On\''),
			array('name'=>'Power Off','command'=>'./pjd7820hd.py \'Power Off\''),
		),
	),
	'Pioneer VSX-1023-K' => array(
		'control' => 'phpClass',
		'class' => 'vsx1023k',
		'commands' => array(
			array('name'=>'Power On','command'=>'power_on'),
			array('name'=>'Power Off','command'=>'power_off'),			
		),
	),
);