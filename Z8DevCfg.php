<?php
$devices = array(
	'ViewSonic PJD7820HD' => array(
		'control' => 'commands',
		'device' => 'projector',
		'device_descriptive' => 'DLP Projector (i-Chip DMD)',
		'room' => 'Theatre/Sun Room',
		'power' => 'surge-arrested mains',
		/*'network' => 'no Ethernet',*/
		'signaling' => 'RS232 signaling',
		'link_as' => 'projector',
		'probes' => array(
			'power' => './pjd7820hd.py \'power_status\'',
			'input' => './pjd7820hd.py \'input_status\'',
		),
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
	/*'Vizio VL370M' => array(
		'control' => 'lirccmd+', // <= 'lirccmd+' allows a mix of LIRC and command use to help an otherwise dumb device
		'device' => 'bedroomtv',
		'device_descriptive' => 'DTV-Equipped LCD Panel Television',
		'room' => 'Bedroom',
		'power' => 'surge-arrested mains',
		//'network' => 'no Ethernet',
		'signaling' => 'Philips RC6 compatible signaling, power switching via WeMo',
		'link_as' => 'bedroomtv',
		'links' => array(
			'inputs' => array(
				'HDMI-In 1' => 'nodevice',
				'C-Video/RCA-In 1' => 'nodevice',
			),
		),
		'probes' => array(
			'power' => array(
				'phpClass' => 'wemo_belkin',
				'function' => 'check_power',
				'argument' => 'bed1wemo', // <= network address in this case
			),
		),
		'commands' => array(
			// NOTE: you should ONLY use WeMo toggle for device power switching
			// if you know for a fact (like I do) that the device in question
			// has solid NVRAM for settings storage (this device does), and if
			// you know for a fact that device's NVRAM is battery-backed, do this
			// only if you know for a fact your device's NVRAM batteries aren't
			// flat (in this device's case modern flash storage is used)
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
	),*/
	'Pioneer VSX-1023-K' => array(
		'control' => 'phpClass',
		'class' => 'vsx1023k',
		'device' => 'receiver',
		'device_descriptive' => 'Receiver/Amplifier supporting audio AirPlay',
		'room' => 'Theatre/Sun Room',
		'power' => 'surge-arrested mains',
		'network' => 'fast Ethernet, LAN DHCP',
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
				// Rear/Centre AWOL until we get more copper (wish I were kidding):
				/*'Rear Pair' => array(
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
				),*/
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