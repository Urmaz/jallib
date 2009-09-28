#!/usr/bin/python
#
#
# Title: jallib USB bootloader driver
# Author: Albert Faber, Copyright (c) 2009, all rights reserved.
# Adapted-by:
# Compiler:
#
# This file is part of jallib (http://jallib.googlecode.com)
# Released under the BSD license (http://www.opensource.org/licenses/bsd-license.php)
#
# Sources:
#
# Description: low level USB driver function
#
# Dependencies: you'll need to install the LIBUSB package in order to use the driver
#
# Notes:
#

import sys
import os
import usb
import time
from array import array

import intelhex
from intelhex import IntelHex


class DeviceDescriptor: 
	 def __init__(self, vendor_id, product_id, interface_id) : 
		  self.vendor_id = vendor_id 
		  self.product_id = product_id 
		  self.interface_id = interface_id 

	 def get_device(self) : 
		  buses = usb.busses() 
		  for bus in buses : 
				for device in bus.devices : 
					 if device.idVendor == self.vendor_id : 
						  if device.idProduct == self.product_id : 
								return device 
		  return None
		  

class UsbBootLoaderDriverError( IOError ):
	"errors raised by UsbBootLoaderDriver, derived from IOError"
	pass


class UsbBootLoaderDriver():

	# USB related constants
	TIMEOUT_XMIT = 1200 
	TIMEOUT_RECV = 1200 
	
	VENDOR_ID     = 0x04D8   #: Vendor Id 
	PRODUCT_ID    = 0x000b   #: Product Id for the bridged usb cable 
	INTERFACE_ID  = 0        #: The interface we use to talk to the device 
	BULK_IN_EP    = 0x81     #: Endpoint for Bulk reads 
	BULK_OUT_EP   = 0x01     #: Endpoint for Bulk writes 
	PACKET_LENGTH = 0x40     #: 64 bytes 
	 
	# Bootloader commands
	CMD_READ_VERSION    = 0x00
	CMD_READ_FLASH      = 0x01
	CMD_WRITE_FLASH     = 0x02
	CMD_ERASE_FLASH     = 0x03
	CMD_READ_EEDATA     = 0x04
	CMD_WRITE_EEDATA    = 0x05
	CMD_READ_CONFIG     = 0x06
	CMD_WRITE_CONFIG    = 0x07
	CMD_UPDATE_LED      = 0x32
	CMD_RESET           = 0xFF

	tx_buffer = []
	rx_buffer = []

	Error_Prefix = ''

	# make device descriptor
	device_descriptor = DeviceDescriptor(VENDOR_ID, PRODUCT_ID, INTERFACE_ID )
	
		
	def Raise( self, Message ):
		"""raise a UsbBootLoaderDriver with suitable prefix"""
		# print "RAISE EXCEPTION"	
		#raise UsbBootLoaderDriverError, self.Error_Prefix + Message
		raise Message


	def __init__(self,) : 
		# The actual device (PyUSB object) 
		self.device = self.device_descriptor.get_device() 

		# Handle that is used to communicate with device. Setup in L{open} 
		self.handle = None 


	def _open_device( self ) : 
		""" Open device interface """ 
	
		if ( self.handle != None ) :
			_close_device()
			
		self.device = self.device_descriptor.get_device() 
		
		if self.device: 
			try: 
				self.handle = self.device.open() 
				self.handle.setConfiguration( 1 )
				self.handle.claimInterface(self.device_descriptor.interface_id) 
			except Exception, err: 
				self.Raise( err )		

	def _close_device( self ):   
		""" Release device interface """ 
		if ( self.handle != None ) :
			try: 
				#self.handle.reset() 
				self.handle.releaseInterface() 
			except Exception, err: 
				self.Raise( err )		
			self.handle, self.device = None, None 

		
	def _ExchangeMessage( self, rx_bytes ) :
		""" exchange message with firmware """
		
		if ( self.handle == None ) :
			self._open_device()
		if ( self.handle == None ) :
			self.Raise( "USB device not found" )										  
		
		tx_bytes = self.handle.bulkWrite(self.BULK_OUT_EP, self.tx_buffer, self.TIMEOUT_XMIT)
		
		if ( tx_bytes != len( self.tx_buffer) )  :
			self.Raise( "ExchangeMessage  bulkWrite failed" )
		else:
			if rx_bytes > 0 :
				self.rx_buffer = self.handle.bulkRead(self.BULK_IN_EP, rx_bytes, self.TIMEOUT_RECV)
			
				if ( len( self.rx_buffer ) != rx_bytes )  :
					self.Raise( "ExchangeMessage  bulkRead failed" )

	def OpenDevice( self ) : 
		self._open_device()

	def CloseDevice( self ) : 
		self._close_device()

	def EraseFlashBlock( self, num_blocks, addr_u, addr_h, addr_l ) :
		""" erase flash N blocks of 64 bytes"""	

		# log the address
		# print"Erase flash " + "%02X" % addr_u + "%02X" % addr_h + "%02X" % addr_l 
		
		self.tx_buffer = chr( self.CMD_ERASE_FLASH ) + chr(num_blocks) + chr(addr_l) + chr(addr_h) + chr(addr_u)
		self._ExchangeMessage( 1 )
		
	def WriteFlashBlock( self, buffer, addr_u, addr_h, addr_l ) :
		""" write flash block if 16 bytes to the firmware """	

		# log the address
		# print"Write to flash " + "%02X" % addr_u + "%02X" % addr_h + "%02X" % addr_l 
		
		assert len( buffer ) == 16
		
		self.tx_buffer = chr( self.CMD_WRITE_FLASH ) + chr(len( buffer )) + chr(addr_l) + chr(addr_h) + chr(addr_u)
		
		for i in range( 0, 16 ) :
			self.tx_buffer = self.tx_buffer + chr( buffer[ i ] ) 
		
		self._ExchangeMessage( 1 )
		

	def ReadFlashBlock( self, addr_u, addr_h, addr_l, num_read_bytes ) :
		""" read flash block from firmware """	
		self.tx_buffer = chr( self.CMD_READ_FLASH ) + chr(num_read_bytes) + chr(addr_l) + chr(addr_h) + chr(addr_u)
		self._ExchangeMessage( len( self.tx_buffer) + num_read_bytes )
		
		# remove command response from received data buffer
		self.rx_buffer = self.rx_buffer[ len( self.tx_buffer): ]
		
		return self.rx_buffer
											

	def ReadVersion( self ) :
		self.tx_buffer = chr( self.CMD_READ_VERSION ) + chr(0) + chr(0) + chr(0) + chr(0)

		self._ExchangeMessage( 4 )

		return str( int( self.rx_buffer[3])) + "." + str( int(self.rx_buffer[2]))
						  
	def Reset( self ) :
		self.tx_buffer = chr( self.CMD_RESET )

		self._ExchangeMessage( 0 )

		return str( int( self.rx_buffer[3])) + "." + str( int(self.rx_buffer[2]))


