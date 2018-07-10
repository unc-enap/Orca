//
//  ORNplHVModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Dec 6 2007
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORNplHVModel.h"
#import "ORNPLCommBoardModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORHVRampItem.h"

NSString* ORNplHVLock						= @"ORNplHVLock";
NSString* HVToCommBoxConnector				= @"HVToCommBoxConnector";


@implementation ORNplHVModel

- (void) makeMainController
{
    [self linkToController:@"ORNplHVController"];
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"NplHVIcon"]];
}

- (void) awakeAfterDocumentLoaded
{
	comBoard	= [[[[self connectors] objectForKey:HVToCommBoxConnector] connector] objectLink];
	boardNumber = [[[[self connectors] objectForKey:HVToCommBoxConnector] connector] identifer];

}

 - (void) makeConnectors
 {
	ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
	[[self connectors] setObject:aConnector forKey:HVToCommBoxConnector];
	[aConnector setConnectorType: 'NSLV' ];
	[aConnector setIoType:kInputConnector];
	[aConnector addRestrictedConnectionType: 'NCmO' ]; //can only connect to Comm Boards
	[aConnector release];
}


- (void) addRampItem
{
	ORHVRampItem* aRampItem = [[ORHVRampItem alloc] initWithOwner:self];
	[rampItems addObject:aRampItem];
	[aRampItem release];
}

- (void) ensureMinimumNumberOfRampItems
{
	if(!rampItems)[self setRampItems:[NSMutableArray array]];
	if([rampItems count] == 0){
		int i;
		[[self undoManager] disableUndoRegistration];
		for(i=0;i<[self numberOfChannels];i++){
			ORHVRampItem* aRampItem = [[ORHVRampItem alloc] initWithOwner:self];
			[aRampItem setTargetName:[self className]];
			[aRampItem setChannelNumber:i];
			[aRampItem setParameterName:@"Voltage"];
			[aRampItem loadParams:self];
			[rampItems addObject:aRampItem];
			[aRampItem release];
		}
		[[self undoManager] enableUndoRegistration];
	}
}

#pragma mark ***Accessors
- (NSString*) lockName
{
	return ORNplHVLock;
}

- (int) adc:(int)aChan
{
	if(aChan>=0 && aChan < [self numberOfChannels])return adc[aChan];
	else return 0;
}

- (void) setAdc:(int)aChan withValue:(int)aValue
{
	if(aChan>=0 && aChan < [self numberOfChannels]){
		adc[aChan] = aValue;
	}
}

- (int) dac:(int)aChan
{
	if(aChan>=0 && aChan < [self numberOfChannels])return dac[aChan];
	else return 0;
}

- (void) setDac:(int)aChan withValue:(int)aValue
{
	if(aChan>=0 && aChan < [self numberOfChannels]){
		dac[aChan] = aValue;
	}
}

- (int) current:(int)aChan
{
	if(aChan>=0 && aChan < [self numberOfChannels])return current[aChan];
	else return 0;
}

- (void) setCurrent:(int)aChan withValue:(int)aValue
{
	if(aChan>=0 && aChan < [self numberOfChannels]){
		current[aChan] = aValue;
	}
}

- (int) controlReg:(int)aChan
{
	if(aChan>=0 && aChan < [self numberOfChannels])return controlReg[aChan];
	else return 0;
}

- (void) setControlReg:(int)aChan withValue:(int)aValue
{
	if(aChan>=0 && aChan < [self numberOfChannels]){
		controlReg[aChan] = aValue;
	}
}



#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];    
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}

- (void) sendCmd
{	
/*
    ORConnector* aConnection = [[[self connectors] objectForKey:HVToCommBoxConnector] connector];
    int board =  [aConnection identifer];

	//send the values from the basic ops
	char bytes[6];
	bytes[0] = 5;
	bytes[1] = ((board & 0xf)<<4) | ((channel & 0x3)<<2) | (functionNumber & 0x3);
	bytes[2] = 0;
	bytes[3] = (writeValue>>16 & 0xf);
	bytes[4] = (writeValue>>8 & 0xf); 
	bytes[5] = writeValue & 0xf; 
	[socket write:bytes length:6];
*/
}

- (SEL) getMethodSelector
{
	return @selector(dac:);
}

- (SEL) setMethodSelector
{
	return @selector(setDac:withValue:);
}

- (SEL) initMethodSelector
{
	//fake out, so we can actually do the load ourselves
	return @selector(junk);
}

- (void) junk
{
}

- (void) loadDac:(int)aChan
{
	//send the values from the basic ops
	char bytes[6];
	bytes[0] = 5;
	bytes[1] = ((1 & 0xf)<<4) | ((aChan & 0x3)<<2) | (2 & 0x3); //set dac
	bytes[2] = 0;
	int aValue = dac[aChan];
	bytes[3] = (aValue>>16 & 0xf);
	bytes[4] = (aValue>>8 & 0xf); 
	bytes[5] = aValue & 0xf; 
	//[socket write:bytes length:6];
}

- (void) initBoard
{
	int chan;
	for(chan = 0 ; chan<[self numberOfChannels] ; chan++){
		//set up the Voltage Adc
		[self setVoltageReg:kNplHVChanConvTime	chan:chan value:0xff]; //set conversion time to max
		[self setVoltageReg:kNplHVChanSetup		chan:chan value:0x5];  //bits 0,1 are gain, bit 2 is enables chan for continous conversion
		[self setVoltageReg:kNplHVMode			chan:chan value:0x20]; //20 = continous and 16 bit output word

		//set up the Current Adc
		[self setCurrentReg:kNplHVChanConvTime	chan:chan value:0xff]; //set conversion time to max
		[self setCurrentReg:kNplHVChanSetup		chan:chan value:0x5];  //bits 0,1 are gain, bit 2 is enables chan for continous conversion
		[self setCurrentReg:kNplHVMode			chan:chan value:0x20]; //20 = continous and 16 bit output word

	}
}

- (void) setVoltageReg:(int)aReg chan:(int)aChan value:(int)aValue
{
	[comBoard sendBoard: boardNumber 
				   bloc: aChan % 4
			   function: kNplHVVoltageAdc
			 controlReg: aReg + aChan
				  value: aValue
				 cmdLen: 3];	
}

- (void) setCurrentReg:(int)aReg chan:(int)aChan value:(int)aValue
{
	[comBoard sendBoard: boardNumber 
				   bloc: aChan % 4
			   function: kNplHVCurrentAdc
			 controlReg: aReg + aChan
				  value: aValue
				 cmdLen: 3];	
}




- (void) revision
{
	[comBoard sendBoard:boardNumber bloc:0 function:kNplHVVoltageAdc controlReg: kNplHVRevision | kNplHvRead value:0 cmdLen:3];
}

- (void) connectionChanged
{
	comBoard	= [[[[self connectors] objectForKey:HVToCommBoxConnector] connector] objectLink];
	boardNumber = [[[[self connectors] objectForKey:HVToCommBoxConnector] connector] identifer];
}

#pragma mark •••HW Wizard
//the next two methods exist only to 'fake' out Hardware wizard and the Ramper so this item can be selected
//- (int) crateNumber	{	return 0;	}
//- (int) slot		{	return [self tag];	}

- (int) numberOfChannels
{
    return 4;
}

//- (BOOL) hasParmetersToRamp
//{
//	return YES;
//}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
//    ORHWWizParam* p;
    
//    p = [[[ORHWWizParam alloc] init] autorelease];
//    [p setName:@"Voltage"];
//    [p setFormat:@"##0" upperLimit:3000 lowerLimit:0 stepSize:1 units:@"V"];
//    [p setSetMethod:@selector(setDac:withValue:) getMethod:@selector(dac:)];
//	[p setInitMethodSelector:@selector(sendCmd)];
//	[p setCanBeRamped:YES];
//    [a addObject:p];
	    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate"	className:@"ORNplHVModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card"		className:@"ORNplHVModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel"	className:@"ORNplHVModel"]];
    return a;
	
}

@end
