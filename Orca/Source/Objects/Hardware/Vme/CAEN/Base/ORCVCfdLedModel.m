/*
 *  ORCVCfdLedModel.m
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
#import "ORCVCfdLedModel.h"

// Address information for this unit.
#define k812DefaultBaseAddress 		0xF0000000
#define k812DefaultAddressModifier 	0x39

NSString* ORCVCfdLedModelAutoInitWithRunChanged = @"ORCVCfdLedModelAutoInitWithRunChanged";
NSString* ORCVCfdLedModelTestPulseChanged			= @"ORCVCfdLedModelTestPulseChanged";
NSString* ORCVCfdLedModelPatternInhibitChanged		= @"ORCVCfdLedModelPatternInhibitChanged";
NSString* ORCVCfdLedModelMajorityThresholdChanged	= @"ORCVCfdLedModelMajorityThresholdChanged";
NSString* ORCVCfdLedModelDeadTime0_7Changed		= @"ORCVCfdLedModelDeadTime0_7Changed";
NSString* ORCVCfdLedModelDeadTime8_15Changed		= @"ORCVCfdLedModelDeadTime8_15Changed";
NSString* ORCVCfdLedModelOutputWidth8_15Changed	= @"ORCVCfdLedModelOutputWidth8_15Changed";
NSString* ORCVCfdLedModelOutputWidth0_7Changed		= @"ORCVCfdLedModelOutputWidth0_7Changed";
NSString* ORCVCfdLedModelThresholdChanged			= @"ORCVCfdLedModelThresholdChanged";
NSString* ORCVCfdLedModelThresholdLock				= @"ORCVCfdLedModelThresholdLock";

@implementation ORCVCfdLedModel

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k812DefaultBaseAddress];
    [self setAddressModifier:k812DefaultAddressModifier];
	
    [[self undoManager] enableUndoRegistration];
	[self registerNotificationObservers];
   
    return self;
}
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    
    [notifyCenter addObserver : self
                     selector : @selector(runABoutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];    
}
#pragma mark ***Accessors

- (BOOL) autoInitWithRun
{
    return autoInitWithRun;
}

- (void) setAutoInitWithRun:(BOOL)aAutoInitWithRun
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoInitWithRun:autoInitWithRun];
    
    autoInitWithRun = aAutoInitWithRun;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelAutoInitWithRunChanged object:self];
}
- (unsigned short) threshold:(unsigned short) aChnl
{
    return(thresholds[aChnl]);
}

- (void) setThreshold:(unsigned short) aChnl threshold:(unsigned short) aValue
{
    
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChnl threshold:[self threshold:aChnl]];
    
    thresholds[aChnl] = aValue;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:@"Channel"];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:ORCVCfdLedModelThresholdChanged object:self userInfo:userInfo];
}

- (unsigned short) testPulse
{
    return testPulse;
}

- (void) setTestPulse:(unsigned short)aTestPulse
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestPulse:testPulse];
    testPulse = aTestPulse;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelTestPulseChanged object:self];
}

- (unsigned short) patternInhibit
{
    return patternInhibit;
}

- (void) setPatternInhibit:(unsigned short)aPatternInhibit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternInhibit:patternInhibit];
    patternInhibit = aPatternInhibit;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelPatternInhibitChanged object:self];
}

- (BOOL)inhibitMaskBit:(int)bit
{
	return patternInhibit&(1<<bit);
}

- (void) setInhibitMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned long aMask = patternInhibit;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setPatternInhibit:aMask];
}

- (unsigned short) majorityThreshold
{
    return majorityThreshold;
}

- (void) setMajorityThreshold:(unsigned short)aMajorityThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMajorityThreshold:majorityThreshold];
    majorityThreshold = aMajorityThreshold;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelMajorityThresholdChanged object:self];
}



- (unsigned short) outputWidth8_15
{
    return outputWidth8_15;
}

- (void) setOutputWidth8_15:(unsigned short)aOutputWidth8_15
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputWidth8_15:outputWidth8_15];
    outputWidth8_15 = aOutputWidth8_15;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelOutputWidth8_15Changed object:self];
}

- (unsigned short) outputWidth0_7
{
    return outputWidth0_7;
}

- (void) setOutputWidth0_7:(unsigned short)aOutputWidth0_7
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputWidth0_7:outputWidth0_7];
    outputWidth0_7 = aOutputWidth0_7;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelOutputWidth0_7Changed object:self];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0xFF);
}

- (void) runABoutToStart:(NSNotification*)aNote
{
	[self initBoard];
}

#pragma mark ***HW Access
- (void) initBoard
{
	@try {
		int i;
		for(i=0;i<16;i++)[self writeThreshold:i];
		[self writeOutputWidth0_7];
		[self writeOutputWidth8_15];
		[self writeTestPulse];
		[self writePatternInhibit];
		[self writeMajorityThreshold];
	}
	@catch (NSException* e) {
		NSLogColor([NSColor redColor], @"%@ didn't initialize\n",[self identifier]);
	}
}

- (unsigned short) numberOfRegisters
{
	//subclasses must override
	return 0;
}
- (unsigned long) regOffset:(int)index
{
	NSAssert(NO, @"RegOffset in ORCVCfdLedModel must be subclassed\n");
	return 0;
}

- (unsigned long) threshold0Offset 
{ 
	NSAssert(NO, @"threshold0Offset in ORCVCfdLedModel must be subclassed\n");
	return 0;
}

- (unsigned long) outputWidth0_7Offset 
{ 
	NSAssert(NO, @"outputWidth0_7Offset in ORCVCfdLedModel must be subclassed\n");
	return 0;
}
- (unsigned long) outputWidth8_15Offset 
{ 
	NSAssert(NO, @"outputWidth8_15Offset in ORCVCfdLedModel must be subclassed\n");
	return 0;
}
- (unsigned long) testPulseOffset 
{ 
	NSAssert(NO, @"testPulseOffset in ORCVCfdLedModel must be subclassed\n");
	return 0;
}
- (unsigned long) patternInibitOffset 
{ 
	NSAssert(NO, @"patternInibitOffset in ORCVCfdLedModel must be subclassed\n");
	return 0;
}
- (unsigned long) majorityThresholdOffset 
{ 
	NSAssert(NO, @"majorityThresholdOffset in ORCVCfdLedModel must be subclassed\n");
	return 0;
}
- (unsigned long) moduleTypeOffset 
{ 
	NSAssert(NO, @"moduleTypeOffset in ORCVCfdLedModel must be subclassed\n");
	return 0;
}
- (unsigned long) versionOffset 
{ 
	NSAssert(NO, @"moduleTypeOffset in ORCVCfdLedModel must be subclassed\n");
	return 0;
}



- (void) writeThreshold:(unsigned short) pChan
{
    unsigned short 	threshold = [self threshold:pChan];
    
    [[self adapter] writeWordBlock:&threshold
                         atAddress:[self baseAddress] +  [self threshold0Offset] + (pChan * sizeof(short))
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) writeOutputWidth0_7
{
    [[self adapter] writeWordBlock:&outputWidth0_7
                         atAddress:[self baseAddress] +  [self outputWidth0_7Offset]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeOutputWidth8_15
{
    [[self adapter] writeWordBlock:&outputWidth8_15
                         atAddress:[self baseAddress] +  [self outputWidth8_15Offset]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeTestPulse
{
    [[self adapter] writeWordBlock:&testPulse
                         atAddress:[self baseAddress] +  [self testPulseOffset]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writePatternInhibit
{
    [[self adapter] writeWordBlock:&patternInhibit
                         atAddress:[self baseAddress] +  [self patternInibitOffset]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeMajorityThreshold
{
    [[self adapter] writeWordBlock:&majorityThreshold
                         atAddress:[self baseAddress] +  [self majorityThresholdOffset]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) probeBoard
{
	unsigned short moduleType;
    [[self adapter] readWordBlock:&moduleType
						atAddress:[self baseAddress] +  [self moduleTypeOffset]
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
	unsigned short version;
    [[self adapter] readWordBlock:&version
						atAddress:[self baseAddress] +  [self versionOffset]
					   numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	NSLog(@"Version: 0x%01x   Serial Number: 0x%03x\n",(version>>12)&0xf,version%0xfff);
	NSLog(@"Manufacturer Code: 0x%x\n",(moduleType>>10)&0x3F);
	NSLog(@"Module Type: 0x%\n",moduleType&0x3ff);
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    int i;
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:16];
    for(i=0;i<16;i++){
        [array addObject:[NSNumber numberWithShort:thresholds[i]]];
    }
    [objDictionary setObject:array forKey:@"thresholds"];
    [objDictionary setObject:[NSNumber numberWithInt:testPulse] forKey:@"testPulse"];
    [objDictionary setObject:[NSNumber numberWithInt:patternInhibit] forKey:@"patternInhibit"];
    [objDictionary setObject:[NSNumber numberWithInt:majorityThreshold] forKey:@"majorityThreshold"];
    [objDictionary setObject:[NSNumber numberWithInt:outputWidth0_7] forKey:@"outputWidth0_7"];
    [objDictionary setObject:[NSNumber numberWithInt:outputWidth8_15] forKey:@"outputWidth8_15"];
    
    return objDictionary;
}


#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];

    [[self undoManager] disableUndoRegistration];
	int i;
	for(i=0;i<16;i++){
		[self setThreshold:i threshold:[aDecoder decodeIntForKey:[NSString stringWithFormat:@"threshold%d",i]]];
	}
    [self setAutoInitWithRun:[aDecoder decodeBoolForKey:@"autoInitWithRun"]];
	[self setTestPulse:[aDecoder decodeIntForKey:@"testPulse"]];
	[self setPatternInhibit:[aDecoder decodeIntForKey:@"patternInhibit"]];
	[self setMajorityThreshold:[aDecoder decodeIntForKey:@"majorityThreshold"]];
	[self setOutputWidth0_7:[aDecoder decodeIntForKey:@"outputWidth0_7"]];
	[self setOutputWidth8_15:[aDecoder decodeIntForKey:@"outputWidth8_15"]];
    [self registerNotificationObservers];
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
	int i;
	for(i=0;i<16;i++){
		[anEncoder encodeInt:[self threshold:i] forKey:[NSString stringWithFormat:@"threshold%d",i]];
	}
	[anEncoder encodeBool:autoInitWithRun forKey:@"autoInitWithRun"];
    [anEncoder encodeInt:testPulse forKey:@"testPulse"];
    [anEncoder encodeInt:patternInhibit forKey:@"patternInhibit"];
    [anEncoder encodeInt:majorityThreshold forKey:@"majorityThreshold"];
    [anEncoder encodeInt:outputWidth0_7 forKey:@"outputWidth0_7"];
    [anEncoder encodeInt:outputWidth8_15 forKey:@"outputWidth8_15"];
}

@end


