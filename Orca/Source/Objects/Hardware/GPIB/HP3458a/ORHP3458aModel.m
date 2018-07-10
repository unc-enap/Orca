//
//  ORHP3458aModel.m
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


#pragma mark •••Imported Files
#import "ORHP3458aModel.h"

#pragma mark •••Notification Strings
NSString* ORHP3458aModelMaxInputChanged			= @"ORHP3458aModelMaxInputChanged";
NSString* ORHP3458aModelFunctionDefChanged		= @"ORHP3458aModelFunctionDefChanged";
NSString* ORHP3458aModelLockGUIChanged			= @"ORHP3458aModelLockGUIChanged";
NSString* ORHP3458aLock							= @"ORHP3458aLock";


#define dcvAcvCount 6
#define ohmCount	10
#define dciCount	9
#define aciCount	6

NSString* funcDefNames[15] = {
@"",
@"DCV",
@"ACV",
@"",
@"OHM",
@"OMHF",
@"DCI",
@"ACD",
@"",
@"",
@"",
@"",
@"",
@"",
@""
};

HP3458aNamesStruct dcvAcvNames[dcvAcvCount] = {
	{@"Autorange", -1.0		},
	{@"100mV"    ,	0.12	},	
	{@"   1V"    ,	1.2		},
	{@"  10V"    ,  12.0	},
	{@" 100V"    ,  120.0	},
	{@"1000V"    ,  1000.0	}
};

HP3458aNamesStruct ohmNames[ohmCount] = {
	{@"Autorange" , -1			},
	{@" 10Ω"	  ,	12			},	
	{@" 100Ω"     ,	120			},
	{@"  1kΩ"     , 1200		},
	{@" 10kΩ"     , 12000		},
	{@"100kΩ"     , 120000		},
	{@"  1MΩ"     , 1200000		},
	{@" 10MΩ"     , 12000000	},
	{@"100MΩ"     , 120000000	},
	{@"  1GΩ"     , 1200000000	}
};

HP3458aNamesStruct dciNames[dciCount] = {
	{@"Autorange"	, -1			},
	{@" .1µA"		,  0.12E-6		},	
	{@"  1µA"		,  1.2E-6		},
	{@" 10µA"		,  12.0E-6		},
	{@"100µA"		,  0.120E-6		},
	{@"  1mA"		,  1.2E-3		},
	{@" 10mA"		,  12.0E-3		},
	{@"100mA"		,  120.0E-3		},
	{@"   1A"		,  1.2			},
};

HP3458aNamesStruct aciNames[aciCount] = {
	{@"Autorange"	, -1			},
	{@"100µA"		,  0.120E-6		},
	{@"  1mA"		,  1.2E-3		},
	{@" 10mA"		,  12.0E-3		},
	{@"100mA"		,  120.0E-3		},
	{@"   1A"		,  1.2			},
};


@implementation ORHP3458aModel

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
    [self setImage: [NSImage imageNamed: @"HP3458a"]];
}


- (NSString*) title 
{
	return [@"HP3458a HV " stringByAppendingString: [super title]];
}


- (void) makeMainController
{
    [self linkToController:@"ORHP3458aController"];
}


#pragma mark •••Accessors

- (int) maxInput
{
	int maxIndex=0;
	switch(functionDef){
		case 1:
		case 2: maxIndex = dcvAcvCount-1; break;
		
		case 4:
		case 5: maxIndex = ohmCount-1; break;
		
		case 6: maxIndex = dciCount-1; break;
		case 7: maxIndex = aciCount-1; break;
	}
	if(maxInput > maxIndex-1)return 0;
    else return maxInput;
}

- (void) setMaxInput:(int)aMaxInput
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxInput:maxInput];
    
    maxInput = aMaxInput;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP3458aModelMaxInputChanged object:self];
}

- (int) functionDef
{
    return functionDef;
}

- (void) setFunctionDef:(int)aFunction
{
	if(aFunction != functionDef){
	
		[[[self undoManager] prepareWithInvocationTarget:self] setFunctionDef:functionDef];
    
		functionDef = aFunction;

		[[NSNotificationCenter defaultCenter] postNotificationName:ORHP3458aModelFunctionDefChanged object:self];
	}
}

- (int) getNumberItemsForMaxInput
{
	switch(functionDef){
		case 1:
		case 2: return dcvAcvCount; 
		
		case 4:
		case 5: return ohmCount;
		
		case 6: return dciCount;
		case 7: return aciCount;
		
		default : return 0;
	}
}

- (NSString*) getMaxInputName:(int)i
{
	switch(functionDef){
		case 1:
		case 2: return dcvAcvNames[i].name; 
		
		case 4:
		case 5: return ohmNames[i].name;
		
		case 6: return dciNames[i].name;
		case 7: return aciNames[i].name;
		
		default : return nil;
	}
}

- (float) getFullScale
{
	switch(functionDef){
		case 1:
		case 2: return dcvAcvNames[maxInput].fullScale; 
		
		case 4:
		case 5: return ohmNames[maxInput].fullScale;
		
		case 6: return dciNames[maxInput].fullScale;
		case 7: return aciNames[maxInput].fullScale;
		
		default : return 0;
	}
}


#pragma mark •••Hardware Access
- (void) readIDString
{
    if([self isConnected]){
		char reply[32];
		reply[0]='\0';
		long n = [self writeReadGPIBDevice:@"ID?" data:reply maxLength:32];
		if(n>0){			
			NSLog(@"HP3458a ID = %@\n",[self trucateToCR:reply]);
		}
		else NSLog(@"Illegal response to ID?\n");
	}
}

- (NSString*) trucateToCR:(char*)cString
{
	NSString* s = [NSString stringWithCString:cString encoding:NSASCIIStringEncoding];
	NSRange r = [s rangeOfString:@"\r"];
	return [s substringToIndex:r.location];
}

- (void) doSelfTest
{
    if([self isConnected]){
		char reply[32];
		reply[0]='\0';
		long n = [self writeReadGPIBDevice:@"TEST?" data:reply maxLength:32];
		if(n>0){
			NSLog(@"HP3458a Self Test Response: = %@\n",[self trucateToCR:reply]);
		}
		else NSLog(@"Illegal response to ID?\n");
	}
}

- (void) sendFuncDef
{
	if(functionDef< 14){
		if([self isConnected]){
			float scale = [self getFullScale];
			NSString* cmd = [NSString stringWithFormat:@"FUNC %@,%@",
						funcDefNames[functionDef],
						scale==-1?@"AUTO":[NSString stringWithFormat:@"%.2f",scale]];
			[self writeToGPIBDevice:cmd];
			NSLog(@"HP3458a Func: = %@\n",cmd);
		}
	}
}

- (void) readVoltages
{
}

- (void) resetHW
{
	[self writeToGPIBDevice:@"RESET"];
}

- (void) logSystemResponse
{
    char reply[32];
    reply[0]='\0';
    long n = [self writeReadGPIBDevice:@"ERR?" data:reply maxLength:32];
    if(n>0)reply[n-1]='\0';
	//NSLog(@"HP3458a Response: %@\n",[self decodeErrorNumber:atoi(reply)]);
}


- (void) sendAllToHW
{
	[self sendFuncDef];
}

- (void) readAllHW
{
	
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [[self undoManager] disableUndoRegistration];
    [self setMaxInput:[aDecoder decodeIntForKey:@"ORHP3458aModelFullScaleIndex"]];
    [self setFunctionDef:[aDecoder decodeIntForKey:@"ORHP3458aModelFunctionDef"]];
	//[aDecoder decodeIntForKey:   [@"OutputOn" stringByAppendingFormat:@"%d",i]];

    [[self undoManager] enableUndoRegistration];
	    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)anEncoder
{
    [super encodeWithCoder:anEncoder];
	[anEncoder encodeInt:maxInput forKey:@"ORHP3458aModelFullScaleIndex"];
	[anEncoder encodeInt:functionDef forKey:@"ORHP3458aModelFunctionDef"];
	//[anEncoder encodeInt:	outputOn[i]			forKey: [@"OutputOn" stringByAppendingFormat:@"%d",i]];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
 //   
//	int i;
//	for(i=0;i<kHP3458aNumberSupplies;i++){
//		[objDictionary setObject:[NSNumber numberWithInt:outputOn[i]] forKey:[@"OutputOn" stringByAppendingFormat:@"%d",i]];
//		[objDictionary setObject:[NSNumber numberWithInt:ocProtectionOn[i]] forKey:[@"OcProtectionOn" stringByAppendingFormat:@"%d",i]];
//		[objDictionary setObject:[NSNumber numberWithFloat:setVoltage[i]] forKey:[@"setVoltage" stringByAppendingFormat:@"%d",i]];
//		[objDictionary setObject:[NSNumber numberWithFloat:overVoltage[i]] forKey:[@"overVoltage" stringByAppendingFormat:@"%d",i]];
//		[objDictionary setObject:[NSNumber numberWithFloat:setCurrent[i]] forKey:[@"setCurrent" stringByAppendingFormat:@"%d",i]];
//	} 
	return objDictionary;
}

@end


