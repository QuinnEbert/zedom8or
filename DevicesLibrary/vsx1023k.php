<?php
/**
 * VSX-1023-K DevicesLibrary Controller
 * 
 * PHP version 5.2.3
 * 
 * @category Hardware_Device_Controller_Classes
 * @package  Zedom8or
 * @author   Quinn Ebert <use-form@quinnebert.net>
 * @license  http://creativecommons.org/licenses/by-nc-sa/4.0/ CC BY-NC-SA 4.0
 * @link     https://github.com/QuinnEbert/zedom8or
 */

if (!function_exists('pvRebel_setPower')) {
    include
        dirname(dirname(__FILE__)).'/PioneerRebel/pioneer.lib.php';
}

/**
 * VSX-1023-K DevicesLibrary Controller Class
 * 
 * This controller *technically* also is compatible with the Pioneer
 * VSX-1022-K (and was in fact originally written using that model as its
 * point of reference), although, it is not known what happens if one tries
 * to reference features not present on the VSX-1022-K (or vice versa, such
 * as in the case of some features of this controller which were written to
 * spec specifically for the VSX-1022-K).
 * 
 * @category Hardware_Device_Controller_Classes
 * @package  Zedom8or
 * @author   Quinn Ebert <use-form@quinnebert.net>
 * @license  http://creativecommons.org/licenses/by-nc-sa/4.0/ CC BY-NC-SA 4.0
 * @link     https://github.com/QuinnEbert/zedom8or
 */
class Vsx1023k
{
    private $_ctlHost = null;

    /**
     * Class constructor
     * 
     * @param string $setParm IP address of the receiver to be controlled
     */
    function __construct($setParm)
    {
        $this->_ctlHost = $setParm;
    }

    /**
     * Signal this VSX-102x-K to turn amp power ON
     * 
     * Note that a VSX-102x-K can only have amp powered turned on if the
     * settings on the device are configured to keep the NIC active when the
     * amp is powered down, be advised that the author has had both 1022 and
     * 1023 units purchased new-in-box and LAN on power-down is disabled by
     * default on both models so if you have not changed that setting you
     * will need to do so before attempting to turn on the amp over the
     * network.
     * 
     * @return void
     */
    public function powerOn()
    {
        pvRebel_setPower($this->_ctlHost, true);
    }

    /**
     * Signal this VSX-102x-K to turn amp power OFF
     * 
     * Note that a VSX-102x-K can only have amp powered turned on if the
     * settings on the device are configured to keep the NIC active when the
     * amp is powered down, be advised that the author has had both 1022 and
     * 1023 units purchased new-in-box and LAN on power-down is disabled by
     * default on both models so if you have not changed that setting you
     * will need to do so before attempting to turn on the amp over the
     * network.
     * 
     * @return void
     */
    public function powerOff()
    {
        pvRebel_setPower($this->_ctlHost, false);
    }
}
