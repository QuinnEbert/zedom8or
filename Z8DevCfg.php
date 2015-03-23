<?php
$devices = array(
	'ViewSonic PJD7820HD' => array(
		'control' => 'commands',
		'device' => 'projector',
		'commands' => array(
			array('name'=>'Power > Off','command'=>'./pjd7820hd.py \'Power OFF\''),
			array('name'=>'Power > On','command'=>'./pjd7820hd.py \'Power ON\''),
			array('name'=>'Input > HDMI','command'=>'./pjd7820hd.py \'HDMI\''),
			array('name'=>'Input > VGA 1','command'=>'./pjd7820hd.py \'VGA 1\''),
			array('name'=>'Input > VGA 2','command'=>'./pjd7820hd.py \'VGA 2\''),
			array('name'=>'Input > Composite','command'=>'./pjd7820hd.py \'Composite\''),
			array('name'=>'Input > S-Video','command'=>'./pjd7820hd.py \'S-Video\''),
		),
	),
	'Pioneer VSX-1023-K' => array(
		'control' => 'phpClass',
		'device' => 'receiver',
		'class' => 'vsx1023k',
		'commands' => array(
			array('name'=>'Power On','command'=>'power_on'),
			array('name'=>'Power Off','command'=>'power_off'),			
		),
	),
);