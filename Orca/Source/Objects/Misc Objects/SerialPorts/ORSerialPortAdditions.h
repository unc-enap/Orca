//
//  ORSerialPortAdditions.h
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

//  Modified from ORSerialPortList.h by Andreas Mayer


#import "ORSerialPort.h"

#define	AMSER_MAXBUFSIZE	4096
#define ORSerialWriteInBackgroundProgressNotification @"ORSerialWriteInBackgroundProgressNotification"
#define ORSerialReadInBackgroundDataNotification @"ORSerialReadInBackgroundDataNotification"


@interface NSObject (ORSerialDelegate)
- (void)serialPortReadData:(NSDictionary *)dataDictionary;
- (void)serialPortWriteProgress:(NSDictionary *)dataDictionary;
@end


@interface ORSerialPort (ORSerialPortAdditions)
-(void) reportProgress:(int) progress dataLen:(unsigned int)dataLen;

// returns the number of bytes available in the input buffer
- (int)checkRead;

- (void)waitForInput:(id)target selector:(SEL)selector;

// reads up to AMSER_MAXBUFSIZE bytes from the input buffer
- (NSString *)readString;

// write string to the serial port
- (int)writeString:(NSString *)string;
- (int) writeCharArray:(const unsigned char *)charArray length:(int)theLength;
- (int) readCharArray:(unsigned char *)buffer length:(int)theLength;

- (void)readDataInBackground;
//
// Will send serialPortReadData: to delegate
// the dataDictionary object will contain these entries:
// 1. "serialPort": the ORSerialPort object that sent the message
// 2. "data": (NSData *)data - received data

- (void)stopReadInBackground;

- (void)writeDataInBackground:(NSData *)data;
//
// Will send serialPortWriteProgress: to delegate if task lasts more than
// approximately three seconds.
// the dataDictionary object will contain these entries:
// 1. "serialPort": the ORSerialPort object that sent the message
// 2. "value": (NSNumber *)value - bytes sent
// 3. "total": (NSNumber *)total - bytes total

- (void)stopWriteInBackground;

- (int)numberOfWriteInBackgroundThreads;

- (void)writeDataInBackgroundThread:(NSData *)data;
- (void)readDataInBackgroundThread;


@end
