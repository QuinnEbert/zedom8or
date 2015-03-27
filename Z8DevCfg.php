<?php
$devices = array(
	'ViewSonic PJD7820HD' => array(
		'control' => 'commands',
		'device' => 'projector',
		'room' => 'Theatre',
		'link_as' => 'projector',
		'links' => array(
			'inputs' => array(
				'receiver'
			),
		),
		'commands' => array(
			array('name'=>'Power > Off','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'Power OFF\''),
			array('name'=>'Power > On','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'Power ON\''),
			array('name'=>'Input > HDMI','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'HDMI\''),
			array('name'=>'Input > VGA 1','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'VGA 1\''),
			array('name'=>'Input > VGA 2','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'VGA 2\''),
			array('name'=>'Input > Composite','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'Composite\''),
			array('name'=>'Input > S-Video','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'S-Video\''),
		),
	),
	'Pioneer VSX-1023-K' => array(
		'control' => 'phpClass',
		'class' => 'vsx1023k',
		'device' => 'receiver',
		'room' => 'Theatre',
		'link_as' => 'receiver',
		'links' => array(
			'outputs' => array(
				'projector'
			),
		),
		'commands' => array(
			array('name'=>'Power On','type'=>'button_oneshot','command'=>'power_on'),
			array('name'=>'Power Off','type'=>'button_oneshot','command'=>'power_off'),			
		),
	),
);