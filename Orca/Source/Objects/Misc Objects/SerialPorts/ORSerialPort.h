//
//  ORSerialPort.h
//  ORCA
//
//  Created by Mark Howe on Mon Feb 10 2003.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

//  Modified from ORSerialPort.h by Andreas Mayer


#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <paths.h>
#include <termios.h>
#include <sysexits.h>
#include <sys/param.h>



#define	ORSerialOptionServiceName   @"ORSerialOptionServiceName"
#define	ORSerialOptionSpeed         @"ORSerialOptionSpeed"
#define	ORSerialOptionDataBits      @"ORSerialOptionDataBits"
#define	ORSerialOptionParity        @"ORSerialOptionParity"
#define	ORSerialOptionStopBits      @"ORSerialOptionStopBits"
#define	ORSerialOptionInputFlowControl  @"ORSerialOptionInputFlowControl"
#define	ORSerialOptionOutputFlowControl @"ORSerialOptionOutputFlowControl"
#define	ORSerialOptionEcho          @"ORSerialOptionEcho"


@interface ORSerialPort : NSObject
{
	NSString* bsdPath;
	NSString* serviceName;
	int fileDescriptor;
	struct termios* options;
	struct termios* originalOptions;
	NSMutableDictionary* optionsDictionary;
	NSFileHandle *fileHandle;
	int	lastError;
	id owner;
	// used by ORSerialPortAdditions only:
	char*		buffer;
	NSTimer*	readTimer;
	id			readTarget;
	SEL			readSelector;
	struct timeval*	timeout;
	fd_set*		readfds;
	id			delegate;
	BOOL delegateHandlesWriteInBackground;
	
	NSLock* writeLock;
	NSLock* stopWriteInBackgroundLock;
	NSLock* countWriteInBackgroundThreadsLock;
	NSLock* readLock;
	NSLock* stopReadInBackgroundLock;
	NSLock* countReadInBackgroundThreadsLock;
	NSLock* closeLock;
	BOOL stopWriteInBackground;
	BOOL stopReadInBackground;
	int countWriteInBackgroundThreads;
	int countReadInBackgroundThreads;
}

- (id)init:(NSString*) path withName:(NSString*) name;  //path is a bsdPath, name is IOKit service name
- (NSString*) bsdPath;                                  // returns the bsdPath (e.g. '/dev/cu.modem')
- (NSString*) name;                                     // returns tho IOKit service name (e.g. 'modem')
- (BOOL) isOpen;
- (ORSerialPort*) obtainBy:(id)sender;                  // get this port exclusively; NULL if it's not free
- (void) free;                                          // give it back (and close the port if still open)
- (BOOL) available;
- (id) owner;                                           // who obtained the port?
- (NSFileHandle*) open;
- (NSFileHandle*) openRaw;       // use returned file handle to read and write
- (NSFileHandle*) open:(BOOL)isRaw;
- (void) close;
- (void) drainInput;
- (void) flushInput:(bool)fIn Output:(bool)fOut;        // (fIn or fOut) must be YES
- (void) sendBreak;

- (NSDictionary*) getOptions;                           // will open the port to get options if neccessary
- (void) setOptions:(NSDictionary *)options;             

- (long) getSpeed;
- (void) setSpeed:(long)speed;

- (int) getDataBits;
- (void) setDataBits:(int)bits;                          // 5 to 8 (5 may not work)

- (bool) testParity;                                     // NO for "no parity"
- (bool) testParityOdd;                                  // meaningful only if TestParity == YES
- (void) setParityNone;
- (void) setParityEven;
- (void) setParityOdd;

- (int) getStopBits;
- (void) setStopBits2:(bool)two;

- (bool) testEchoEnabled;
- (void) setEchoEnabled:(bool)echo;

- (bool) testRTSInputFlowControl;
- (void) setRTSInputFlowControl:(bool)rts;

- (bool) testDTRInputFlowControl;
- (void) setDTRInputFlowControl:(bool)dtr;

- (bool) testCTSOutputFlowControl;
- (void) setCTSOutputFlowControl:(bool)cts;

- (bool) testDSROutputFlowControl;
- (void) setDSROutputFlowControl:(bool)dsr;

- (bool) testCAROutputFlowControl;
- (void) setCAROutputFlowControl:(bool)car;

- (bool) testHangupOnClose;
- (void) setHangupOnClose:(bool)hangup;

- (bool) getLocal;
- (void) setLocal:(bool)local;                               // YES = ignore modem status lines

- (bool) commitChanges;                                      // call this after using any of the above Set functions
- (int) errorCode;                                           // if CommitChanges returns NO, look here for further info

- (id) delegate;
- (void)setDelegate:(id)newDelegate;


@end

extern NSString* ORSerialPortStateChanged;
extern NSString* ORSerialPortDataReceived;
