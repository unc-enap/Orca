//
//  ORHP6622aModel.m
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
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


#pragma mark ¥¥¥Imported Files
#import "ORHP6622aModel.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORHP6622aPowerOnChanged			= @"ORHP6622aPowerOnChanged";
NSString* ORHP6622aOcProtectionOnChanged	= @"ORHP6622aOcProtectionOnChanged";
NSString* ORHP6622aOutputOnChanged		= @"ORHP6622aOutputOnChanged";
NSString* ORHP6622aSetVolageChanged		= @"ORHP6622aSetVolageChanged";
NSString* ORHP6622aActVolageChanged		= @"ORHP6622aActVolageChanged";
NSString* ORHP6622aOverVolageChanged		= @"ORHP6622aOverVolageChanged";
NSString* ORHP6622aSetCurrentChanged		= @"ORHP6622aSetCurrentChanged";
NSString* ORHP6622aActCurrentChanged		= @"ORHP6622aActCurrentChanged";


NSString* ORHP6622aModelLockGUIChanged			= @"ORHP6622aModelLockGUIChanged";
NSString* ORHP6622aLock							= @"ORHP6622aLock";

@implementation ORHP6622aModel

#pragma mark ***Initialization
- (id) init
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
        
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage: [NSImage imageNamed: @"HP6622a"]];
}


- (NSString*) title 
{
	return [@"6622a HV " stringByAppendingString: [super title]];
}


- (void) makeMainController
{
    [self linkToController:@"ORHP6622aController"];
}

- (NSString*) helpURL
{
	return @"GPIB/HP6622.html";
}

#pragma mark ¥¥¥Accessors
- (BOOL) powerOn:(int)index { return powerOn[index]; }

- (void) setPowerOn:(int)index withValue:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPowerOn:index withValue:powerOn[index]];
    powerOn[index] = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP6622aPowerOnChanged object:self];
}

- (BOOL) ocProtectionOn:(int)index { return ocProtectionOn[index]; }

- (void) setOcProtectionOn:(int)index withValue:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOcProtectionOn:index withValue:ocProtectionOn[index]];
    ocProtectionOn[index] = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP6622aOcProtectionOnChanged object:self];
}

- (BOOL) outputOn:(int)index { return outputOn[index]; }

- (void) setOutputOn:(int)index withValue:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputOn:index withValue:outputOn[index]];
    outputOn[index] = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP6622aOutputOnChanged object:self];
}


- (float) setVoltage:(int)index { return setVoltage[index]; }

- (void) setSetVoltage:(int)index withValue:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSetVoltage:index withValue:setVoltage[index]];
    setVoltage[index] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP6622aSetVolageChanged object:self];
}

- (float) actVoltage:(int)index { return actVoltage[index]; }

- (void) setActVoltage:(int)index withValue:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setActVoltage:index withValue:actVoltage[index]];
    actVoltage[index] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP6622aActVolageChanged object:self];
}

- (float) overVoltage:(int)index { return overVoltage[index]; }

- (void) setOverVoltage:(int)index withValue:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOverVoltage:index withValue:overVoltage[index]];
    overVoltage[index] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP6622aOverVolageChanged object:self];
}

- (float) setCurrent:(int)index { return setCurrent[index]; }

- (void) setSetCurrent:(int)index withValue:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSetCurrent:index withValue:setCurrent[index]];
    setCurrent[index] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP6622aSetCurrentChanged object:self];
}

- (float) actCurrent:(int)index { return actCurrent[index]; }

- (void) setActCurrent:(int)index withValue:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setActCurrent:index withValue:actCurrent[index]];
    actCurrent[index] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP6622aActCurrentChanged object:self];
}

- (NSString*) decodeErrorNumber:(int)errorNum
{
	switch(errorNum){
		case 0: return @"Success. No error";
		case 1: return @"Invalid Char";
		case 2: return @"Invalid Number";
		case 3: return @"Invalid Str";
		case 4: return @"Syntax Error";
		case 5: return @"Number Range";
		case 6: return @"No Query";
		case 7: return @"Disp Length";
		case 8: return @"Buffer Full";
		case 9: return @"EEPROM Error";
		case 10: return @"Hardware Error";
		case 11: return @"Hardware Error Channel 1";
		case 12: return @"Hardware Error Channel 2";
		case 13: return @"Hardware Error Channel 3";
		case 14: return @"Hardware Error Channel 4";
		case 15: return @"No Model Number";
		case 16: return @"Cal Error";
		case 17: return @"Uncalibrated";
		case 18: return @"Cal Locked";
		case 20: return @"Timer Failed";
		case 21: return @"RAM Failed";
		case 22: return @"Skip Self Test";
		case 27: return @"ROM Failed CheckSum";
		case 28: return @"Invalid Str";
		default: return [NSString stringWithFormat:@"Unknown error number: %d",errorNum];
	}
}


#pragma mark ¥¥¥Hardware Access
- (void) readIDString
{
    if([self isConnected]){
		char reply[32];
		reply[0]='\0';
		long n = [self writeReadGPIBDevice:@"ID?" data:reply maxLength:32];
		if(n>0)reply[n-1]='\0';
		NSLog(@"HP6622a ID = %c\n",reply);
	}
}

- (void) doSelfTest
{
    if([self isConnected]){
		char reply[32];
		reply[0]='\0';
		long n = [self writeReadGPIBDevice:@"TEST?" data:reply maxLength:32];
		if(n>0)reply[n-1]='\0';
		NSLog(@"HP6622a Self Test Response: %@\n",[self decodeErrorNumber:atoi(reply)]);
	}
}

- (void) writeOutputOn
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[self writeToGPIBDevice:[NSString stringWithFormat:@"OUT %d,%d",i+1,outputOn[i]]];
		NSLog(@"HP6622a chan %d Output set to %@\n",i+1,outputOn[i]?@"ON":@"OFF");
		[self logSystemResponse];
	}
}

- (void) writeVoltages
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[self writeToGPIBDevice:[NSString stringWithFormat:@"VSET %d,%.2f",i+1,setVoltage[i]]];
		NSLog(@"HP6622a chan %d Voltage set to %.2f\n",i+1,setVoltage[i]);
		[self logSystemResponse];
	}
}

- (void) readVoltages
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		char reply[32];
		reply[0]='\0';
		long n = [self writeReadGPIBDevice:[NSString stringWithFormat:@"VOUT? %d",i+1] data:reply maxLength:32];
		[self setActVoltage:i withValue:atof(reply)];
		if(n>0){
			reply[n-1]='\0';
			[self setActVoltage:i withValue:atof(reply)];
		}
	}
}

- (void) readCurrents
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		char reply[32];
		reply[0]='\0';
		long n = [self writeReadGPIBDevice:[NSString stringWithFormat:@"IOUT? %d",i+1] data:reply maxLength:32];
		[self setActCurrent:i withValue:atof(reply)];
		if(n>0){
			reply[n-1]='\0';
			[self setActCurrent:i withValue:atof(reply)];
		}
	}
}

- (void) readOverVoltages
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		char reply[32];
		reply[0]='\0';
		long n = [self writeReadGPIBDevice:[NSString stringWithFormat:@"OVSET? %d",i+1] data:reply maxLength:32];
		[self setOverVoltage:i withValue:atof(reply)];
		if(n>0){
			reply[n-1]='\0';
			[self setOverVoltage:i withValue:atof(reply)];
		}
	}
}

- (void) writeCurrents
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[self writeToGPIBDevice:[NSString stringWithFormat:@"ISET %d,%.2f",i+1,setCurrent[i]]];
		NSLog(@"HP6622a chan %d Current set to %.2f\n",i+1,setCurrent[i]);
		[self logSystemResponse];
	}
}

- (void) writeOverVoltage
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[self writeToGPIBDevice:[NSString stringWithFormat:@"OVSET %d,%.2f",i+1,overVoltage[i]]];
		NSLog(@"HP6622a chan %d OverVoltage set to %.2f\n",i+1,overVoltage[i]);
		[self logSystemResponse];
	}
}

- (void) writeOCProtection
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[self writeToGPIBDevice:[NSString stringWithFormat:@"OCP %d,%d",i+1,ocProtectionOn[i]]];
		NSLog(@"HP6622a chan %d Over Current Protection set to %@\n",i+1,ocProtectionOn[i]?@"ON":@"OFF");
		[self logSystemResponse];
	}
}

- (void) logSystemResponse
{
    char reply[32];
    reply[0]='\0';
    long n = [self writeReadGPIBDevice:@"ERR?" data:reply maxLength:32];
    if(n>0)reply[n-1]='\0';
	NSLog(@"HP6622a Response: %@\n",[self decodeErrorNumber:atoi(reply)]);
}

- (void) resetOverVoltage:(int)index
{
	[self writeToGPIBDevice:[NSString stringWithFormat:@"OVRST %d",index+1]];
	NSLog(@"HP6622a chan %d Over Voltage reset\n",index+1);
	[self logSystemResponse];
}

- (void) resetOcProtection:(int)index
{
	[self writeToGPIBDevice:[NSString stringWithFormat:@"OCRST %d",index+1]];
	NSLog(@"HP6622a chan %d Over Current reset\n",index+1);
	[self logSystemResponse];
}

- (void) sendAllToHW
{
	[self writeVoltages];
	[self writeCurrents];
	[self writeOverVoltage];
	[self writeOCProtection];
	[self writeOutputOn];
}

- (void) readAllHW
{
	[self readVoltages];
	[self readCurrents];
	[self readOverVoltages];
}

- (void) sendClear
{
	[self writeToGPIBDevice:[NSString stringWithFormat:@"CLR"]];
	NSLog(@"HP6622a sent CLR command %@\n");
	[self logSystemResponse];
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [[self undoManager] disableUndoRegistration];
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[self setOutputOn:i			withValue:[aDecoder decodeIntForKey:   [@"OutputOn" stringByAppendingFormat:@"%d",i]]];
		[self setOcProtectionOn:i	withValue:[aDecoder decodeIntForKey:   [@"OcProtectionOn" stringByAppendingFormat:@"%d",i]]];
		[self setSetVoltage:i		withValue:[aDecoder decodeFloatForKey: [@"setVoltage" stringByAppendingFormat:@"%d",i]]];
		[self setOverVoltage:i		withValue:[aDecoder decodeFloatForKey: [@"overVoltage" stringByAppendingFormat:@"%d",i]]];
		[self setSetCurrent:i		withValue:[aDecoder decodeFloatForKey: [@"setCurrent" stringByAppendingFormat:@"%d",i]]];
	}

    [[self undoManager] enableUndoRegistration];
	    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)anEncoder
{
    [super encodeWithCoder:anEncoder];
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[anEncoder encodeInt:	outputOn[i]			forKey: [@"OutputOn" stringByAppendingFormat:@"%d",i]];
		[anEncoder encodeInt:	ocProtectionOn[i]	forKey: [@"OcProtectionOn" stringByAppendingFormat:@"%d",i]];
		[anEncoder encodeFloat: setVoltage[i]		forKey: [@"setVoltage" stringByAppendingFormat:@"%d",i]];
		[anEncoder encodeFloat: overVoltage[i]		forKey: [@"overVoltage" stringByAppendingFormat:@"%d",i]];
		[anEncoder encodeFloat: setCurrent[i]		forKey: [@"setCurrent" stringByAppendingFormat:@"%d",i]];
	}
    
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[objDictionary setObject:[NSNumber numberWithInt:outputOn[i]] forKey:[@"OutputOn" stringByAppendingFormat:@"%d",i]];
		[objDictionary setObject:[NSNumber numberWithInt:ocProtectionOn[i]] forKey:[@"OcProtectionOn" stringByAppendingFormat:@"%d",i]];
		[objDictionary setObject:[NSNumber numberWithFloat:setVoltage[i]] forKey:[@"setVoltage" stringByAppendingFormat:@"%d",i]];
		[objDictionary setObject:[NSNumber numberWithFloat:overVoltage[i]] forKey:[@"overVoltage" stringByAppendingFormat:@"%d",i]];
		[objDictionary setObject:[NSNumber numberWithFloat:setCurrent[i]] forKey:[@"setCurrent" stringByAppendingFormat:@"%d",i]];
	} 
	return objDictionary;
}

@end


