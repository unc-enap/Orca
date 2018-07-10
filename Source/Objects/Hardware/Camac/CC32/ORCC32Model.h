/*

File:		CCamacContrlCC32.h

Usage:		Class Definition for the ARW PCI-CAMAC
I/O Kit Kernel Extension (KEXT) Functions

Author:		F. McGirt

Copyright:		Copyright 2003 F. McGirt.  All rights reserved.

Change History:	1/20/03
07/29/03 MAH CENPA. Converted to Obj-C for the ORCA project.


Notes:		PCI Matching is done with
Vendor ID 0x10b5 and Device ID 0x2258
Subsystem Vendor ID 0x9050
Subsystem Device ID 0x2258


There are two "features" of the ARE PCI-CAMAC hardware to
be aware of:

The hardware as delivered may come configured for use with
MS-DOS and force all memory accesses to lie below 1MB. This
will not work for either Mac or Win OSs and must be changed
using the PLX tools for re-programming the EEPROM on board
the PCI card.

The PCI-CAMAC hardware forces all NAF command writes to set
the F16 bit to a 1 and all NAF command reads to set the F16
bit to 0.  Therefore all F values from F0 through F15 MUST
be used with CAMAC bus read accesses and all F values from
F16 through F31 MUST be used with CAMAC bus write accesses.


At times delays must be used between a sequence
of NAF commands or the CC32 status returns
will not reflect the current status - but usually
that of the previous NAF command.  (See the
									CCamacContrlCC32Test object.)  This may possibly
be due to the design of the controller hardware, 
the speed of the PowerMac G4, or to the use of an
optimizing compiler which may relocate memory
accesses.   In an effort to alleviate this problem
all variables used to access PCI-CAMAC memory spaces
are declared volatile.


-----------------------------------------------------------
	This program was prepared for the Regents of the University of 
	Washington at the Center for Experimental Nuclear Physics and 
	Astrophysics (CENPA) sponsored in part by the United States 
	Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
	The University has certain rights in the program pursuant to 
	the contract and the program should not be copied or distributed 
	outside your organization.  The DOE and the University of 
	Washington reserve all rights in the program. Neither the authors,
	University of Washington, or U.S. Government make any warranty, 
	express or implied, or assume any liability or responsibility 
	for the use of this software.
-------------------------------------------------------------


	*/

#pragma mark ¥¥¥Imported Files
#import "ORCamacControllerCard.h"
#import "ORDataTaker.h"


@class ORReadOutList;

// definitions
#define kLCRIntCSROffset		19			// 0x4c / 4 = 0x13 = 19
#define kLCRCntrlOffset		20			// 0x50 / 4 = 0x14 = 20
#define kInitialCC32Status		0x8300
#define kInitialControlStatus	0x4986
#define kEnableCC32				0x4184
//#define kEnableCC32AutoRead     0x4182
#define kEnableCC32AutoRead     0x4184
#define kDisableCC32			0x4084
#define kDisableAllInterrupts	0x0000


#define OExceptionCamacAccessErrorDescription   		@"Camac Address Exception. "
#define OExceptionNoCamacCratePower                     @"No Camac Crate Power"
#define OExceptionBadCamacStatus                        @"Bad Camac Status"

// class definition
@interface ORCC32Model : ORCamacControllerCard <ORDataTaker>
{
	//data taking variables
	ORReadOutList*  readOutGroup;
	id	dataTakers[25];       //cache of data takers arranged by slot
}

- (NSString*) settingsLock;

#pragma mark ¥¥¥Accessors

- (unsigned short)  initializeContrl;	// enable CC32 - no auto read
- (unsigned short)  initializeContrlAuto;// enable CC32 - auto read
- (unsigned short)  disableContrl;		// disable CC32
- (unsigned short)  camacStatus;		// get status
- (ORReadOutList*) readOutGroup;
- (void) setReadOutGroup:(ORReadOutList*)newReadOutGroup;

#pragma mark ¥¥¥Module Cmds
- (unsigned short)  resetContrl;     //can throw
- (unsigned short)	generateQAndX;
- (unsigned short)  setCrateInhibit:(BOOL)state;
- (unsigned short)  readCrateInhibit:(unsigned short*)state;
- (unsigned short)  executeCCycle;
- (unsigned short)  executeZCycle;
- (unsigned short)  executeCCycleIOff;
- (unsigned short)  executeZCycleIOn;
- (unsigned short)  resetLAMFF;
- (unsigned short)  readLAMFFStatus:(unsigned short*)value;
- (unsigned long)   readLEDs;
- (unsigned long)  setLAMMask:(unsigned long) mask;
- (unsigned short)  readLAMMask:(unsigned long *)mask;
- (unsigned short)  readLAMStations:(unsigned long *)stations;
- (unsigned long)  readLEDs;

- (void) delay:(float)delayValue;
- (unsigned short) execute;

- (unsigned short)  camacStatus;		// get status
- (void)  checkCratePower;

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
							 data:(unsigned short*) data;

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f;
								
- (unsigned short)  camacLongNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(unsigned long*) data;


- (unsigned short)  camacShortNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned short*) data
                                length:(unsigned long)   numWords;

- (unsigned short)  camacLongNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned long*) data
                                length:(unsigned long)    numWords;

#pragma mark ¥¥¥DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (int) reset;


@end

extern NSString* ORCC32SettingsLock;
