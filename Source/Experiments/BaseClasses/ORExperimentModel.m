//
//  ORExperimentModel.m
//  Orca
//
//  Created by Mark Howe on 12/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORExperimentModel.h"
#import "ORAxis.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"
#import "ORDataTypeAssigner.h"
#import "ORRunModel.h"
#import "ORDetectorSegment.h"
#import "ORSegmentGroup.h"
#import "ORAlarmCollection.h"

NSString* ORExperimentModelIgnoreHWChecksChanged		 = @"ORExperimentModelIgnoreHWChecksChanged";
NSString* ORExperimentModelShowNamesChanged				 = @"ORExperimentModelShowNamesChanged";
NSString* ExperimentModelDisplayTypeChanged				 = @"ExperimentModelDisplayTypeChanged";
NSString* ExperimentModelSelectionStringChanged			 = @"ExperimentModelSelectionStringChanged";
NSString* ExperimentHardwareCheckChangedNotification     = @"ExperimentHardwareCheckChangedNotification";
NSString* ExperimentCardCheckChangedNotification         = @"ExperimentCardCheckChangedNotification";
NSString* ExperimentCaptureDateChangedNotification       = @"ExperimentCaptureDateChangedNotification";
NSString* ExperimentDisplayUpdatedNeeded			 	 = @"ExperimentDisplayUpdatedNeeded";
NSString* ExperimentCollectedRates						 = @"ExperimentCollectedRates";
NSString* ExperimentDisplayHistogramsUpdated			 = @"ExperimentDisplayHistogramsUpdated";
NSString* ExperimentModelSelectionChanged				 = @"ExperimentModelSelectionChanged";
NSString* ExperimentModelColorScaleTypeChanged           = @"ExperimentModelColorScaleTypeChanged";
NSString* ExperimentModelCustomColor1Changed             = @"ExperimentModelCustomColor1Changed";
NSString* ExperimentModelCustomColor2Changed             = @"ExperimentModelCustomColor2Changed";


@interface ORExperimentModel (private)
- (void) checkCardOld:(NSDictionary*)oldCardRecord new:(NSDictionary*)newCardRecord  check:(SEL)checkSelector exclude:(NSSet*)exclusionSet;
- (void) delayedHistogram;
@end

@implementation ORExperimentModel
#pragma mark •••Initialization
- (id) init
{
    self = [super init];
    [self setCustomColor1:[NSColor blueColor]];
    [self setCustomColor2:[NSColor whiteColor]];
	[self makeSegmentGroups];
    return self;
}

-(void)dealloc
{	
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[segmentGroups release];
	[selectionString release];
        
    [failedHardwareCheckAlarm clearAlarm];
    [failedHardwareCheckAlarm release];
 
	[failedCardCheckAlarm clearAlarm];
    [failedCardCheckAlarm release];
   
    [captureDate release];
    [problemArray release];
    [customColor1 release];
    [customColor2 release];
    
    [super dealloc];
}


- (void) wakeUp
{
    if([self aWake])return;
	[self collectRates];
    [super wakeUp];
}

- (void) sleep
{
    [super sleep];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
}

- (void) awakeAfterDocumentLoaded
{
	[segmentGroups makeObjectsPerformSelector:@selector(awakeAfterDocumentLoaded)];
    [super awakeAfterDocumentLoaded];
}

- (BOOL) solitaryObject
{
    return YES;
}

- (void) addGroup:(ORSegmentGroup*)aGroup
{
	if(!segmentGroups)segmentGroups = [[NSMutableArray array] retain];
	if(![segmentGroups containsObject:aGroup]){
		[segmentGroups addObject:aGroup];
	}
}

#pragma mark •••Group Methods

- (NSMutableArray*) setupMapEntries:(int) index
{
	//default set -- subsclasses can override
    [self setCardIndex:kCardSlot];
    [self setChannelIndex:kChannel];
	NSMutableArray* mapEntries = [NSMutableArray array];
	[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
	[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
	[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
	[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kName",			@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
    [self setCrateIndex:-1]; //default is no crate
    
	return mapEntries;
}
- (void) setCrateIndex:(int)aValue
{
    for(id aGroup in segmentGroups)[aGroup setCrateIndex:aValue];
}
- (void) setCardIndex:(int)aValue
{
    for(id aGroup in segmentGroups)[aGroup setCardIndex:aValue];
}
- (void) setChannelIndex:(int)aValue
{
    for(id aGroup in segmentGroups)[aGroup setChannelIndex:aValue];
}
- (void) registerForRates
{
	[segmentGroups makeObjectsPerformSelector:@selector(registerForRates)];
}


- (void) collectRatesFromAllGroups
{
	if([self guardian]){
		[segmentGroups makeObjectsPerformSelector:@selector(collectRates)];
	}
}

- (void) clearSegmentErrors 
{
	[segmentGroups makeObjectsPerformSelector:@selector(clearSegmentErrors)];
}

- (int) numberOfSegmentGroups
{
	return (int)[segmentGroups count];
}

- (ORSegmentGroup*) segmentGroup:(int)aSet
{
	if(aSet>=0 && aSet < [segmentGroups count]){
		return [segmentGroups objectAtIndex:aSet];
	}
	else return nil;
}		

- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	//default is to just return the string. subclasses can reform if they want
	return aString;
}
- (NSString*) getPartStartingWith:(NSString*)aLable parts:(NSArray*)parts
{
	//subclasses can reform if they want
	return @"";
}

- (void) selectedSet:(int)aSet segment:(int)index
{
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		NSString* s = [self reformatSelectionString:[aGroup selectedSegementInfo:index] forSet:aSet];
		[self setSelectionString:s];	
		[self setSomethingSelected:YES];
	}
	else {
		[self setSomethingSelected:NO];
		[self setSelectionString:@"<Nothing Selected>"];	
	}
}

- (void) showDialogForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		[aGroup showDialogForSegment:index];
	}
}

- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	//not implemented... up to subclasses to define
}

- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index
{ 
	return @"";
	//not implemented... up to subclasses to define
}


- (void) histogram
{
	[segmentGroups makeObjectsPerformSelector:@selector(histogram)];
}

- (void) setSegmentErrorClassName:(NSString*)aClassName card:(int)card channel:(int)channel
{
	NSEnumerator* e = [segmentGroups objectEnumerator];
	ORSegmentGroup* aGroup;
	while(aGroup = [e nextObject]){
		[aGroup setSegmentErrorClassName:aClassName card:card channel:channel];
	}
}

- (void) initHardware
{
	NSMutableSet* allCards = [NSMutableSet set];
	NSEnumerator* e = [segmentGroups objectEnumerator];
	ORSegmentGroup* aGroup;
	while(aGroup = [e nextObject]){
		[allCards unionSet:[aGroup hwCards]];
	}

	@try {
		[allCards makeObjectsPerformSelector:@selector(initBoard)];
		NSLog(@"%@ Adc cards inited\n",[self className]);
	}
	@catch (NSException * e) {
		NSLogColor([NSColor redColor],@"%@ Adc cards init failed\n",[self className]);
	}
}


#pragma mark •••Subclass Responsibility
- (void) makeSegmentGroups{;} //subclasses must override
- (int)  maxNumSegments{ return 0;} //subclasses must override
- (void) handleOldPrimaryMapFormats:(NSString*)aPath {;}//subclasses can override
- (void) readAuxFiles:(NSString*)aPath {;}//subclasses can override
- (void) saveAuxFiles:(NSString*)aPath {;}//subclasses can override
- (NSString*) validateHWMapPath:(NSString*)aPath{return aPath;}//subclasses can override
- (NSString*) mapFileHeader:(int)tag{return nil;}//subclasses can override
- (void) setupSegmentIds {;} //subclasses must override

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
					   
	[self registerForRates];
	[self collectRates];
 }

- (void) runStatusChanged:(NSNotification*)aNote
{
    int running = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
    if(running == eRunStopped){
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
        //[[self detector] unregisterRates];
    }
    else {
        [self registerForRates];
        [self collectRates];
    }
}

- (void) collectRates
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
	if([self guardian]){
		[self collectRatesFromAllGroups];
	
		[[NSNotificationCenter defaultCenter]
			postNotificationName:ExperimentCollectedRates
						object:self];

	}
	[self performSelector:@selector(collectRates) withObject:nil afterDelay:5.0];
}

#pragma mark •••Specific Dialog Lock Methods
- (NSString*) experimentMapLock 
{
	return @"ExperimentMapLock";
}
- (NSString*) experimentDetectorLock;
{
	return @"ExperimentDetectorLock";
}
- (NSString*) experimentDetailsLock;
{
	return @"ExperimentDetailsLock";
}

#pragma mark •••Accessors
- (int) colorScaleType
{
    return colorScaleType;
}

- (void) setColorScaleType:(int)aType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setColorScaleType:colorScaleType];
    colorScaleType = aType;
    [[NSNotificationCenter defaultCenter] postNotificationName:ExperimentModelColorScaleTypeChanged object:self];
}

- (NSColor*) customColor1
{
    return customColor1;
}

- (void) setCustomColor1:(NSColor*)aColor
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCustomColor1:customColor1];
    [aColor retain];
    [customColor1 release];
    customColor1 = aColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:ExperimentModelCustomColor1Changed object:self];
    
}

- (NSColor*) customColor2
{
    return customColor2;
  
}

- (void) setCustomColor2:(NSColor*)aColor
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCustomColor2:customColor2];
    [aColor retain];
    [customColor2 release];
    customColor2 = aColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:ExperimentModelCustomColor2Changed object:self];
    
}


- (BOOL) ignoreHWChecks
{
    return ignoreHWChecks;
}

- (void) setIgnoreHWChecks:(BOOL)aIgnoreHWChecks
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnoreHWChecks:ignoreHWChecks];
    ignoreHWChecks = aIgnoreHWChecks;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORExperimentModelIgnoreHWChecksChanged object:self];
}

- (BOOL) showNames
{
    return showNames;
}

- (void) setShowNames:(BOOL)aShowNames
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowNames:showNames];
    
    showNames = aShowNames;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORExperimentModelShowNamesChanged object:self];
}

- (void) setSomethingSelected:(BOOL)aFlag
{
    somethingSelected = aFlag;

    [[NSNotificationCenter defaultCenter] postNotificationName:ExperimentModelSelectionChanged object:self];
}

- (BOOL) somethingSelected
{
	return somethingSelected;
}
- (int) displayType
{
    return displayType;
}

- (void) setDisplayType:(int)aDisplayType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisplayType:displayType];
    
    displayType = aDisplayType;

    [[NSNotificationCenter defaultCenter] postNotificationName:ExperimentModelDisplayTypeChanged object:self];
}


- (NSString*) selectionString
{
	if(!selectionString)return @"<nothing selected>";
    else return selectionString;
}

- (void) setSelectionString:(NSString*)aSelectionString
{
    [selectionString autorelease];
    selectionString = [aSelectionString copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ExperimentModelSelectionStringChanged object:self];
}

- (BOOL) replayMode
{
	return replayMode;
}

- (void) setReplayMode:(BOOL)aReplayMode
{
	replayMode = aReplayMode;
	//[[Prespectrometer sharedInstance] setReplayMode:aReplayMode];
}

- (int) hardwareCheck
{
    return hardwareCheck;
}

- (void) setHardwareCheck: (int) aState
{
    hardwareCheck = aState;
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:ExperimentHardwareCheckChangedNotification
                      object:self];
    
    if(hardwareCheck==NO) {
		if(!failedHardwareCheckAlarm){
			failedHardwareCheckAlarm = [[ORAlarm alloc] initWithName:@"Hardware Check Failed" severity:kSetupAlarm];
			[failedHardwareCheckAlarm setSticky:YES];
		}
		[failedHardwareCheckAlarm setAcknowledged:NO];
		[failedHardwareCheckAlarm postAlarm];
        [failedHardwareCheckAlarm setHelpStringFromFile:@"HardwareCheckHelp"];
    }
    else {
        [failedHardwareCheckAlarm clearAlarm];
    }
    
}

- (int) cardCheck
{
    return cardCheck;
}

- (void) setCardCheck: (int) aState
{
    cardCheck = aState;
    [[NSNotificationCenter defaultCenter]
         postNotificationName:ExperimentCardCheckChangedNotification
                       object:self];
    
    if(cardCheck==NO) {
		if(!failedCardCheckAlarm){
			failedCardCheckAlarm = [[ORAlarm alloc] initWithName:@"Card Check Failed" severity:kSetupAlarm];
			[failedCardCheckAlarm setSticky:YES];
		}
		[failedCardCheckAlarm setAcknowledged:NO];
		[failedCardCheckAlarm postAlarm];
        [failedCardCheckAlarm setHelpStringFromFile:@"CardCheckHelp"];
    }
    else {
        [failedCardCheckAlarm clearAlarm];
    }
}

- (void) setCardCheckFailed
{
    [self setCardCheck:NO];
}

- (void) setHardwareCheckFailed
{
    [self setHardwareCheck:NO];
}

- (NSDate *) captureDate
{
    return captureDate; 
}

- (void) setCaptureDate: (NSDate *) aCaptureDate
{
    [aCaptureDate retain];
    [captureDate release];
    captureDate = aCaptureDate;
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:ExperimentCaptureDateChangedNotification
                      object:self];
    
}

- (void) clearAlarm:(NSString*)aName
{
	[[ORAlarmCollection sharedAlarmCollection] performSelectorOnMainThread:@selector(removeAlarmWithName:) withObject:aName waitUntilDone:YES];	
}

- (void) postAlarm:(NSString*)aName
{
	[self postAlarm:aName severity:0 reason:@"No Reason Given"];
}


- (void) postAlarm:(NSString*)aName severity:(int)aSeverity
{
	[self postAlarm:aName severity:aSeverity reason:@"No Reason Given"];
}

- (void) postAlarm:(NSString*)aName severity:(int)aSeverity reason:(NSString*)aReason
{
	ORAlarm* anAlarm = [[ORAlarm alloc] initWithName:aName severity:MIN(kNumAlarmSeverityTypes-1,aSeverity)];
	NSString* s = [NSString stringWithFormat:@"\n[%@] posted this alarm. Acknowledge it and it will go away.",[self fullID]];
	if([aReason length]){
		s = [s stringByAppendingFormat:@"\n\n Reason Posted: %@",aReason];
	}
	[anAlarm setHelpString:s];
	
	[anAlarm performSelectorOnMainThread:@selector(postAlarm) withObject:nil waitUntilDone:YES];
	[anAlarm release];
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setIgnoreHWChecks:[decoder decodeBoolForKey:	@"ignoreHWChecks"]];
    [self setShowNames:		[decoder decodeBoolForKey:	@"ORExperimentModelShowNames"]];
    [self setDisplayType:	[decoder decodeIntForKey:   @"ExperimentModelDisplayType"]];
    [self setCaptureDate:	[decoder decodeObjectForKey:@"ExperimentCaptureDate"]];
    [self setColorScaleType:[decoder decodeIntForKey:   @"colorScaleType"]];
    
    NSColor* color1 = [decoder decodeObjectForKey:@"customColor1"];
    if(color1)[self setCustomColor1:color1];
    else [self setCustomColor1:[NSColor blueColor]];
    
    NSColor* color2 = [decoder decodeObjectForKey:@"customColor2"];
    if(color2)[self setCustomColor2:color2];
    else [self setCustomColor2:[NSColor whiteColor]];
    
	segmentGroups = [[decoder decodeObjectForKey:       @"ExperimentSegmentGroups"] retain];
	if([segmentGroups count] == 1)[[segmentGroups objectAtIndex:0] setMapEntries:[self setupMapEntries:0]];
	else if([segmentGroups count] == 2){
		[[segmentGroups objectAtIndex:0] setMapEntries:[self setupMapEntries:0]];
		[[segmentGroups objectAtIndex:1] setMapEntries:[self setupMapEntries:1]];
	}
	else if([segmentGroups count] == 3){
		[[segmentGroups objectAtIndex:0] setMapEntries:[self setupMapEntries:0]];
		[[segmentGroups objectAtIndex:1] setMapEntries:[self setupMapEntries:1]];
		[[segmentGroups objectAtIndex:2] setMapEntries:[self setupMapEntries:2]];
	}
    [self setupSegmentIds];
    
    [[self undoManager] enableUndoRegistration];
    
    [self setHardwareCheck:2]; //unknown
    [self setCardCheck:2];

    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:ignoreHWChecks	forKey: @"ignoreHWChecks"];
    [encoder encodeBool:showNames		forKey: @"ORExperimentModelShowNames"];
    [encoder encodeInteger:displayType		forKey: @"ExperimentModelDisplayType"];
    [encoder encodeInteger:colorScaleType   forKey: @"colorScaleType"];
    [encoder encodeObject:captureDate	forKey: @"ExperimentCaptureDate"];
    [encoder encodeObject:segmentGroups forKey: @"ExperimentSegmentGroups"];
    [encoder encodeObject:customColor1  forKey: @"customColor1"];
    [encoder encodeObject:customColor2  forKey: @"customColor2"];
}

- (NSMutableDictionary*) captureState
{
    NSMutableDictionary* stateDictionary = [NSMutableDictionary dictionary];
    [[self document] addParametersToDictionary: stateDictionary];
    [stateDictionary writeToFile:[[self capturePListsFile] stringByExpandingTildeInPath] atomically:YES];
    
    [self setHardwareCheck:YES];
    [self setCardCheck:YES];
    [self setCaptureDate:[NSDate date]];
    return stateDictionary;
}

- (void) addObjectInfoToArray:(NSMutableArray*)anArray
{
	NSMutableDictionary* stateDictionary = [NSMutableDictionary dictionary];
	[self addParametersToDictionary:stateDictionary];
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	NSEnumerator* e = [stateDictionary keyEnumerator];
	id aKey;
	while(aKey = [e nextObject]){
		NSDictionary* d = [stateDictionary objectForKey:aKey];
		[dictionary addEntriesFromDictionary:d];
	}							
	
	[anArray addObject:dictionary];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)aDictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
	id aSegmentGroup;
	NSEnumerator* e = [segmentGroups objectEnumerator];
	while(aSegmentGroup = [e nextObject]){
		[aSegmentGroup addParametersToDictionary:objDictionary useName:@"Geometry"];
	}
    [aDictionary setObject:objDictionary forKey:[self className]];
    return aDictionary;
}

- (NSString*) capturePListsFile
{
	return [NSString stringWithFormat:@"~/Library/Preferences/edu.washington.npl.orca.capture.%@.plist",[self className]];
}


#pragma mark •••Work Methods
- (void) compileHistograms
{
	if(!scheduledToHistogram){
		[self performSelector:@selector(delayedHistogram) withObject:nil afterDelay:1];
		scheduledToHistogram = YES;
	}
}

- (NSString*) crateKey:(NSDictionary*)aDicionary
{
	NSArray* theKeys = [aDicionary allKeys];
	for(NSString* aKey in theKeys){
		if([aKey rangeOfString:@"CrateModel"].location != NSNotFound){
			return aKey;
		}
	}
	return @"";
}

- (BOOL) preRunChecks
{
	return [self preRunChecks:ignoreHWChecks];
}

//a highly hardcoded config checker. Assumes things like only one crate, ect.
- (BOOL) preRunChecks:(BOOL) skipChecks
{
	[self clearSegmentErrors];
	
	if(skipChecks)return YES;
	
    NSMutableDictionary* newDictionary  = [[self document] addParametersToDictionary: [NSMutableDictionary dictionary]];
    NSDictionary* oldDictionary         = [NSDictionary dictionaryWithContentsOfFile:[[self capturePListsFile] stringByExpandingTildeInPath]];
    
    [problemArray release];
    problemArray = [[NSMutableArray array]retain];
    // --crate presence must be same
    // --number of cards must match
    // --slots must match
    
    //init the checks to 'unknown'
    [self setHardwareCheck:2];
    [self setCardCheck:2];
    id crateKey = [self crateKey:oldDictionary];
    NSDictionary* newCrateDictionary = [newDictionary objectForKey:crateKey];
    NSDictionary* oldCrateDictionary = [oldDictionary objectForKey:crateKey];
    if(!newCrateDictionary  && oldCrateDictionary){
        [self setHardwareCheck:NO];
        [problemArray addObject:@"Crate has been removed\n"];
    }
    if(!oldCrateDictionary  && newCrateDictionary){
        [self setHardwareCheck:NO];
        [problemArray addObject:@"Crate has been added\n"];
    }
    if(newCrateDictionary && oldCrateDictionary && ![[newCrateDictionary objectForKey:@"count"] isEqualToNumber:[oldCrateDictionary objectForKey:@"count"]]){
        [self setHardwareCheck:NO];
        [problemArray addObject:@"Card count is different\n"];
    }
    
    //first scan for the cards    
    NSArray* newCardKeys = [newCrateDictionary allKeys];        
    NSArray* oldCardKeys = [oldCrateDictionary allKeys];
    NSEnumerator* eNew =  [newCardKeys objectEnumerator];
    id newCardKey;
    while( newCardKey = [eNew nextObject]){ 
        //loop over all cards, comparing old card records to new ones.
        id newCardRecord = [newCrateDictionary objectForKey:newCardKey];
        if(![[newCardRecord class] isSubclassOfClass:NSClassFromString(@"NSDictionary")])continue;
        NSEnumerator* eOld =  [oldCardKeys objectEnumerator];
        id oldCardKey;
        //grab some objects that we'll use more than once below
		NSString* slotKey = @"slot";
		if( ![newCardRecord objectForKey:slotKey]) slotKey = @"station";             
		if( ![newCardRecord objectForKey:slotKey]) slotKey = @"Card";             
        NSNumber* newSlot           = [newCardRecord objectForKey:slotKey];

        while( oldCardKey = [eOld nextObject]){ 
            id oldCardRecord = [oldCrateDictionary objectForKey:oldCardKey];
            if(![[oldCardRecord class] isSubclassOfClass:NSClassFromString(@"NSDictionary")])continue;
			NSNumber* oldSlot           = [oldCardRecord objectForKey:slotKey];

            if(newSlot && oldSlot && [newSlot isEqualToNumber:oldSlot]){
				[self checkCardOld:oldCardRecord new:newCardRecord   check:@selector(setCardCheckFailed) exclude:[NSSet setWithObjects:@"thresholdAdcs",nil]];
                //found a card so we are done.
                break;
			}
        }
    }
    
    BOOL passed = YES;
    if(hardwareCheck == 2) [self setHardwareCheck:YES];
    else if(hardwareCheck == 0){
        NSLogColor([NSColor redColor],@"Failed Hardware Config Check\n");
        passed = NO;
    }
    
    if(cardCheck == 2)[self setCardCheck:YES];
    else if(cardCheck == 0){
        NSLogColor([NSColor redColor],@"Failed Card Config Check\n");
        passed = NO;
    }
            
    if(passed)NSLog(@"Passed Configuration Checks\n");
    else {
        NSEnumerator* e = [problemArray objectEnumerator];
        id s;
        if([problemArray count]){
            NSLog(@"Configuration Check Problem Summary\n");
            while(s = [e nextObject]) NSLog(s);
            NSLog(@"\n");
        }
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:ExperimentDisplayUpdatedNeeded object:self];

    return passed;
}

- (void) printProblemSummary
{
    [self preRunChecks:NO];
}

- (void) clearTotalCounts
{
	[segmentGroups makeObjectsPerformSelector:@selector(clearTotalCounts)];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAdcInfoProvidingValueChanged object:self];
}

- (int) numberSegmentsInGroup:(int)aGroup
{
	if(aGroup == 0) return [self maxNumSegments];
	else			return 0;
}

- (NSMutableData*) thresholdDataForSet:(int)aSet
{
	NSMutableData* theData;
	int numSegments = [self numberSegmentsInGroup:aSet];
	theData = [NSMutableData dataWithLength:numSegments*sizeof(int32_t)];
	ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
	int i;
	uint32_t* p = (uint32_t*)[theData bytes];
	for(i = 0;i<numSegments;i++){
		p[i] = [segmentGroup getThreshold:i];
	}
	
	return theData;
}

- (NSString*) thresholdDataAsStringForSet:(int)aSet
{
	int numSegments = [self numberSegmentsInGroup:aSet];
	ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
	int i;
	NSString* s = @"";
	for(i = 0;i<numSegments;i++){
		s = [s stringByAppendingFormat:@"%.0f",[segmentGroup getThreshold:i]];
		if(i<numSegments-1)s = [s stringByAppendingString:@","];
	}
	return s;
}

- (void) postCouchDBRecord
{
    if([[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORCouchDBModel")] count]==0)return;
    NSMutableDictionary*  values  = [NSMutableDictionary dictionary];
    int aSet;
    int numGroups = (int)[segmentGroups count];
    for(aSet=0;aSet<numGroups;aSet++){
        NSMutableDictionary* aDictionary= [NSMutableDictionary dictionary];
        NSMutableArray* thresholdArray  = [NSMutableArray array];
        NSMutableArray* gainArray       = [NSMutableArray array];
        NSMutableArray* totalCountArray = [NSMutableArray array];
        NSMutableArray* rateArray       = [NSMutableArray array];

        ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
        int numSegments = [self numberSegmentsInGroup:aSet];
        int i;
        for(i = 0; i<numSegments; i++){
            [thresholdArray     addObject:[NSNumber numberWithFloat:[segmentGroup getThreshold:i]]];
            [gainArray          addObject:[NSNumber numberWithFloat:[segmentGroup getGain:i]]];
            [totalCountArray    addObject:[NSNumber numberWithFloat:[segmentGroup getTotalCounts:i]]];
            [rateArray          addObject:[NSNumber numberWithFloat:[segmentGroup getRate:i]]];
        }
        
        NSArray* mapEntries = [[segmentGroup paramsAsString] componentsSeparatedByString:@"\n"];
        
        if([thresholdArray count])  [aDictionary setObject:thresholdArray   forKey: @"thresholds"];
        if([gainArray count])       [aDictionary setObject:gainArray        forKey: @"gains"];
        if([totalCountArray count]) [aDictionary setObject:totalCountArray  forKey: @"totalcounts"];
        if([rateArray count])       [aDictionary setObject:rateArray        forKey: @"rates"];
        if([mapEntries count])      [aDictionary setObject:mapEntries       forKey: @"geometry"];
        id aKey = [segmentGroup groupName];
        if(aKey && aDictionary)[values setObject:aDictionary forKey:aKey];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}

- (NSMutableData*) gainDataForSet:(int)aSet
{
	NSMutableData* theData;
	int numSegments = [self numberSegmentsInGroup:aSet];
	theData = [NSMutableData dataWithLength:numSegments*sizeof(int32_t)];
	ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
	int i;
	uint32_t* p = (uint32_t*)[theData bytes];
	for(i = 0;i<numSegments;i++){
		p[i] = [segmentGroup getGain:i];
	}
	
	return theData;
}
- (NSString*) gainDataAsStringForSet:(int)aSet
{
	int numSegments = [self numberSegmentsInGroup:aSet];
	ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
	int i;
	NSString* s = @"";
	for(i = 0;i<numSegments;i++){
		s = [s stringByAppendingFormat:@"%.0f",[segmentGroup getGain:i]];
		if(i<numSegments-1)s = [s stringByAppendingString:@","];
	}
	return s;
}

- (NSMutableData*) rateDataForSet:(int)aSet;
{
	NSMutableData* theData;
	int numSegments = [self numberSegmentsInGroup:aSet];
	theData = [NSMutableData dataWithLength:numSegments*sizeof(int32_t)];
	ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
	int i;
	float* p = (float*)[theData bytes];
	for(i = 0;i<numSegments;i++){
		p[i] = [segmentGroup getRate:i];
	}
	return theData;
}
- (NSString*) rateDataAsStringForSet:(int)aSet
{
	int numSegments = [self numberSegmentsInGroup:aSet];
	ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
	int i;
	NSString* s = @"";
	for(i = 0;i<numSegments;i++){
		s = [s stringByAppendingFormat:@"%.0f",[segmentGroup getRate:i]];
		if(i<numSegments-1)s = [s stringByAppendingString:@","];
	}
	return s;
}

- (NSMutableData*) totalCountDataForSet:(int)aSet;
{
	NSMutableData* theData;
	int numSegments = [self numberSegmentsInGroup:aSet];
	theData = [NSMutableData dataWithLength:numSegments*sizeof(int32_t)];
	ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
	int i;
	uint32_t* p = (uint32_t*)[theData bytes];
	for(i = 0;i<numSegments;i++){
		p[i] = [segmentGroup getTotalCounts:i];
	}
	return theData;
}
- (NSString*) totalCountDataAsStringForSet:(int)aSet
{
	int numSegments = [self numberSegmentsInGroup:aSet];
	ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
	int i;
	NSString* s = @"";
	for(i = 0;i<numSegments;i++){
		s = [s stringByAppendingFormat:@"%.0f",[segmentGroup getTotalCounts:i]];
		if(i<numSegments-1)s = [s stringByAppendingString:@","];
	}
	return s;
}

@end

@implementation ORExperimentModel (private)

- (void) checkCardOld:(NSDictionary*)oldRecord new:(NSDictionary*)newRecord  check:(SEL)checkSelector exclude:(NSSet*)exclusionSet
{
    NSEnumerator* e = [oldRecord keyEnumerator];
    id aKey;
	NSString* slotKey = @"slot";
	if(![oldRecord objectForKey:slotKey])	slotKey = @"station";
	if(![oldRecord objectForKey:slotKey])	slotKey = @"Card";             
	BOOL segmentErrorNoted = NO;
    while(aKey = [e nextObject]){
        if(![exclusionSet containsObject:aKey]){
			id oldValues = [oldRecord objectForKey:aKey];
			id newValues =  [newRecord objectForKey:aKey];
            if(![oldValues isEqualTo:newValues]){
                [self performSelector:checkSelector];
				NSString* problemCardID = [NSString stringWithFormat:@"%@ %@ %@ changed.\n",
									[oldRecord objectForKey:@"Class Name"],
									slotKey,
									[oldRecord objectForKey:slotKey]];
                if(![problemArray containsObject:problemCardID]){
					[problemArray addObject:problemCardID];
				}
                
				if([newValues isKindOfClass:NSClassFromString(@"NSArray")]){
					int i = 0;
					for(id newVal in newValues){
						@try {
							id oldVal = [oldValues objectAtIndex:i];
							if(![oldVal isEqualTo:newVal]){
								[problemArray addObject:[NSString stringWithFormat:@"%@ %d: oldValue = %@ / newValue = %@\n",aKey,i,oldVal,newVal]];
							}
						}
						@catch (NSException* e){
						}
						i++;
					}
				}
				else {
					[problemArray addObject:[NSString stringWithFormat:@"%@: oldValue = %@ / newValue = %@\n",aKey,oldValues,newValues]];
				}
				if(!segmentErrorNoted){
					segmentErrorNoted = YES;
					if([newValues isKindOfClass:NSClassFromString(@"NSArray")]){
						int numChannels = (int)[newValues count];
						int channel;
						for(channel = 0;channel<numChannels;channel++){
							id newValue = [newValues objectAtIndex:channel];
							id oldValue = [oldValues objectAtIndex:channel];
							if(![newValue  isEqualTo: oldValue ]){
								int card = [[oldRecord objectForKey:slotKey] intValue];
								[self setSegmentErrorClassName:[oldRecord objectForKey:@"Class Name"] card:card channel:channel];
							}
						}
					}
				}
            }
        }
    }
}

- (void) delayedHistogram
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedHistogram) object:nil];
	[self histogram];

	scheduledToHistogram = NO;

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ExperimentDisplayHistogramsUpdated
                      object:self];

}


@end

