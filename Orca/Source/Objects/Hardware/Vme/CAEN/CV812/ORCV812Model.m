/*
 *  ORCV812Model.m
 *  Orca
 *
 *  Created by Mark Howe on Tuesday, June 7, 2011.
 *  Copyright (c) 2011 CENPA, University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sonsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORCV812Model.h"

#define k812DefaultBaseAddress 		0xF0000000
#define k812DefaultAddressModifier 	0x39

// Define all the registers available to this unit.
static CVCfcLedRegNamesStruct CV812Reg[kNum812Registers] = {
	{@"Threshold 0",		0x00},
	{@"Threshold 1",		0x02},
	{@"Threshold 2",		0x04},
	{@"Threshold 3",		0x06},
	{@"Threshold 4",		0x08},
	{@"Threshold 5",		0x0A},
	{@"Threshold 6",    	0x0C},
	{@"Threshold 7",		0x0E},
	{@"Threshold 8",		0x10},
	{@"Threshold 9",		0x12},
	{@"Threshold 10",		0x14},
	{@"Threshold 11",		0x16},
	{@"Threshold 12",		0x18},
	{@"Threshold 13",    	0x1A},
	{@"Threshold 14",		0x1C},
	{@"Threshold 15",		0x1E},
	
	{@"Output Width 0-7",	0x40},
	{@"Output Width 8-15",	0x42},
	{@"Dead Time 0-7",		0x44},
	{@"Dead Time 8-15",		0x46},

	{@"Majority Thres",		0x48},
	{@"Pattern Inhib",		0x4A},
	{@"Test Pulse",			0x4C},
	
	{@"Fixed Code",			0xFA},
	{@"Module Type",		0xFC},
	{@"Version",			0xFE},
};


NSString* ORCV812ModelDeadTime0_7Changed = @"ORCV812ModelDeadTime0_7Changed";
NSString* ORCV812ModelDeadTime8_15Changed = @"ORCV812ModelDeadTime8_15Changed";

@implementation ORCV812Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k812DefaultBaseAddress];
    [self setAddressModifier:k812DefaultAddressModifier];
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

#pragma mark ***Accessors
- (unsigned long) threshold0Offset			{ return [self regOffset:kThreshold0]; }
- (unsigned long) deadTime0_7Offset			{ return [self regOffset:kDeadTime0_7]; }
- (unsigned long) deadTime8_15Offset		{ return [self regOffset:kDeadTime8_15]; }
- (unsigned long) outputWidth0_7Offset		{ return [self regOffset:kOutputWidt0_7]; }
- (unsigned long) outputWidth8_15Offset		{ return [self regOffset:kOutputWidth8_15]; }
- (unsigned long) testPulseOffset			{ return [self regOffset:kTestPulse]; }
- (unsigned long) patternInibitOffset		{ return [self regOffset:kPatternInhibit]; }
- (unsigned long) majorityThresholdOffset	{ return [self regOffset:kMajorityThreshold]; } 
- (unsigned long) moduleTypeOffset			{ return [self regOffset:kModuleType]; }
- (unsigned long) versionOffset				{ return [self regOffset:kVersion]; }

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CV812"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCV812Controller"];
}

- (NSString*) helpURL
{
	return @"VME/V812.html";
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 812 (Slot %d) ",[self slot]];
}

- (unsigned short) numberOfRegisters { return kNum812Registers; }

- (unsigned long) regOffset:(int)index
{
	if(index >=0 && index<kNum812Registers){
		return CV812Reg[index].addressOffset;
	}
	else return 0;
}

- (unsigned short) deadTime0_7 { return deadTime0_7;}
- (void) setDeadTime0_7:(unsigned short)aDeadTime0_7
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDeadTime0_7:deadTime0_7];
    deadTime0_7 = aDeadTime0_7;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV812ModelDeadTime0_7Changed object:self];
}

- (unsigned short) deadTime8_15 { return deadTime8_15; }
- (void) setDeadTime8_15:(unsigned short)aDeadTime8_15
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDeadTime8_15:deadTime8_15];
    deadTime8_15 = aDeadTime8_15;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV812ModelDeadTime8_15Changed object:self];
}

#pragma mark ***HW Accesss
- (void) initBoard
{
	[super initBoard];
	[self writeDeadTime0_7];
	[self writeDeadTime8_15];
}

- (void) writeDeadTime0_7
{
    [[self adapter] writeWordBlock:&deadTime0_7
                         atAddress:[self baseAddress] +  [self regOffset:kDeadTime0_7]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeDeadTime8_15
{
    [[self adapter] writeWordBlock:&deadTime8_15
                         atAddress:[self baseAddress] +  [self regOffset:kDeadTime8_15]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];
    [[self undoManager] disableUndoRegistration];
	
 	[self setDeadTime0_7:[aDecoder decodeIntForKey:@"deadTime0_7"]];
	[self setDeadTime8_15:[aDecoder decodeIntForKey:@"deadTime8_15"]];
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
    [anEncoder encodeInt:deadTime0_7 forKey:@"deadTime0_7"];
    [anEncoder encodeInt:deadTime8_15 forKey:@"deadTime8_15"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[objDictionary setObject:[NSNumber numberWithInt:deadTime0_7] forKey:@"deadTime0_7"];
    [objDictionary setObject:[NSNumber numberWithInt:deadTime8_15] forKey:@"deadTime8_15"];
    
    return objDictionary;
}

@end


