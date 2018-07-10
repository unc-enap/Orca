//
//  ORXL1Model.m
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
#import "ORXL1Model.h"
#import "ORSNOCrateModel.h"
#import "ORSNOCard.h"
#import "ORCommandList.h"
#import "ORVmeReadWriteCommand.h"
#import "ORSNOCableDB.h"

NSString* ORXL1ClockFileChanged			= @"ORXL1ClockFileChanged";
NSString* ORXL1XilinxFileChanged		= @"ORXL1XilinxFileChanged";
NSString* ORXL1CableFileChanged			= @"ORXL1CableFileChanged";
NSString* ORXL1AdcClockChanged			= @"ORXL1AdcClockChanged";
NSString* ORXL1SequencerClockChanged	= @"ORXL1SequencerClockChanged";
NSString* ORXL1MemoryClockChanged		= @"ORXL1MemoryClockChanged";
NSString* ORXL1AlowedErrorsChanged		= @"ORXL1AlowedErrorsChanged";
NSString* ORXL1Lock						= @"ORXL1Lock";

@implementation ORXL1Model

#pragma mark •••Initialization

- (void) dealloc
{
    [clockFile release];
    [connectorName release];
    [connector release];
    [super dealloc];
}

#pragma mark ***Accessors

- (NSString*) clockFile
{
    return clockFile;
}

- (void) setClockFile:(NSString*)aClockFile
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockFile:clockFile];
    
    [clockFile autorelease];
    clockFile = [aClockFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL1ClockFileChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"XL1Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORXL1Controller"];
}

- (BOOL) solitaryInViewObject
{
	return YES;
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
        
	[ [self connector] setConnectorType: 'XL1O' ];
	[ [self connector] addRestrictedConnectionType: 'XL2I' ]; //can only connect to XL2I inputs
}

- (NSString*) connectorName
{
    return connectorName;
}
- (void) setConnectorName:(NSString*)aName
{
    [aName retain];
    [connectorName release];
    connectorName = aName;
    
}

- (id) getXL1
{
	return self;
}

- (void) setCrateNumbers
{
	//we'll drop in here if any of the XL1/2 connections change -- this is initiated from the XL2s only or we'll get an infinite loop
	//id nextXL2 = [connector connectedObject];
	//[nextXL2 setCrateNumber:0];
}

- (ORConnector*) connector
{
    return connector;
}

- (void) setConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [connector release];
    connector = aConnector;
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORSNOCardSlotChanged
                          object: self];
}

- (void) positionConnector:(ORConnector*)aConnector
{
    NSRect aFrame = [aConnector localFrame];
    float x =  20 + [self slot] * 16 * .62 + 2;
    float y =  25;
    aFrame.origin = NSMakePoint(x,y);
    [aConnector setLocalFrame:aFrame];
}

- (void) setGuardian:(id)aGuardian
{
    
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    
    if(oldGuardian != aGuardian){
        [oldGuardian removeDisplayOf:connector];
    }
    
    [aGuardian assumeDisplayOf:connector];
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (id) adapter
{
	id anAdapter = [[self guardian] adapter];
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No PCI/VME adapter" format:@"Check a PCI/VME adapter is in place and connected to the Mac.\n"];
	return nil;

	return [[self guardian] adapter];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:connector forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:connector];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:connector];
}
- (NSString*) identifier
{
    return [NSString stringWithFormat:@"XL1 (%d,%d)",[self crateNumber],[self slot]];
}
- (void) awakeAfterDocumentLoaded
{
	int i;
	for(i=0;i<kNumFecMonitorAdcs; i++){
		adcAllowedError[i] = kAllowedFecMonitorError;
	}
}

- (NSString*) xilinxFile 
{
	return xilinxFile;
}
- (void)setXilinxFile:(NSString*)aFilePath;
{
	if(!aFilePath)aFilePath = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setXilinxFile:xilinxFile];
	
	[aFilePath retain];
	[xilinxFile release];
	xilinxFile = aFilePath;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL1XilinxFileChanged object:self];
}

- (NSString*) cableFile 
{
	return cableFile;
}

- (void)setCableFile:(NSString*)aFilePath;
{
	if(!aFilePath)aFilePath = @"";
	[[[self undoManager] prepareWithInvocationTarget:self] setCableFile:cableFile];
	
	[aFilePath retain];
	[cableFile release];
	cableFile = aFilePath;
	
	ORSNOCableDB* db = [ORSNOCableDB sharedSNOCableDB];
	[db setCableDBFilePath:[self cableFile]];
		
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL1CableFileChanged object:self];
}


- (float) adcClock
{
	return adcClock;
}
- (void) setAdcClock:(float)aValue;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcClock:adcClock];
	
	adcClock = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL1AdcClockChanged object:self];
}

- (float) sequencerClock
{
	return sequencerClock;
}
- (void) setSequencerClock:(float)aValue;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSequencerClock:sequencerClock];
	
	sequencerClock = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL1SequencerClockChanged object:self];
}

- (float) memoryClock
{
	return memoryClock;
}
- (void) setMemoryClock:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryClock:memoryClock];
	
	memoryClock = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL1MemoryClockChanged object:self];
}

- (float) adcAllowedError:(short)anIndex
{
	return adcAllowedError[anIndex];
}

- (void) setAdcAllowedError:(short)anIndex withValue:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcAllowedError:anIndex withValue:adcAllowedError[anIndex]];
	
	adcAllowedError[anIndex] = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL1AlowedErrorsChanged object:self];
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setClockFile:		[decoder decodeObjectForKey:@"clockFile"]];
    [self setConnectorName:	[decoder decodeObjectForKey:@"connectorName"]];
    [self setConnector:		[decoder decodeObjectForKey:@"connector"]];
	[self setSlot:			[decoder decodeIntForKey:@"slot"]];
	[self setXilinxFile:	[decoder decodeObjectForKey: @"xilinxFile"]];
	[self setCableFile:	[decoder decodeObjectForKey: @"cableFile"]];
    [self setAdcClock:		[decoder decodeFloatForKey: @"adcClock"]];
    [self setSequencerClock:[decoder decodeFloatForKey: @"sequencerClock"]];
    [self setMemoryClock:	[decoder decodeFloatForKey: @"memoryClock"]];
	int i;
	for(i=0;i<kNumFecMonitorAdcs;i++){
		[self setAdcAllowedError:i withValue: [decoder decodeFloatForKey: [NSString stringWithFormat:@"adcAllowedError%d",i]]];
	}
	ORSNOCableDB* db = [ORSNOCableDB sharedSNOCableDB];
	//[db setCableDBFilePath:@"/Users/markhowe/Desktop/CableDB.h"];
	[db setCableDBFilePath:[self cableFile]];
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:clockFile			forKey:@"clockFile"];
    [encoder encodeObject:connectorName		forKey:@"connectorName"];
    [encoder encodeObject:connector			forKey:@"connector"];
	[encoder encodeInt:[self slot]			forKey:@"slot"];
	[encoder encodeObject:xilinxFile		forKey:@"xilinxFile"];
	[encoder encodeObject:cableFile			forKey:@"cableFile"];
	[encoder encodeFloat:adcClock			forKey:@"adcClock"];
	[encoder encodeFloat:sequencerClock		forKey:@"sequencerClock"];
	int i;
	for(i=0;i<kNumFecMonitorAdcs;i++){
		[encoder encodeFloat:adcAllowedError[i] forKey:[NSString stringWithFormat:@"adcAllowedError%d",i]];
	}	
}

- (NSData*) clockFileData
{
	NSData* theData = [NSData dataWithContentsOfFile:clockFile];
	if(![theData length]){
		[NSException raise:@"No Clock Data" format:@"Couldn't open clockFile: %@",[clockFile stringByAbbreviatingWithTildeInPath]];
		return nil; //can't get here, but avoid the compiler warning
	}
	else return theData;
}

- (NSData*) xilinxFileData
{
	NSData* theData = [NSData dataWithContentsOfFile:xilinxFile];
	if(![theData length]){
		[NSException raise:@"No Xilinx Data" format:@"Couldn't open xilinxFile: %@",[xilinxFile stringByAbbreviatingWithTildeInPath]];
		return nil; //can't get here, but avoid the compiler warning
	}
	else return theData;
}

#pragma mark •••Hardware Access

- (void) writeHardwareRegister:(unsigned long) regAddress value:(unsigned long) aValue
{
	[[self adapter] writeLongBlock:&aValue
              atAddress:regAddress
             numToWrite:1
             withAddMod:0x29
          usingAddSpace:0x01];
}

- (unsigned long) readHardwareRegister:(unsigned long) regAddress
{
	unsigned long aValue = 0;
	[[self adapter] readLongBlock:&aValue
              atAddress:regAddress
             numToRead:1
             withAddMod:0x29
          usingAddSpace:0x01];
	
	return aValue;
}

- (id) writeHardwareRegisterCmd:(unsigned long) regAddress value:(unsigned long) aValue
{
	return [ORVmeReadWriteCommand writeLongBlock:&aValue
								  atAddress:regAddress
								 numToWrite:1
								 withAddMod:0x29
							  usingAddSpace:0x01];
}

- (id) readHardwareRegisterCmd:(unsigned long) regAddress
{
	return [ORVmeReadWriteCommand readLongBlockAtAddress:regAddress
						numToRead:1
					   withAddMod:0x29
					usingAddSpace:0x01];
}

- (id) delayCmd:(unsigned long) milliSeconds
{
	return [ORVmeReadWriteCommand delayCmd:milliSeconds];
}

- (void) executeCommandList:(ORCommandList*)aList
{
	[[self adapter] executeCommandList:aList];		
}

@end
