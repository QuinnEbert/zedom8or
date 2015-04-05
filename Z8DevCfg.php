<?php
$devices = array(
	'ViewSonic PJD7820HD' => array(
		'control' => 'commands',
		'device' => 'projector',
		'room' => 'Theatre',
		'power' => 'surge-arrested mains',
		'network' => 'no Ethernet',
		'signaling' => 'RS232 signaling',
		'link_as' => 'projector',
		'links' => array(
			'inputs' => array(
				'HDMI-In' => 'receiver'
			),
		),
		'commands' => array(
			'Power' => array(
				array('name'=>'Power > Off','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'Power OFF\''),
				array('name'=>'Power > On','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'Power ON\''),
			),
			'Inputs' => array(
				array('name'=>'Input > HDMI','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'HDMI\''),
				array('name'=>'Input > VGA 1','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'VGA 1\''),
				array('name'=>'Input > VGA 2','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'VGA 2\''),
				array('name'=>'Input > Composite','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'Composite\''),
				array('name'=>'Input > S-Video','type'=>'button_oneshot','command'=>'./pjd7820hd.py \'S-Video\''),
			),
		),
	),
	'Pioneer VSX-1023-K' => array(
		'control' => 'phpClass',
		'class' => 'vsx1023k',
		'device' => 'receiver',
		'room' => 'Theatre',
		'power' => 'surge-arrested mains',
		'network' => 'fast Ethernet, our DHCP',
		'link_as' => 'receiver',
		'links' => array(
			'outputs' => array(
				'HDMI-Out' => 'projector'
			),
		),
		'analogues' => array(
			'speakers' => array(
				'Front Pair' => array(
					'name' => 'Polk Audio Tall Satellites (Stereo Pair)',
					'wire' => 'Doubly Insulated Copper Pairs',
					'caps' => 'Banana Clips',
					'power' => 'Receiver'
				),
				'Rear Pair' => array(
					'name' => 'Polk Audio Mid Satellites (Stereo Pair)',
					'wire' => 'Doubly Insulated Copper Pairs',
					'caps' => 'Banana Clips',
					'power' => 'Receiver'
				),
				'Centre' => array(
					'name' => 'Polk Audio Wide Satellite (Standalone)',
					'wire' => 'Doubly Insulated Copper Pair',
					'caps' => 'Banana Clips',
					'power' => 'Receiver'
				),
				'Subwoofer' => array(
					'name' => 'Polk Audio 16-inch Selectable Passive/Active Woofer with Direct Inputs',
					'wire' => 'Monster Cable Blue RCA',
					'caps' => 'RCA-style tip/ring',
					'power' => 'Mains'
				),
			),
		),
		'commands' => array(
			'Power' => array(
				array('name'=>'Power On','type'=>'button_oneshot','command'=>'power_on'),
				array('name'=>'Power Off','type'=>'button_oneshot','command'=>'power_off'),			
			),
		),
	),
);