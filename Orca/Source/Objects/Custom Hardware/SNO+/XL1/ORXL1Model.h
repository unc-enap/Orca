//
//  ORXL1Model.h
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORVmeCard.h"
@class ORCommandList;

#define kNumFecMonitorAdcs		21
#define kAllowedFecMonitorError	0.1

@interface ORXL1Model :  ORVmeCard 
{
	@private
		NSString*		connectorName;
		ORConnector*	connector; //we won't draw this connector.
		NSString*		xilinxFile;
		float			adcClock;
		float			sequencerClock;
		float			memoryClock;
		float			adcAllowedError[kNumFecMonitorAdcs];
		NSString*		clockFile;
		NSString*		cableFile;
}

#pragma mark •••Connection Stuff
- (void) positionConnector:(ORConnector*)aConnector;
- (NSString*) connectorName;
- (void) setConnectorName:(NSString*)aName;
- (ORConnector*) connector;
- (void) setConnector:(ORConnector*)aConnector;
- (void) setUpImage;
- (void) setSlot:(int)aSlot;
- (void) makeConnectors;
- (void) setGuardian:(id)aGuardian;
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;
- (void) setCrateNumbers;
- (id)   getXL1;

#pragma mark •••Accessors
- (NSString*)	clockFile;
- (void)	setClockFile:(NSString*)aClockFile;
- (NSString*)	xilinxFile;
- (void)	setXilinxFile:(NSString*)aFilePath;
- (NSString*)	cableFile;
- (void)	setCableFile:(NSString*)aFilePath;
- (float)		adcClock;
- (void)		setAdcClock:(float)aValue;
- (float)		sequencerClock;
- (void)		setSequencerClock:(float)aValue;
- (float)		memoryClock;
- (void)		setMemoryClock:(float)aValue;
- (float)		adcAllowedError:(short)anIndex;
- (void)		setAdcAllowedError:(short)anIndex withValue:(float)aValue;
- (NSData*)		clockFileData;
- (NSData*)		xilinxFileData;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Hardware Access
- (void) writeHardwareRegister:(unsigned long) regAddress value:(unsigned long) aValue;
- (unsigned long) readHardwareRegister:(unsigned long) regAddress;
- (id) writeHardwareRegisterCmd:(unsigned long) regAddress value:(unsigned long) aValue;
- (id) readHardwareRegisterCmd:(unsigned long) regAddress;
- (void) executeCommandList:(ORCommandList*)aList;
- (id) delayCmd:(unsigned long) milliSeconds;

@end


extern NSString* ORXL1ClockFileChanged;
extern NSString* ORXL1XilinxFileChanged;
extern NSString* ORXL1CableFileChanged;
extern NSString* ORXL1AdcClockChanged;
extern NSString* ORXL1SequencerClockChanged;
extern NSString* ORXL1MemoryClockChanged;
extern NSString* ORXL1AlowedErrorsChanged;
extern NSString* ORXL1Lock;


