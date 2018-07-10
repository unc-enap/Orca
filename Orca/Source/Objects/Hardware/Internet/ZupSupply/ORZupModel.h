//
//  ORZupModel.h
//  Orca
//
//  Created by Mark Howe on Monday March 16,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files

#import "ORRamperModel.h"

@class ORSerialPort;

@interface ORZupModel : ORRamperModel
{
	NSString*			portName;
	BOOL				portWasOpen;
	ORSerialPort*		serialPort;
	NSData*				lastRequest;
	NSMutableArray*		cmdQueue;
	NSMutableData*		inComingData;
	NSMutableString*    buffer;
	float				voltage;
    int					boardAddress;
	BOOL				sentAddress;
    BOOL				outputState;
    float				actualCurrent;
    float				current;
    int					statusRegister;
    int					faultRegister;
    int faultEnableMask;
    int statusEnableMask;
    float actualVoltage;
}

#pragma mark ***Accessors
- (float) actualVoltage;
- (void) setActualVoltage:(float)aActualVoltage;
- (int) statusEnableMask;
- (void) setStatusEnableMask:(int)aStatusEnableMask;
- (int) faultEnableMask;
- (void) setFaultEnableMask:(int)aFaultEnableMask;
- (int) faultRegister;
- (void) setFaultRegister:(int)aFaultRegister;
- (int) statusRegister;
- (void) setStatusRegister:(int)aStatusRegister;
- (float) current;
- (void) setCurrent:(float)aCurrent;
- (float) actualCurrent;
- (void) setActualCurrent:(float)aActualCurrent;
- (BOOL) sentAddress;
- (BOOL) outputState;
- (void) setOutputState:(BOOL)aOutputState;
- (int) boardAddress;
- (void) setBoardAddress:(int)aBoardAddress;
- (float) voltage:(int)dummy;
- (void) setVoltage:(int)dummy withValue:(float)aValue;
- (float) voltage;
- (void) setVoltage:(float)aValue;
- (void) loadDac:(int)dummy;
- (float) upperLimit;
- (float) lowerLimit;
- (SEL) getMethodSelector;
- (SEL) setMethodSelector;
- (SEL) initMethodSelector;
- (int) numberOfChannels;
- (void) initBoard;
- (void) turnOff;

- (void) dataReceived:(NSNotification*)note;
- (ORSerialPort*) serialPort;
- (void) setSerialPort:(ORSerialPort*)aSerialPort;
- (BOOL) portWasOpen;
- (void) setPortWasOpen:(BOOL)aPortWasOpen;
- (NSString*) portName;
- (void) setPortName:(NSString*)aPortName;
- (NSData*) lastRequest;
- (void) setLastRequest:(NSData*)aRequest;
- (void) openPort:(BOOL)state;
- (void) serialPortWriteProgress:(NSDictionary *)dataDictionary;
- (void) getStatus;
- (void) togglePower;
- (void) sendFailEnableMask;
- (void) sendStatusEnableMask;

//helper methods (useful for scripting)
- (void) setImmediatelyToVoltage:(float)aVoltage;
- (void) setImmediatelyToCurrent:(float)aCurrent;

#pragma mark ***Utilities
- (void) sendCmd:(NSString*)aCommand;
- (void) sendCmd:(NSString*)aCommand value:(short)hexData;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORZupModelActualVoltageChanged;
extern NSString* ORZupModelStatusEnableMaskChanged;
extern NSString* ORZupModelFaultEnableMaskChanged;
extern NSString* ORZupModelFaultRegisterChanged;
extern NSString* ORZupModelStatusRegisterChanged;
extern NSString* ORZupModelCurrentChanged;
extern NSString* ORZupModelActualCurrentChanged;
extern NSString* ORZupModelOutputStateChanged;
extern NSString* ORZupModelBoardAddressChanged;
extern NSString* ORZupLock;
extern NSString* ORZupModelSerialPortChanged;
extern NSString* ORZupModelPortStateChanged;
extern NSString* ORZupModelPortNameChanged;

