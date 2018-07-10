//
//  ORSerialPort.m
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

//  Modified from ORSerialPort.m by Andreas Mayer


#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <paths.h>
#include <termios.h>
#include <sysexits.h>
#include <sys/param.h>

#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"


NSString* ORSerialPortStateChanged = @"ORSerialPortStateChanged";
NSString* ORSerialPortDataReceived = @"ORSerialPortDataReceived";

@implementation ORSerialPort

- (id)init:(NSString*) path withName:(NSString*) name
{
	self = [super init];
	bsdPath			 = [path retain];
	serviceName		 = [name retain];
	optionsDictionary = [[NSMutableDictionary dictionaryWithCapacity:8] retain];
	options = malloc(sizeof(*options));
	originalOptions = malloc(sizeof(*originalOptions));
	timeout = malloc(sizeof(*timeout));
	readfds = malloc(sizeof(*readfds));
	fileDescriptor = -1;
	
	writeLock = [[NSLock alloc] init];
	stopWriteInBackgroundLock = [[NSLock alloc] init];
	countWriteInBackgroundThreadsLock = [[NSLock alloc] init];
	readLock = [[NSLock alloc] init];
	stopReadInBackgroundLock = [[NSLock alloc] init];
	countReadInBackgroundThreadsLock = [[NSLock alloc] init];
	closeLock = [[NSLock alloc] init];
	
	return self;
}

- (void)dealloc;
{
	if (fileDescriptor != -1) [self close];
    [self setDelegate:nil];
	[countReadInBackgroundThreadsLock release];
	[stopReadInBackgroundLock release];
	[readLock release];
	[bsdPath release];
	[serviceName release];
	[optionsDictionary release];
	[countWriteInBackgroundThreadsLock release];
	[stopWriteInBackgroundLock release];
	[writeLock release];
	[closeLock release];
	[fileHandle release];
	[readTimer release];
	
	if (buffer != nil)	free(buffer);
	if (readfds != nil)	free(readfds);
	if (timeout != nil)	free(timeout);
	if (originalOptions != nil)free(originalOptions);
	if (options != nil)	free(options);
	[super dealloc];
}


- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)newDelegate
{
    delegate = newDelegate;
    //delegateHandlesReadInBackground = [delegate respondsToSelector:@selector(serialPortReadData:)];
    delegateHandlesWriteInBackground = [delegate respondsToSelector:@selector(serialPortWriteProgress:)];
}


- (NSString*) bsdPath
{
	return bsdPath;
}

- (NSString*) name
{
	return serviceName;
}

- (BOOL)isOpen
{
	// YES if port is open
	return (fileDescriptor >= 0);
}

- (ORSerialPort*) obtainBy:(id)sender
{
	// get this port exclusively; NULL if it's not free
	if (owner == nil) {
		owner = sender;
		return self;
	} 
    else return nil;
}

- (void)free
{
	// give it back
	owner = nil;
	[self close];	// you never know ...
}

- (BOOL)available
{
	// check if port is free and can be obtained
	return (owner == nil);
}

- (id)owner
{
	// who obtained the port?
	return owner;
}


- (NSFileHandle*) open        // use returned file handle to read and write
{
    return [self open:NO];
}

- (NSFileHandle*) openRaw        // use returned file handle to read and write
{
    return [self open:YES];
}

- (NSFileHandle*) open:(BOOL)isRaw
{
    // use returned file handle to read and write
	const char* thePath = [bsdPath cStringUsingEncoding:NSASCIIStringEncoding];
	fileDescriptor = open(thePath, O_RDWR | O_NOCTTY); // | O_NONBLOCK);
	NSLog(@"opened: %@\n", bsdPath);
	
	if (fileDescriptor < 0){
		NSLog(@"Error opening serial port %@ - %s(%d).\n", bsdPath, strerror(errno), errno);
		goto error;
	}
	
	
	// Get the current options and save them for later reset
	if (tcgetattr(fileDescriptor, originalOptions) == -1)
	{
		NSLog(@"Error getting tty attributes %@ - %s(%d).\n", bsdPath, strerror(errno), errno);
		goto error;
	}
	// Get a copy for local options
	tcgetattr(fileDescriptor, options);
    if(isRaw) cfmakeraw(options);

	// Success
	fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSerialPortStateChanged object:self];
    [self readDataInBackground];
	//NSLog(@"fileHandle retain count: %d\n", [fileHandle retainCount]);
	return fileHandle;
	
	// Failure path
error:
    if (fileDescriptor >= 0) close(fileDescriptor);
	fileDescriptor = -1;
	
	return NULL;
}


- (void) close
{
	//int err;
	// Traditionally it is good to reset a serial port back to
	// the state in which you found it.  Let's continue that tradition.
    @synchronized(self){
        if (fileDescriptor >= 0) {
            [self stopReadInBackground];
            [closeLock lock];
            // kill pending read by setting O_NONBLOCK
            if (fcntl(fileDescriptor, F_SETFL, fcntl(fileDescriptor, F_GETFL, 0) | O_NONBLOCK) == -1){
                NSLog(@"Error clearing O_NONBLOCK %@ - %s(%d).\n", bsdPath, strerror(errno), errno);
            }
            
            if (tcsetattr(fileDescriptor, TCSANOW, originalOptions) == -1){
                NSLog(@"Error resetting tty attributes - %s(%d).\n", 				strerror(errno), errno);
            }
            
            [readTarget release];
            readTarget = nil;
            
            [readTimer release];
            readTimer = nil;
            
            [fileHandle closeFile];
            [fileHandle release];
            fileHandle = nil;
            
            NSLog(@"closed: %@\n", bsdPath);
            close(fileDescriptor);
            
            fileDescriptor = -1;
            [closeLock unlock];
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORSerialPortStateChanged object:self];
        }
    }
}

-(void)drainInput
{
	tcdrain(fileDescriptor);
}

-(void)flushInput:(bool)fIn Output:(bool)fOut	// (fIn or fOut) must be YES
{
	int mode = 0;
	if (fIn == YES) mode = TCIFLUSH;
	if (fOut == YES)mode = TCOFLUSH;
	if (fIn && fOut)mode = TCIOFLUSH;
	
	tcflush(fileDescriptor, mode);
}

-(void)sendBreak
{
	tcsendbreak(fileDescriptor, 0);
}


// read and write serial port settings through a dictionary

- (void) buildOptionsDictionary
{
	[optionsDictionary removeAllObjects];
	[optionsDictionary setObject:[self name]
												forKey:ORSerialOptionServiceName];
	[optionsDictionary setObject:[NSString stringWithFormat:@"%ld", [self getSpeed]]
												forKey:ORSerialOptionSpeed];
	[optionsDictionary setObject:[NSString stringWithFormat:@"%d", [self getDataBits]]
												forKey:ORSerialOptionDataBits];
	if ([self testParity]) {
		if ([self testParityOdd]) {
			[optionsDictionary setObject:@"Odd" forKey:ORSerialOptionParity];
		} 
        else {
			[optionsDictionary setObject:@"Even" forKey:ORSerialOptionParity];
		}
	}
	
	[optionsDictionary setObject:[NSString stringWithFormat:@"%d", [self getStopBits]]
												forKey:ORSerialOptionStopBits];
	if ([self testRTSInputFlowControl])  [optionsDictionary setObject:@"RTS" forKey:ORSerialOptionInputFlowControl];
	if ([self testDTRInputFlowControl])  [optionsDictionary setObject:@"DTR" forKey:ORSerialOptionInputFlowControl];
	
	if ([self testCTSOutputFlowControl]) [optionsDictionary setObject:@"CTS" forKey:ORSerialOptionOutputFlowControl];
	if ([self testDSROutputFlowControl]) [optionsDictionary setObject:@"DSR" forKey:ORSerialOptionOutputFlowControl];
	if ([self testCAROutputFlowControl]) [optionsDictionary setObject:@"CAR" forKey:ORSerialOptionOutputFlowControl];
	
	if ([self testEchoEnabled]) [optionsDictionary setObject:@"YES" forKey:ORSerialOptionEcho];
}

- (NSDictionary*) getOptions
{
	// will open the port to get options if neccessary
	if ([optionsDictionary objectForKey:ORSerialOptionServiceName] == nil){
		if (!fileHandle) {
			[self open];
			[self buildOptionsDictionary];
			[self close];
		}
        else if(options) [self buildOptionsDictionary];
	}
    else if(options){
        [self buildOptionsDictionary];
    }
	return [NSMutableDictionary dictionaryWithDictionary:optionsDictionary];
}

- (void)setOptions:(NSDictionary*) newOptions
{
	// ORSerialOptionServiceName HAS to match! You may NOT switch ports using this
	// method.
	NSString *temp;
	
	if ([(NSString*) [newOptions objectForKey:ORSerialOptionServiceName] isEqualToString:[self name]]){
		[optionsDictionary addEntriesFromDictionary:newOptions];
		// parse dictionary
		temp = (NSString*) [optionsDictionary objectForKey:ORSerialOptionSpeed];
		[self setSpeed:[temp intValue]];
		
		temp = (NSString*) [optionsDictionary objectForKey:ORSerialOptionDataBits];
		[self setDataBits:[temp intValue]];
		
		temp = (NSString*) [optionsDictionary objectForKey:ORSerialOptionParity];
		if (temp == nil)                        [self setParityNone];
		else if ([temp isEqualToString:@"Odd"]) [self setParityOdd];
		else                                    [self setParityEven];
		
		temp = (NSString*) [optionsDictionary objectForKey:ORSerialOptionStopBits];
		[self setStopBits2:([temp intValue] == 2)];
		
		temp = (NSString*) [optionsDictionary objectForKey:ORSerialOptionInputFlowControl];
		[self setRTSInputFlowControl:[temp isEqualToString:@"RTS"]];
		[self setDTRInputFlowControl:[temp isEqualToString:@"DTR"]];
		
		temp = (NSString*) [optionsDictionary objectForKey:ORSerialOptionOutputFlowControl];
		[self setCTSOutputFlowControl:[temp isEqualToString:@"CTS"]];
		[self setDSROutputFlowControl:[temp isEqualToString:@"DSR"]];
		[self setCAROutputFlowControl:[temp isEqualToString:@"CAR"]];
		
		temp = (NSString*) [optionsDictionary objectForKey:ORSerialOptionEcho];
		[self setEchoEnabled:(temp != nil)];
		
		[self commitChanges];
	} else NSLog(@"Error setting options for port %s (wrong port name: %s).\n", [self name], [newOptions objectForKey:ORSerialOptionServiceName]);
}


-(long)getSpeed
{
	return cfgetospeed(options);	// we should support cfgetispeed too
}

-(void)setSpeed:(long)speed
{
	cfsetospeed(options, speed);
	cfsetispeed(options, 0);		// same as output speed
	// we should support setting input and output speed separately
}


-(int)getDataBits
{
	return 5 + ((options->c_cflag & CSIZE) >> 8);
}

-(void)setDataBits:(int)bits	// 5 to 8 (5 is marked as "(pseudo)")
{
	// ?? options->c_oflag &= ~OPOST;
	options->c_cflag &= ~CSIZE;
	switch (bits){
		case 5:	options->c_cflag |= CS5;	break; // redundant since CS5 == 0
		case 6:	options->c_cflag |= CS6;    break;
		case 7:	options->c_cflag |= CS7;    break;
		case 8:	options->c_cflag |= CS8;    break;
	}
}

-(bool)testParity
{
	// NO for "no parity"
	return (options->c_cflag & PARENB);
}

-(bool)testParityOdd
{
	// meaningful only if TestParity == YES
	return (options->c_cflag & PARODD);
}

-(void)setParityNone
{
	options->c_cflag &= ~PARENB;
}

-(void)setParityEven
{
	options->c_cflag |= PARENB;
	options->c_cflag &= ~PARODD;
}

-(void)setParityOdd
{
	options->c_cflag |= PARENB;
	options->c_cflag |= PARODD;
}


-(int)getStopBits
{
	if (options->c_cflag & CSTOPB)  return 2;
	else                            return 1;
}

-(void)setStopBits2:(bool)two
{
	if (two) options->c_cflag |= CSTOPB;
	else options->c_cflag &= ~CSTOPB;
}


-(bool)testEchoEnabled
{
	return (options->c_lflag & ECHO);
}

-(void)setEchoEnabled:(bool)echo
{
	if (echo == YES) options->c_lflag |= ECHO;
	else             options->c_lflag &= ~ECHO;
}

-(bool)testRTSInputFlowControl
{
	return (options->c_cflag & CRTS_IFLOW);
}

-(void)setRTSInputFlowControl:(bool)rts
{
	if (rts == YES) options->c_cflag |= CRTS_IFLOW;
	else            options->c_cflag &= ~CRTS_IFLOW;
}


-(bool)testDTRInputFlowControl
{
	return (options->c_cflag & CDTR_IFLOW);
}

-(void)setDTRInputFlowControl:(bool)dtr
{
	if (dtr == YES) options->c_cflag |= CDTR_IFLOW;
	else            options->c_cflag &= ~CDTR_IFLOW;
}


-(bool)testCTSOutputFlowControl
{
	return (options->c_cflag & CCTS_OFLOW);
}

-(void)setCTSOutputFlowControl:(bool)cts
{
	if (cts == YES) options->c_cflag |= CCTS_OFLOW;
	else            options->c_cflag &= ~CCTS_OFLOW;
}


-(bool)testDSROutputFlowControl
{
	return (options->c_cflag & CDSR_OFLOW);
}

-(void)setDSROutputFlowControl:(bool)dsr
{
	if (dsr == YES) options->c_cflag |= CDSR_OFLOW;
	else            options->c_cflag &= ~CDSR_OFLOW;
}


-(bool)testCAROutputFlowControl
{
	return (options->c_cflag & CCAR_OFLOW);
}

-(void)setCAROutputFlowControl:(bool)car
{
	if (car == YES) options->c_cflag |= CCAR_OFLOW;
	else            options->c_cflag &= ~CCAR_OFLOW;
}


-(bool)testHangupOnClose
{
	return (options->c_cflag & HUPCL);
}

-(void)setHangupOnClose:(bool)hangup
{
	if (hangup == YES)  options->c_cflag |= HUPCL;
	else                options->c_cflag &= ~HUPCL;
}

- (bool)getLocal
{
	return (options->c_cflag & CLOCAL);
}

- (void)setLocal:(bool)local	// YES = ignore modem status lines
{
	if (local == YES)   options->c_cflag |= CLOCAL;
	else                options->c_cflag &= ~CLOCAL;
}


-(bool)commitChanges
{
	// call this after using any of the above Set functions
	if (tcsetattr(fileDescriptor, TCSANOW, options) == -1){
		// something went wrong
		lastError = errno;
		NSLogColor([NSColor redColor],@"Serial port Error %s\n", strerror( errno ) );

		return NO;
	}
	else {
		[self buildOptionsDictionary];
		return YES;
	}
}

-(int)errorCode
{
	// if CommitChanges returns NO, look here for further info
	return lastError;
}
- (NSString*)description
{
    return [self name];
}
@end
