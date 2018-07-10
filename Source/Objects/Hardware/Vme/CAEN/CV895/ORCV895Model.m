/*
 *  ORCV895Model.m
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
#import "ORCV895Model.h"

//Address defaults for this unit.
#define k895DefaultBaseAddress 		0xE0000000
#define k895DefaultAddressModifier 	0x39

//Define all the registers available to this unit.
static CVCfcLedRegNamesStruct CV895Reg[kNum895Registers] = {
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
	
	{@"Majority Thres",		0x48},
	{@"Pattern Inhib",		0x4A},
	{@"Test Pulse",			0x4C},
	
	{@"Fixed Code",			0xFA},
	{@"Module Type",		0xFC},
	{@"Version",			0xFE},
};


@implementation ORCV895Model

#pragma mark ***Initialization
- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k895DefaultBaseAddress];
    [self setAddressModifier:k895DefaultAddressModifier];
	
    [[self undoManager] enableUndoRegistration];
   
    return self;
}

#pragma mark ***Accessors
- (unsigned long) threshold0Offset			{ return [self regOffset:kThreshold0]; }
- (unsigned long) outputWidth0_7Offset		{ return [self regOffset:kOutputWidt0_7]; }
- (unsigned long) outputWidth8_15Offset		{ return [self regOffset:kOutputWidth8_15]; }
- (unsigned long) testPulseOffset			{ return [self regOffset:kTestPulse]; }
- (unsigned long) patternInibitOffset		{ return [self regOffset:kPatternInhibit]; }
- (unsigned long) majorityThresholdOffset	{ return [self regOffset:kMajorityThreshold]; } 
- (unsigned long) moduleTypeOffset			{ return [self regOffset:kModuleType]; }
- (unsigned long) versionOffset				{ return [self regOffset:kVersion]; }

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CV895"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCV895Controller"];
}

- (NSString*) helpURL
{
	return @"VME/V895.html";
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 895 (Slot %d) ",[self slot]];
}

- (unsigned short) numberOfRegisters
{
	return kNum895Registers;
}

- (unsigned long) regOffset:(int)index
{
	if(index >=0 && index<kNum895Registers){
		return CV895Reg[index].addressOffset;
	}
	else return 0;
}

@end


