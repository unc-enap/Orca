//
//  ORIP220Model.cp
//  Orca
//
//  Created by Mark Howe on Tue Jun 5 2007.
//  Copyright Â© 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORIP220Model.h"
#import "ORIPCarrierModel.h"

NSString* ORIP220VoltageChanged 		= @"ORIP220VoltageChanged";
NSString* ORIP220TransferModeChanged 	= @"ORIP220TransferModeChanged";
NSString* ORIP220SettingsLock			= @"ORIP220SettingsLock";

#define kIP220TransparentMode  0
#define kIP220SimultaneousMode 1

@implementation ORIP220Model
#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    hwLock = [[NSLock alloc] init];
	
	int i;
	for(i=0;i<16;i++){
		outputVoltage[i] = 0;
	}
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

-(void)dealloc
{
    [hwLock release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"IP220"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORIP220Controller"];
}

- (NSString*) helpURL
{
	return @"VME/IP220.html";
}

#pragma mark ¥¥¥Accessors
- (float) outputVoltage:(unsigned short)index
{
	if(index<16) return outputVoltage[index];
	else return 0;
}

- (void) setOutputVoltage:(unsigned short)index withValue:(float)aValue
{
	if(index<16){
		[[[self undoManager] prepareWithInvocationTarget:self] setOutputVoltage:index withValue:outputVoltage[index]];
		
		if(aValue< -10)aValue = -10;
		else if(aValue>9.98)aValue = 9.98;
		
		outputVoltage[index] = aValue;
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:ORIP220VoltageChanged
		 object:self
		 userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:@"Channel"]];
	}
}

- (void) setTransferMode:(BOOL)flag
{
	[[[self undoManager] prepareWithInvocationTarget:self] setTransferMode:transferMode];
	transferMode = flag;
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIP220TransferModeChanged
	 object:self];
}

- (BOOL) transferMode
{
	return transferMode;
}

#pragma mark ¥¥¥Hardware Access

- (void) resetBoard
{
	//convert the Voltage values to raw values and load into the hw registers
	id  theController = [guardian adapter];
	unsigned short controlRegValue;
	[theController readWordBlock:&controlRegValue						
					   atAddress:[self baseAddress] + 0x28
					   numToRead:1L
					  withAddMod:[guardian addressModifier]
				   usingAddSpace:kAccessRemoteIO];
	controlRegValue |= 0x0080;
	[theController writeWordBlock:&controlRegValue					
						atAddress:[self baseAddress] + 0x28
					   numToWrite:1L
					   withAddMod:[guardian addressModifier]
					usingAddSpace:kAccessRemoteIO];
	
	int i;
	for(i=0;i<16;i++)outputVoltage[i] = 0;
	[self initBoard];
}

- (void) initBoard
{
	//convert the Voltage values to raw values and load into the hw registers
	int i;
	id  theController = [guardian adapter];
	unsigned short dummy = 1;
	if(transferMode == kIP220SimultaneousMode){
		[theController writeWordBlock:&dummy					//value doesn't matter
							atAddress:[self baseAddress] + 0x24		//offset to the simultaneous write reg.
						   numToWrite:1L
						   withAddMod:[guardian addressModifier]
						usingAddSpace:kAccessRemoteIO];
	}
	for(i=0;i<16;i++){
		if(transferMode == kIP220TransparentMode){
			[theController writeWordBlock:&dummy					//value doesn't matter
								atAddress:[self baseAddress] + 0x20		//offset to the transparent write reg.
							   numToWrite:1L
							   withAddMod:[guardian addressModifier]
							usingAddSpace:kAccessRemoteIO];
		}
		//the least significant bit of the raw data is bit 4, hence the shifth
		unsigned short rawValue = (unsigned short)((204.8*outputVoltage[i]+2048))<<4;
		[theController writeWordBlock:&rawValue
							atAddress:[self baseAddress] + (i*2)
						   numToWrite:1L
						   withAddMod:[guardian addressModifier]
						usingAddSpace:kAccessRemoteIO];
		
	}
	if(transferMode == kIP220SimultaneousMode){
		[theController writeWordBlock:&dummy					//value doesn't matter, the write triggers event
							atAddress:[self baseAddress] + 0x24		//offset to the simultaneous write reg.
						   numToWrite:1L
						   withAddMod:[guardian addressModifier]
						usingAddSpace:kAccessRemoteIO];
	}
	
}

- (void) readBoard
{
	int i;
	id  theController = [guardian adapter];
	unsigned short rawValue;
	for(i=0;i<16;i++){
		@try {
			[theController readWordBlock:&rawValue
							   atAddress:[self baseAddress] + (i*2)
							   numToRead:1L
							  withAddMod:[guardian addressModifier]
						   usingAddSpace:kAccessRemoteIO];
			
			//the least significant bit of the raw data is bit 4, hence the shifth
			float convertedValue = (((rawValue>>4)-2048.)/204.8);
			
			[[self undoManager] disableUndoRegistration];
			[self setOutputVoltage:i withValue:convertedValue];
			[[self undoManager] enableUndoRegistration];
		}
		@catch(NSException* localException) {
			NSLogError(@"Read Exception",@"IP220",nil);
		}
	}
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"%d,%d,%@",[self crateNumber],[guardian slot],[self identifier]];
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	int i;
	for(i=0;i<16;i++){
		[self setOutputVoltage:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"outputVoltage%d",i]]];
	}
	[self setTransferMode:[decoder decodeBoolForKey:@"transferMode"]];
    [[self undoManager] enableUndoRegistration];
    
    hwLock = [[NSLock alloc] init];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	int i;
	for(i=0;i<16;i++){
		[encoder encodeFloat:outputVoltage[i] forKey:[NSString stringWithFormat:@"outputVoltage%d",i]];
	}
	[encoder encodeBool:transferMode forKey:@"transferMode"];
}

@end



