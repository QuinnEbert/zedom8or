#!/usr/bin/python
"""Commands and control for the Viewsonic PJD7820HD.

Model website:
<TODO>

Manual for the projector:
<TODO>
"""

__author__ = 'Quinn Ebert <no-reply@quinnebert.net>'

import serial
import logging

import commands


ALL_COMMANDS = commands.ALL


class InvalidCommandException(Exception):
  """Raised when an invalid command is provided."""


class ViewsonicPJD7820HD(object):
  def __init__(self, serial_port):
    self.serial_port = serial_port
    self.serial_connection = None
    self.command_dict = None
    self.buildCommandDict()

  def buildCommandDict(self):
    if self.command_dict is None:
      self.command_dict = {}
      for x in commands.ALL:
        self.command_dict[x[0]] = x[1]

  def connectSerial(self):
    if self.serial_connection is None:
      self.serial_connection = serial.Serial(self.serial_port, 115200)

  def disconnectSerial(self):
    if self.serial_connection is not None:
      try:
        self.serial_connection.close()
      except:
        logging.exception('Could not close serial port %s' % self.serial_port)
      self.serial_connection = None

  def asciiCommandToHex(self, command):
    """Convert an ascii command to it's hex equivalent.

    Args:
       command: (string) ascii characters to be hexified for writing to serial
    """
    if len(command) % 2:
     raise InvalidCommandException("Command length must be a multiple of 2.")
    output = ''
    while command:
      part = command[:2]
      output += ('\\x' + part).decode('string_escape')
      command = command[2:]
    return output

  def verifyCommand(self, command):
    """Verify that a command is known and valid.

    Args:
       command: (string) ascii characters to be hexified for writing to serial
    """
    if command not in self.command_dict.values():
      raise InvalidCommandException("Specified command not in commands.py") 

  def writeCommand(self, command):
    """Write a command as an ascii string, will be converted to hex.

    Args:
       command: (string) ascii characters to be hexified for writing to serial
    """
    self.verifyCommand(command)
    hex_command = self.asciiCommandToHex(command)

    try:
      self.connectSerial()
      self.serial_connection.write(hex_command)
    finally:
      self.disconnectSerial()

  def writeCommandFromName(self, command_name):
    """Write a command based on it's named entry in commands.py.

    Args:
       command: (string) command name from commands.py
    """
    if command_name not in self.command_dict:
      raise InvalidCommandException("Given command name not in commands.py")
    self.writeCommand(self.command_dict[command_name])

  def powerOn(self):
    """Turn the projector power on."""
    self.writeCommandFromName('Power ON')

  def powerOff(self):
    """Turn the projector power off."""
    self.writeCommandFromName('Power OFF')
