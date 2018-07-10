//
//  NcdModel.m
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "NcdModel.h"
#import "NcdController.h"
#import "NcdDetector.h"
#import "ORAxis.h"
#import "ORDataPacket.h"
#import "ORTask.h"
#import "NcdPDSStepTask.h"
#import "NcdLogAmpTask.h"
#import "NcdPulseChannelsTask.h"
#import "NcdLinearityTask.h"
#import "NcdThresholdTask.h"
#import "NcdCableCheckTask.h"

#import "ORCommandCenter.h"
#import "ORTrigger32Model.h"
#import "ORHPPulserModel.h"
#import "ORDataTypeAssigner.h"
#import "ORRunModel.h"
#import "SourceMask.h"
#import "ORDispatcherModel.h"

NSString* NcdModelReducedEfficiencyDateChanged = @"NcdModelReducedEfficiencyDateChanged";
NSString* NcdModelRunningAtReducedEfficiencyChanged = @"NcdModelRunningAtReducedEfficiencyChanged";
NSString* NcdModelCurrentMuxEfficiencyChanged = @"NcdModelCurrentMuxEfficiencyChanged";
NSString* NcdModelNominalSettingsFileChanged = @"NcdModelNominalSettingsFileChanged";
NSString* ORNcdRateColorBarChangedNotification      = @"ORNcdRateColorBarChangedNotification";
NSString* ORNcdChartXChangedNotification            = @"ORNcdChartXChangedNotification";
NSString* ORNcdChartYChangedNotification            = @"ORNcdChartYChangedNotification";
NSString* ORNcdDisplayOptionMaskChangedNotification = @"ORNcdDisplayOptionMaskChangedNotification";
NSString* ORNcdSpecialLock                          = @"ORNcdSpecialLock";
NSString* ORNcdTubeMapLock                          = @"ORNcdTubeMapLock";
NSString* ORNcdDetectorLock                         = @"ORNcdDetectorLock";
NSString* ORNcdNominalSettingsLock                  = @"ORNcdNominalSettingsLock";
NSString* ORNcdHardwareCheckChangedNotification     = @"ORNcdHardwareCheckChangedNotification";
NSString* ORNcdShaperCheckChangedNotification       = @"ORNcdShaperCheckChangedNotification";
NSString* ORNcdMuxCheckChangedNotification          = @"ORNcdMuxCheckChangedNotification";
NSString* ORNcdTriggerCheckChangedNotification      = @"ORNcdTriggerCheckChangedNotification";
NSString* ORNcdCaptureDateChangedNotification       = @"ORNcdCaptureDateChangedNotification";
NSString* ORNcdRateAllDisableChangedNotification    = @"ORNcdRateAllDisableChangedNotification";

enum {
    kDisplayTubeLabel = (1 << 0)
};

#define kNcdModelNumberOfTasks 5

@interface NcdModel (private)
- (void) checkCardOld:(NSDictionary*)oldCardRecord new:(NSDictionary*)newCardRecord  check:(SEL)checkSelector exclude:(NSSet*)exclusionSet;
- (void) checkMuxOld:(NSDictionary*)oldCardRecord new:(NSDictionary*)newCardRecord  check:(SEL)checkSelector exclude:(NSSet*)exclusionSet;
- (void) checkBuilderConnection;
@end


@implementation NcdModel

#pragma mark ¥¥¥Initialization

- (id) init //designated initializer
{
    self = [super init];
    
    colorBarAttributes = [[NSMutableDictionary dictionary] retain];
    [colorBarAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
    [colorBarAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
    [colorBarAttributes setObject:[NSNumber numberWithBool:NO] forKey:ORAxisUseLog];
    
	
    altMuxThresholds = [[NSMutableArray alloc] init];
    fullEfficiencyMuxThresholds = [[NSMutableArray alloc] init];
	
    return self;
    
    
    return self;
}

-(void)dealloc
{
    NcdDetector* ncdDet = [NcdDetector sharedInstance];
	[ncdDet setDelegate:nil];

    [reducedEfficiencyDate release];
    [nominalSettingsFile release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [colorBarAttributes release];
    [xAttributes release];
    [yAttributes release];
    
    [ncdPulseChannelsTask setDelegate:self];
    [ncdPulseChannelsTask release];
    ncdPulseChannelsTask = nil;
    
    [ncdPDSStepTask setDelegate:self];
    [ncdPDSStepTask release];
    ncdPDSStepTask = nil;
    
	[ncdLogAmpTask setDelegate:self];
	[ncdLogAmpTask release];
    ncdLogAmpTask = nil;
    
	[ncdLinearityTask setDelegate:self];
    [ncdLinearityTask release];
    ncdLinearityTask = nil;
    
	[ncdThresholdTask setDelegate:self];
    [ncdThresholdTask release];
    ncdThresholdTask = nil;
    
	[ncdCableCheckTask setDelegate:self];
    [ncdCableCheckTask release];
    ncdCableCheckTask = nil;
    
    [failedHardwareCheckAlarm clearAlarm];
    [failedHardwareCheckAlarm release];
    
    [failedShaperCheckAlarm clearAlarm];
    [failedShaperCheckAlarm release];
	
    [failedTriggerCheckAlarm clearAlarm];
    [failedTriggerCheckAlarm release];
	
	[failedMuxCheckAlarm clearAlarm];
    [failedMuxCheckAlarm release];
	
	[noDispatcherAlarm clearAlarm];
    [noDispatcherAlarm release];
	
	[builderNotConnectedAlarm clearAlarm];
    [builderNotConnectedAlarm release];
	
    [captureDate release];
    [problemArray release];
    [altMuxThresholds release];
    [fullEfficiencyMuxThresholds release];
    
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self configurationChanged:nil];
    [ncdPulseChannelsTask wakeUp];
    [ncdPDSStepTask wakeUp];
    [ncdLogAmpTask wakeUp];
    [ncdLinearityTask wakeUp];
    [ncdThresholdTask wakeUp];
    [ncdCableCheckTask wakeUp];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
    
    [ncdPulseChannelsTask sleep];
    [ncdPDSStepTask sleep];
    [ncdLogAmpTask sleep];
    [ncdLinearityTask sleep];
    [ncdThresholdTask sleep];
    [ncdCableCheckTask sleep];
	
    [noDispatcherAlarm clearAlarm];
	[noDispatcherAlarm release];
	noDispatcherAlarm = nil;
	
	[failedHardwareCheckAlarm clearAlarm];
    [failedHardwareCheckAlarm release];
	failedHardwareCheckAlarm = nil;
    
    [failedShaperCheckAlarm clearAlarm];
    [failedShaperCheckAlarm release];
	failedShaperCheckAlarm = nil;
	
    [failedTriggerCheckAlarm clearAlarm];
    [failedTriggerCheckAlarm release];
	failedTriggerCheckAlarm = nil;
	
	[failedMuxCheckAlarm clearAlarm];
    [failedMuxCheckAlarm release];
	failedMuxCheckAlarm = nil;
	
	
	[builderNotConnectedAlarm clearAlarm];
    [builderNotConnectedAlarm release];
	builderNotConnectedAlarm = nil;
	
	
}

- (void) installTasks:(NSNotification*)aNote
{
    
    //NOTE if you add a task don't forget to increment the kNcdModelNumberOfTasks 
    //constant at the top of this file.
    
    if(!ncdLogAmpTask){
        ncdLogAmpTask = [[NcdLogAmpTask alloc] init];
    }
	
    [ncdLogAmpTask setDelegate:self];
    [ncdLogAmpTask wakeUp];
    
    if(!ncdLinearityTask){
        ncdLinearityTask = [[NcdLinearityTask alloc] init];
    }
    [ncdLinearityTask setDelegate:self];
    [ncdLinearityTask wakeUp];
    
    if(!ncdThresholdTask){
        ncdThresholdTask = [[NcdThresholdTask alloc] init];
    }
    [ncdThresholdTask setDelegate:self];
    [ncdThresholdTask wakeUp];
    
    if(!ncdCableCheckTask){
        ncdCableCheckTask = [[NcdCableCheckTask alloc] init];
    }
    [ncdCableCheckTask setDelegate:self];
    [ncdCableCheckTask wakeUp];
	
    if(!ncdPulseChannelsTask){
        ncdPulseChannelsTask = [[NcdPulseChannelsTask alloc] init];
    }
    [ncdPulseChannelsTask setDelegate:self];
    [ncdPulseChannelsTask wakeUp];
    [ncdPulseChannelsTask setTitle:@"NRE"];
    
    if(!ncdPDSStepTask){
        ncdPDSStepTask = [[NcdPDSStepTask alloc] init];
    }
    
    [ncdPDSStepTask setDelegate:self];
    [ncdPDSStepTask wakeUp];
    
}

- (id) dependentTask:(ORTask*)aTask
{
    if(aTask == ncdLogAmpTask)				return ncdPDSStepTask;
    else if(aTask == ncdLinearityTask)		return ncdPDSStepTask;
    else if(aTask == ncdThresholdTask)		return ncdPDSStepTask;
    else if(aTask == ncdPulseChannelsTask)	return ncdPulseChannelsTask;
    else return nil;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Ncd"]];
}

- (void) makeMainController
{
    [self linkToController:@"NcdController"];
}

- (NSString*) helpURL
{
	return @"NCD/NCD_Control.html";
}

- (void) reloadData:(id)obj
{
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORNcdRateColorBarChangedNotification
	 object:self];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(installTasks:)
                         name : ORDocumentLoadedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORDocumentLoadedNotification
                       object : nil];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runEnded:)
                         name : ORRunStoppedNotification
                       object : nil];
	
}

- (void) registerForRates
{
    [self registerForShaperRates];
    [self registerForMuxRates];
}

- (void) registerForShaperRates
{
    [[self detector] registerForShaperRates:[[self document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")]];
}

- (void) registerForMuxRates
{
    [[self detector] registerForMuxRates:[[self document] collectObjectsOfClass:NSClassFromString(@"NcdMuxBoxModel")]];
}


- (void) configurationChanged:(NSNotification*)aNote
{
    [[self detector] configurationChanged];
}

- (void) runStatusChanged:(NSNotification*)aNote
{
    int running = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
    if(running == eRunStopped){
        if( [ncdLogAmpTask taskState]    == eTaskRunning)[ncdLogAmpTask hardHaltTask];
        if( [ncdLinearityTask taskState] == eTaskRunning)[ncdLinearityTask hardHaltTask];
        if( [ncdThresholdTask taskState] == eTaskRunning)[ncdThresholdTask hardHaltTask];
        if( [ncdCableCheckTask taskState]== eTaskRunning)[ncdCableCheckTask hardHaltTask];
        if( [ncdPDSStepTask taskState]   == eTaskRunning)[ncdPDSStepTask hardHaltTask];
        if( [ncdPulseChannelsTask taskState]   == eTaskRunning)[ncdPulseChannelsTask hardHaltTask];
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
    NcdDetector* theDetector = [NcdDetector sharedInstance];
    [theDetector collectTotalShaperRate];
    [theDetector collectTotalMuxRate];
    [self performSelector:@selector(collectRates) withObject:nil afterDelay:5.0];
    //tell anybody connected what our rates are.
    [[ORCommandCenter sharedCommandCenter] sendCmd:@"OrcaRates" withString:[NSString stringWithFormat:@"%f %f",[theDetector shaperRate],[theDetector muxRate]]];
}


#pragma mark ¥¥¥Accessors

- (NSDate*) reducedEfficiencyDate
{
    return reducedEfficiencyDate;
}

- (void) setReducedEfficiencyDate:(NSDate*)aReducedEfficiencyDate
{
    [aReducedEfficiencyDate retain];
    [reducedEfficiencyDate release];
    reducedEfficiencyDate = aReducedEfficiencyDate;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:NcdModelReducedEfficiencyDateChanged object:self];
}

- (BOOL) runningAtReducedEfficiency
{
    return runningAtReducedEfficiency;
}

- (void) setRunningAtReducedEfficiency:(BOOL)aRunningAtReducedEfficiency
{
    runningAtReducedEfficiency = aRunningAtReducedEfficiency;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:NcdModelRunningAtReducedEfficiencyChanged object:self];
}

- (float) currentMuxEfficiency
{
    return currentMuxEfficiency;
}

- (void) setCurrentMuxEfficiency:(float)aCurrentMuxEfficiency
{
	if(aCurrentMuxEfficiency == 0)aCurrentMuxEfficiency = 90;
    [[[self undoManager] prepareWithInvocationTarget:self] setCurrentMuxEfficiency:currentMuxEfficiency];
    
    currentMuxEfficiency = aCurrentMuxEfficiency;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:NcdModelCurrentMuxEfficiencyChanged object:self];
}

- (NSString*) nominalSettingsFile
{
    return nominalSettingsFile;
}

- (void) setNominalSettingsFile:(NSString*)aNominalSettingsFile
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNominalSettingsFile:nominalSettingsFile];
    
    [nominalSettingsFile autorelease];
    nominalSettingsFile = [aNominalSettingsFile copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:NcdModelNominalSettingsFileChanged object:self];
}
- (BOOL)allDisabled
{
    return allDisabled;
}
- (void)setAllDisabled:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAllDisabled:allDisabled];
    allDisabled = flag;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORNcdRateAllDisableChangedNotification
	 object:self];
}

- (NSMutableArray *)altMuxThresholds
{
    return altMuxThresholds;
}

- (void)setAltMuxThresholds:(NSMutableArray *)anArray
{
    if (altMuxThresholds != anArray) {
        [altMuxThresholds release];
        altMuxThresholds = [anArray mutableCopy];
    }
    
}

- (NSMutableArray *)fullEfficiencyMuxThresholds
{
    return fullEfficiencyMuxThresholds;
}

- (void)setFullEfficiencyMuxThresholds:(NSMutableArray *)anArray
{
    if (fullEfficiencyMuxThresholds != anArray) {
        [fullEfficiencyMuxThresholds release];
        fullEfficiencyMuxThresholds = [anArray mutableCopy];
    }
}


- (NSMutableDictionary*) colorBarAttributes
{
    return colorBarAttributes;
}
- (void) setColorBarAttributes:(NSMutableDictionary*)newColorBarAttributes
{
    [[[self undoManager] prepareWithInvocationTarget:self] setColorBarAttributes:colorBarAttributes];
    
    [newColorBarAttributes retain];
    [colorBarAttributes release];
    colorBarAttributes=newColorBarAttributes;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORNcdRateColorBarChangedNotification
	 object:self];
    
}

- (NSDictionary*)xAttributes
{
    return xAttributes;
}

- (NSDictionary*)   yAttributes
{
    return yAttributes;
}

- (void) setYAttributes:(NSMutableDictionary*)someAttributes
{
    [yAttributes release];
    yAttributes = [someAttributes copy];
}

- (void) setXAttributes:(NSMutableDictionary*)someAttributes
{
    [xAttributes release];
    xAttributes = [someAttributes copy];
}


- (NcdDetector*) detector
{
    return [NcdDetector sharedInstance];
}

- (int) hardwareCheck
{
    return hardwareCheck;
}

- (void) setHardwareCheck: (int) aState
{
    hardwareCheck = aState;
    [[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORNcdHardwareCheckChangedNotification
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


- (int) shaperCheck
{
    return shaperCheck;
}

- (void) setShaperCheck: (int) aState
{
    shaperCheck = aState;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORNcdShaperCheckChangedNotification
	 object:self];
    
    if(shaperCheck==NO) {
		if(!failedShaperCheckAlarm){
			failedShaperCheckAlarm = [[ORAlarm alloc] initWithName:@"Shaper Card Check Failed" severity:kSetupAlarm];
			[failedShaperCheckAlarm setSticky:YES];
		}
		[failedShaperCheckAlarm setAcknowledged:NO];
		[failedShaperCheckAlarm postAlarm];
        [failedShaperCheckAlarm setHelpStringFromFile:@"ShaperCheckHelp"];
    }
    else {
        [failedShaperCheckAlarm clearAlarm];
    }
}


- (int) muxCheck
{
    return muxCheck;
}

- (void) setMuxCheck: (int) aState
{
    muxCheck = aState;
    [[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORNcdMuxCheckChangedNotification
	 object:self];
    if(muxCheck==NO) {
		if(!failedMuxCheckAlarm){
			failedMuxCheckAlarm = [[ORAlarm alloc] initWithName:@"Mux Check Failed" severity:kSetupAlarm];
			[failedMuxCheckAlarm setSticky:YES];
		}
		[failedMuxCheckAlarm setAcknowledged:NO];
		[failedMuxCheckAlarm postAlarm];
        [failedMuxCheckAlarm setHelpStringFromFile:@"MuxCheckHelp"];
    }
    else {
        [failedMuxCheckAlarm clearAlarm];
    }
}


- (int) triggerCheck
{
    return triggerCheck;
}

- (void) setTriggerCheck: (int) aState
{
    triggerCheck = aState;
    [[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORNcdTriggerCheckChangedNotification
	 object:self];
    if(triggerCheck==NO) {
		if(!failedTriggerCheckAlarm){
			failedTriggerCheckAlarm = [[ORAlarm alloc] initWithName:@"Trigger Card Check Failed" severity:kSetupAlarm];
			[failedTriggerCheckAlarm setSticky:YES];
		}
		[failedTriggerCheckAlarm setAcknowledged:NO];
		[failedTriggerCheckAlarm postAlarm];
        [failedTriggerCheckAlarm setHelpStringFromFile:@"TriggerCheckHelp"];
    }
    else {
        [failedTriggerCheckAlarm clearAlarm];
    }
}

- (void) setTriggerCheckFailed
{
    [self setTriggerCheck:NO];
}

- (void) setShaperCheckFailed
{
    [self setShaperCheck:NO];
}

- (void) setMuxCheckFailed
{
    [self setMuxCheck:NO];
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
	 postNotificationName:ORNcdCaptureDateChangedNotification
	 object:self];
    
}

//------Nominal Settings Actions

- (void) modifiyMuxEfficiency
{
	if(!runningAtReducedEfficiency){
		[[self detector] saveMuxMementos:fullEfficiencyMuxThresholds];
		
		[[self detector] setMuxEfficiency:currentMuxEfficiency];
		[self setRunningAtReducedEfficiency:YES];
		[self setReducedEfficiencyDate:[NSDate date]];
		NSLog(@"Running Mux efficiency at %0.f%%\n",currentMuxEfficiency);
	}
}

- (void) restoreMuxEfficiency
{
	[[self detector] restoreMuxMementos:fullEfficiencyMuxThresholds];
	[self setRunningAtReducedEfficiency:NO];
	NSLog(@"Restored Mux efficiency to previous value. (Was at %.0f%%)\n",currentMuxEfficiency);
}

- (void) saveNominalSettingsTo:(NSString*)filePath
{
	if(filePath){
		filePath = [filePath stringByExpandingTildeInPath];
		
		NSMutableArray* muxNominals = [NSMutableArray array];
		[[self detector] saveMuxMementos:muxNominals];
		
		NSMutableArray* shaperGainNominals = [NSMutableArray array];
		[[self detector] saveShaperGainMementos:shaperGainNominals];
		
		NSMutableArray* shaperThresholdNominals = [NSMutableArray array];
		[[self detector] saveShaperThresholdMementos:shaperThresholdNominals];
		
		NSDictionary* theMementos = [NSDictionary dictionaryWithObjectsAndKeys:muxNominals,@"Mux",
									 shaperGainNominals,@"ShaperGains",
									 shaperThresholdNominals,@"ShaperThresholds",
									 nil];
		[theMementos writeToFile:filePath atomically:YES];
		[self setNominalSettingsFile:filePath];
		
		NSLog(@"Saved Mux and Shaper nominal values to file: %@\n",[nominalSettingsFile stringByAbbreviatingWithTildeInPath]);
	}
}

- (void) restoreToNomional
{
	if(nominalSettingsFile){
		if([[NSFileManager defaultManager] fileExistsAtPath:nominalSettingsFile]){
			NSLog(@"Restoring Mux and Shaper settings to nominal values (file: %@)\n",[nominalSettingsFile stringByAbbreviatingWithTildeInPath]);
			NSDictionary* theMementos = [NSDictionary dictionaryWithContentsOfFile:nominalSettingsFile];
			NSArray* array;
			array = [theMementos objectForKey:@"Mux"];
			[[self detector] restoreMuxMementos:array];
			array = [theMementos objectForKey:@"ShaperGains"];
			[[self detector] restoreShaperGainMementos:array];
			array = [theMementos objectForKey:@"ShaperThresholds"];
			[[self detector] restoreShaperThresholdMementos:array];
		}
		else {
			NSLogColor([NSColor redColor],@"Nominal settings file <%@> not found!\n",nominalSettingsFile);
		}
	}
}

- (void) restoreMuxesToNomional
{
	if(nominalSettingsFile){
		if([[NSFileManager defaultManager] fileExistsAtPath:nominalSettingsFile]){
			NSLog(@"Restoring Mux Thresholds to nominal settings (file: %@)\n",[nominalSettingsFile stringByAbbreviatingWithTildeInPath]);
			NSDictionary* theMementos = [NSDictionary dictionaryWithContentsOfFile:nominalSettingsFile];
			NSArray* array;
			array = [theMementos objectForKey:@"Mux"];
			[[self detector] restoreMuxMementos:array];
		}
		else {
			NSLogColor([NSColor redColor],@"Nominal settings file <%@> not found!\n",nominalSettingsFile);
		}
	}
}

- (void) restoreShapersToNominal
{
	if(nominalSettingsFile){
		if([[NSFileManager defaultManager] fileExistsAtPath:nominalSettingsFile]){
			NSLog(@"Restoring Shaper Thresholds and Gains to nominal settings (file: %@)\n",[nominalSettingsFile stringByAbbreviatingWithTildeInPath]);
			NSDictionary* theMementos = [NSDictionary dictionaryWithContentsOfFile:nominalSettingsFile];
			NSArray* array;
			array = [theMementos objectForKey:@"ShaperGains"];
			[[self detector] restoreShaperGainMementos:array];
			array = [theMementos objectForKey:@"ShaperThresholds"];
			[[self detector] restoreShaperThresholdMementos:array];
			
		}
		else {
			NSLogColor([NSColor redColor],@"Nominal settings file <%@> not found!\n",nominalSettingsFile);
		}
	}
}

- (void) restoreShaperGainsToNominal
{
	if(nominalSettingsFile){
		if([[NSFileManager defaultManager] fileExistsAtPath:nominalSettingsFile]){
			NSLog(@"Restoring Shaper Gains to nominal settings (file: %@)\n",[nominalSettingsFile stringByAbbreviatingWithTildeInPath]);
			NSDictionary* theMementos = [NSDictionary dictionaryWithContentsOfFile:nominalSettingsFile];
			NSArray* array;
			array = [theMementos objectForKey:@"ShaperGains"];
			[[self detector] restoreShaperGainMementos:array];
		}
		else {
			NSLogColor([NSColor redColor],@"Nominal settings file <%@> not found!\n",nominalSettingsFile);
		}
	}
}

- (void) restoreShaperThresholdsToNominal
{
	if(nominalSettingsFile){
		if([[NSFileManager defaultManager] fileExistsAtPath:nominalSettingsFile]){
			NSLog(@"Restoring Shaper Thresholds to nominal settings (file: %@)\n",[nominalSettingsFile stringByAbbreviatingWithTildeInPath]);
			NSDictionary* theMementos = [NSDictionary dictionaryWithContentsOfFile:nominalSettingsFile];
			NSArray* array;
			array = [theMementos objectForKey:@"ShaperThresholds"];
			[[self detector] restoreShaperThresholdMementos:array];
		}
		else {
			NSLogColor([NSColor redColor],@"Nominal settings file <%@> not found!\n",nominalSettingsFile);
		}
	}
}


// ----------------------------------------------------------
// - displayOptionMask:
// ----------------------------------------------------------
- (unsigned long) displayOptionMask
{
    return displayOptionMask;
}

// ----------------------------------------------------------
// - setDisplayOptionMask:
// ----------------------------------------------------------
- (void) setDisplayOptionMask: (unsigned long) aDisplayOptionMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisplayOptionMask:displayOptionMask];
    displayOptionMask = aDisplayOptionMask;
    [[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORNcdDisplayOptionMaskChangedNotification
	 object:self];
    
}

- (void) setDisplayOption:(short)optionTag state:(BOOL)aState
{
    unsigned long aMask = displayOptionMask;
    if(aState){
        aMask |= (1L<<optionTag);
    }
    else {
        aMask &= ~(1L<<optionTag);
    }
    [self setDisplayOptionMask:aMask];
}

- (BOOL) displayOptionState:(int)optionTag
{
    return (displayOptionMask&(1<<optionTag))!=0L ;
}

- (BOOL) drawTubeLabel
{
    return (displayOptionMask & kDisplayTubeLabel)!=0;
}



#pragma mark ¥¥¥Archival
static NSString* ORNcdColorBarAttributes        = @"ORNcdColorBarAttributes";
static NSString* ORNcdPulseChannelsTask         = @"ORNcdPulseChannelsTask";
static NSString* ORNcdPDSStepTask               = @"ORNcdPDSStepTask";
static NSString* ORNcdLogAmpCalibrationTask     = @"ORNcdLogAmpCalibrationTask1";
static NSString* ORNcdLinearityCalibrationTask  = @"ORNcdLinearityCalibrationTask";
static NSString* ORNcdThresholdCalibrationTask  = @"ORNcdThresholdCalibrationTask";
static NSString* ORNcdDisplayOptionMask         = @"ORNcdDisplayOptionMask";
static NSString *ORNcdXAttributes               = @"ORNcdXAttributes";
static NSString *ORNcdYAttributes               = @"ORNcdYAttributes";
static NSString *ORNcdHardwareCheck             = @"ORNcdHardwareCheck";
static NSString *ORNcdShaperCheck               = @"ORNcdShaperCheck";
static NSString *ORNcdMuxCheck                  = @"ORNcdMuxCheck";
static NSString *ORNcdTriggerCheck              = @"ORNcdTriggerCheck";
static NSString *ORNcdCaptureDate               = @"ORNcdCaptureDate";
static NSString *ORNcdCableCheckTask            = @"ORNcdCableCheckTask";
static NSString *ORNcdMuxAltThresholds          = @"ORNcdMuxAltThresholds";
static NSString *ORNcdAllDisabled               =@"ORNcdAllDisabled";
static NSString *ORNcdMuxFullEfficiencyThresholds = @"ORNcdMuxFullEfficiencyThresholds";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    
    [self setReducedEfficiencyDate:[decoder decodeObjectForKey:@"NcdModelReducedEfficiencyDate"]];
    [self setRunningAtReducedEfficiency:[decoder decodeBoolForKey:@"NcdModelRunningAtReducedEfficiency"]];
    [self setCurrentMuxEfficiency:[decoder decodeFloatForKey:@"NcdModelCurrentMuxEfficiency"]];
    [self setNominalSettingsFile:[decoder decodeObjectForKey:@"NcdModelNominalSettingsFile"]];
    [[NcdDetector sharedInstance] loadWithCoder:decoder];
    [(NcdDetector*)[NcdDetector sharedInstance] setDelegate:(id)self];
    
    
    ncdPulseChannelsTask = [[decoder decodeObjectForKey:ORNcdPulseChannelsTask] retain];
    ncdPDSStepTask = [[decoder decodeObjectForKey:ORNcdPDSStepTask] retain];
    ncdLogAmpTask = [[decoder decodeObjectForKey:ORNcdLogAmpCalibrationTask] retain];
    ncdLinearityTask = [[decoder decodeObjectForKey:ORNcdLinearityCalibrationTask] retain];
    ncdThresholdTask = [[decoder decodeObjectForKey:ORNcdThresholdCalibrationTask] retain];
    ncdCableCheckTask = [[decoder decodeObjectForKey:ORNcdCableCheckTask] retain];
    [self installTasks:nil];
    
    [self setColorBarAttributes:[decoder decodeObjectForKey:ORNcdColorBarAttributes]];
    [self setXAttributes:[decoder decodeObjectForKey:ORNcdXAttributes]];
    [self setYAttributes:[decoder decodeObjectForKey:ORNcdYAttributes]];
    [self setDisplayOptionMask:[decoder decodeInt32ForKey:ORNcdDisplayOptionMask]];
    
    [self setHardwareCheck:[decoder decodeIntForKey:ORNcdHardwareCheck]];
    [self setShaperCheck:[decoder decodeIntForKey:ORNcdShaperCheck]];
    [self setMuxCheck:[decoder decodeIntForKey:ORNcdMuxCheck]];
    [self setTriggerCheck:[decoder decodeIntForKey:ORNcdTriggerCheck]];
    [self setCaptureDate:[decoder decodeObjectForKey:ORNcdCaptureDate]];
    [self setAltMuxThresholds:[decoder decodeObjectForKey:ORNcdMuxAltThresholds]];
    [self setFullEfficiencyMuxThresholds:[decoder decodeObjectForKey:ORNcdMuxFullEfficiencyThresholds]];
    [self setAllDisabled:[decoder decodeBoolForKey:ORNcdAllDisabled]];
    
    if(!altMuxThresholds)[self setAltMuxThresholds:[NSMutableArray array]];
    if(!fullEfficiencyMuxThresholds)[self setFullEfficiencyMuxThresholds:[NSMutableArray array]];
	
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [[NcdDetector sharedInstance] saveWithCoder:encoder];
    
	
	
    [encoder encodeObject:reducedEfficiencyDate forKey:@"NcdModelReducedEfficiencyDate"];
    [encoder encodeBool:runningAtReducedEfficiency forKey:@"NcdModelRunningAtReducedEfficiency"];
    [encoder encodeFloat:currentMuxEfficiency forKey:@"NcdModelCurrentMuxEfficiency"];
    [encoder encodeObject:nominalSettingsFile forKey:@"NcdModelNominalSettingsFile"];
    [encoder encodeBool:allDisabled forKey:ORNcdAllDisabled];
	
    [encoder encodeObject:ncdPulseChannelsTask forKey:ORNcdPulseChannelsTask];
    [encoder encodeObject:ncdPDSStepTask forKey:ORNcdPDSStepTask];
    [encoder encodeObject:ncdLogAmpTask forKey:ORNcdLogAmpCalibrationTask];
    [encoder encodeObject:ncdLinearityTask forKey:ORNcdLinearityCalibrationTask];
    [encoder encodeObject:ncdThresholdTask forKey:ORNcdThresholdCalibrationTask];
    [encoder encodeObject:ncdCableCheckTask forKey:ORNcdCableCheckTask];
    
    [encoder encodeObject:colorBarAttributes forKey:ORNcdColorBarAttributes];
    [encoder encodeInt32:displayOptionMask forKey:ORNcdDisplayOptionMask];
    [encoder encodeObject:xAttributes forKey:ORNcdXAttributes];
    [encoder encodeObject:yAttributes forKey:ORNcdYAttributes];
    
    [encoder encodeInt:hardwareCheck forKey:ORNcdHardwareCheck];
    [encoder encodeInt:shaperCheck forKey:ORNcdShaperCheck];
    [encoder encodeInt:muxCheck forKey:ORNcdMuxCheck];
    [encoder encodeInt:triggerCheck forKey:ORNcdTriggerCheck];
    
    [encoder encodeObject:captureDate forKey:ORNcdCaptureDate];
    [encoder encodeObject:altMuxThresholds forKey:ORNcdMuxAltThresholds];
    [encoder encodeObject:fullEfficiencyMuxThresholds forKey:ORNcdMuxFullEfficiencyThresholds];
}

- (void) standAloneMode:(BOOL)state
{
    NSArray* theTriggerCards = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORTrigger32Model")];
    if([theTriggerCards count]){
        ORTrigger32Model* theTrigger = [theTriggerCards objectAtIndex:0];
        [theTrigger standAloneMode:state];	
    }
    NSArray* theRunControlObjs = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if([theRunControlObjs count]){
        ORRunModel* theRunControl = [theRunControlObjs objectAtIndex:0];
        [theRunControl setRemoteControl:NO];
    }
    
}


- (unsigned long) pulserDataId { return pulserDataId; }
- (void) setPulserDataId: (unsigned long) PulserDataId
{
    pulserDataId = PulserDataId;
}


- (unsigned long) logAmpDataId { return logAmpDataId; }
- (void) setLogAmpDataId: (unsigned long) LogAmpDataId
{
    logAmpDataId = LogAmpDataId;
}


- (unsigned long) linearityDataId { return linearityDataId; }
- (void) setLinearityDataId: (unsigned long) LinearityDataId
{
    linearityDataId = LinearityDataId;
}


- (unsigned long) thresholdDataId { return thresholdDataId; }
- (void) setThresholdDataId: (unsigned long) ThresholdDataId
{
    thresholdDataId = ThresholdDataId;
}

- (unsigned long) cableCheckDataId { return cableCheckDataId; }
- (void) setCableCheckDataId: (unsigned long) aCableCheckDataId
{
    cableCheckDataId = aCableCheckDataId;
}


- (unsigned long) stepPDSDataId { return stepPDSDataId; }
- (void) setStepPDSDataId: (unsigned long) StepPDSDataId
{
    stepPDSDataId = StepPDSDataId;
}


- (void)setSourceMask:(unsigned long)aMask
{
    sourceMask = aMask;
}

- (void) runAboutToStart:(NSNotification*)aNote
{
    unsigned long runTypeMask = [[[aNote userInfo] objectForKey:@"RunType"] longValue];
    //note that the source is placed in this object magically by SHaRC at the start of run.
    //note that the runType masks are shifted by one compared to SHaRC because
    //ORCA reserves bit 0 for its own maintenance run type.
    if(!allDisabled && (runTypeMask &  0x4)){
        NSEnumerator* e = [altMuxThresholds objectEnumerator];
        NSDictionary* obj;
        while(obj = [e nextObject]){
            SourceMask* theSourceMaskObj = [obj objectForKey:@"sourceMask"];
            if(sourceMask & (0x1L << [theSourceMaskObj value])){
                if([[obj objectForKey:@"enabled"] intValue]){
                    [[self detector] saveMuxMementos];
                    muxMementosExist = YES;
                    [[self detector] replaceMuxThresholdsUsingFile: [obj objectForKey:@"muxFile"]];
                    break;
                }
            }
        }
    }
	
	//only run the pulser channel task if in neutrino run or source run.
	if(runTypeMask &  0x2 || runTypeMask &  0x4){
		if(runTypeMask &  0x2 ){
			//source run
			[ncdPulseChannelsTask setUseNeutrinoRun:YES];
			if([ncdPulseChannelsTask autoStart]){
				[ncdPulseChannelsTask startTask];
			}
		}
		else {
			[ncdPulseChannelsTask setUseNeutrinoRun:NO];
			if([ncdPulseChannelsTask autoStartForSourceRun]){
				[ncdPulseChannelsTask startTask];
			}
		}
		
	}
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkBuilderConnection) object:nil];
	[self performSelector:@selector(checkBuilderConnection) withObject:nil afterDelay:0];
	
}

- (void) runEnded:(NSNotification*)aNote
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkBuilderConnection) object:nil];
    if(muxMementosExist){
        muxMementosExist = NO;
		sourceMask = 0;
        [[self detector] restoreMuxMementos];
    }
	
	if([ncdPulseChannelsTask taskState] == eTaskRunning || [ncdPulseChannelsTask taskState] == eTaskWaiting){
		[ncdPulseChannelsTask stopTask];
	}
	
}

- (void) taskDidStart:(NSNotification*)aNote
{
	//this really means a task is about to start....
	id task = [aNote object];
	
	if(task != ncdPulseChannelsTask){
		if([ncdPulseChannelsTask taskState] == eTaskRunning || [ncdPulseChannelsTask taskState] == eTaskWaiting){
			[ncdPulseChannelsTask stopTask];
		}
	}
	
	
    [self shipTaskRecord:[aNote object] running:YES];
}

- (void) taskDidFinish:(NSNotification*)aNote
{
    [self shipTaskRecord:[aNote object] running:NO];
}

- (int) getLogAmpState
{
    return (int)[ncdLogAmpTask taskState];
}

- (int) getExtendedLinearityState
{
    return (int)[ncdLinearityTask taskState];
}

- (int) getLinearityState
{
    return (int)[ncdLinearityTask taskState];
}
- (int) getThresholdState
{
    return (int)[ncdThresholdTask taskState];
}

- (int) getCableCheckState
{
    return (int)[ncdCableCheckTask taskState];
}

- (int) getPulseChannelsState
{
    return (int)[ncdPulseChannelsTask taskState];
}

- (void) startLogAmp:(BOOL)state
{
    if(state == YES) {
        if([ncdLogAmpTask taskState] == eTaskStopped){
            [ncdLogAmpTask startTask];
        }
    }
    else {
        if([ncdLogAmpTask taskState] == eTaskRunning || [ncdLogAmpTask taskState] == eTaskWaiting){
            [ncdLogAmpTask stopTask];
        }
    }
}

- (void) startLinearity:(BOOL)state
{
    if(state == YES) {
        if([ncdLinearityTask taskState] == eTaskStopped){
            [ncdLinearityTask setExtendedLinearity:NO];
            [ncdLinearityTask startTask];
        }
    }
    else {
        if([ncdLinearityTask taskState] == eTaskRunning || [ncdLinearityTask taskState] == eTaskWaiting){
            [ncdLinearityTask stopTask];
        }
    }
}

- (void) startExtendedLinearity:(BOOL)state
{
    if(state == YES) {
        if([ncdLinearityTask taskState] == eTaskStopped){
            [ncdLinearityTask setExtendedLinearity:YES];
            [ncdLinearityTask startTask];
        }
    }
    else {
        if([ncdLinearityTask taskState] == eTaskRunning || [ncdLinearityTask taskState] == eTaskWaiting){
            [ncdLinearityTask stopTask];
        }
    }
}

- (void) startThreshold:(BOOL)state
{
    if(state == YES) {
        if([ncdThresholdTask taskState] == eTaskStopped){
            [ncdThresholdTask startTask];
        }
    }
    else {
        if([ncdThresholdTask taskState] == eTaskRunning || [ncdThresholdTask taskState] == eTaskWaiting){
            [ncdThresholdTask stopTask];
        }
    }
}

- (void) startNRE:(BOOL)state
{
    if(state == YES) {
        if([ncdPulseChannelsTask taskState] == eTaskStopped){
            [ncdPulseChannelsTask startTask];
        }
    }
    else {
        if([ncdPulseChannelsTask taskState] == eTaskRunning || [ncdPulseChannelsTask taskState] == eTaskWaiting){
            [ncdPulseChannelsTask stopTask];
        }
    }
}

- (void) startCableCheck:(BOOL)state
{
    if(state == YES) {
        if([ncdCableCheckTask taskState] == eTaskStopped){
            [ncdCableCheckTask startTask];
        }
    }
    else {
        if([ncdCableCheckTask taskState] == eTaskRunning || [ncdCableCheckTask taskState] == eTaskWaiting){
            [ncdCableCheckTask stopTask];
        }
    }
}
- (NSString*) descriptionLinearity     { return [ncdLinearityTask description];    }
- (NSString*) descriptionExtendedLinearity  { return [ncdLinearityTask description];    }
- (NSString*) descriptionCableCheck    { return [ncdCableCheckTask description];   }
- (NSString*) descriptionThreshold     { return [ncdThresholdTask description];    }
- (NSString*) descriptionLogAmp        { return [ncdLogAmpTask description];       }
- (NSString*) descriptionPulseChannels { return [ncdPulseChannelsTask description];       }

- (void) setDataIds:(id)assigner
{
    pulserDataId        = [assigner assignDataIds:kLongForm];
    logAmpDataId        = [assigner assignDataIds:kLongForm];
    linearityDataId     = [assigner assignDataIds:kLongForm];
    thresholdDataId     = [assigner assignDataIds:kLongForm];
    cableCheckDataId    = [assigner assignDataIds:kLongForm];
    stepPDSDataId       = [assigner assignDataIds:kLongForm];
    pulseChannelsDataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setPulserDataId:[anotherObj pulserDataId]];
    [self setLogAmpDataId:[anotherObj logAmpDataId]];
    [self setLinearityDataId:[anotherObj linearityDataId]];
    [self setThresholdDataId:[anotherObj thresholdDataId]];
    [self setCableCheckDataId:[anotherObj cableCheckDataId]];
    [self setStepPDSDataId:[anotherObj stepPDSDataId]];
}


- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"NcdDecoderForStepPDSTask",                @"decoder",
								 [NSNumber numberWithLong:stepPDSDataId],    @"dataId",
								 [NSNumber numberWithBool:NO],               @"variable",
								 [NSNumber numberWithLong:3],                @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"StepPDSTask"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"NcdDecoderForThresholdTask",              @"decoder",
				   [NSNumber numberWithLong:thresholdDataId],  @"dataId",
				   [NSNumber numberWithBool:NO],               @"variable",
				   [NSNumber numberWithLong:3],                @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"ThresholdTask"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"NcdDecoderForLinearityTask",              @"decoder",
				   [NSNumber numberWithLong:linearityDataId],  @"dataId",
				   [NSNumber numberWithBool:NO],               @"variable",
				   [NSNumber numberWithLong:3],                @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"LinearityTask"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"NcdDecoderForLogAmpTask",                 @"decoder",
				   [NSNumber numberWithLong:logAmpDataId],     @"dataId",
				   [NSNumber numberWithBool:NO],               @"variable",
				   [NSNumber numberWithLong:3],                @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"LogAmpTask"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"NcdDecoderForCableCheckTask",             @"decoder",
				   [NSNumber numberWithLong:cableCheckDataId], @"dataId",
				   [NSNumber numberWithBool:NO],               @"variable",
				   [NSNumber numberWithLong:3],                @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"CableCheckTask"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"NcdDecoderForPulseChannelsTask",               @"decoder",
				   [NSNumber numberWithLong:pulseChannelsDataId], @"dataId",
				   [NSNumber numberWithBool:NO],               @"variable",
				   [NSNumber numberWithLong:3],                @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"NcdPulseChannelsTask"];
    
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"NcdDecoderForPulserSettings",             @"decoder",
				   [NSNumber numberWithLong:pulserDataId],     @"dataId",
				   [NSNumber numberWithBool:NO],               @"variable",
				   [NSNumber numberWithLong:6],                @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"PulserSettings"];
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"NcdModel"];
    
}


#define kNcdPulserRecordSize 6
- (void) shipPulserRecord:(ORHPPulserModel*)thePulser 
{  
    NSArray* triggerCards = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORTrigger32Model")];
    if([triggerCards count]){
        @try {
            
            union packed {
                unsigned long longValue;
                float floatValue;
            }packed;
            
            unsigned long data[kNcdPulserRecordSize];
            data[0] = pulserDataId | (kNcdPulserRecordSize & 0x3ffff);
            data[1] = [[[triggerCards objectAtIndex:0]crate] requestGTID];
            data[2] = [thePulser selectedWaveform];
            
            packed.floatValue = [thePulser voltage];
            data[3] = packed.longValue;
            
            packed.floatValue = [thePulser burstRate];
            data[4] = packed.longValue;
            
            packed.floatValue = [thePulser totalWidth];
            data[5] = packed.longValue;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
                                                                object:[NSData dataWithBytes:data length:sizeof(long)*kNcdPulserRecordSize]];
            
        }
		@catch(NSException* localException) {
            NSLog(@"\n");
            NSLogColor([NSColor redColor],@"HW exception on the trigger card.\n");
            NSLogColor([NSColor redColor],@"So didn't ship the Pulser record because no GTID.\n");
        }
    }
}

- (void) shipTaskRecord:(id)aTask running:(BOOL)aState
{
    int taskId = -1;
    if(aTask == ncdLogAmpTask)taskId = logAmpDataId;
    else if(aTask == ncdLinearityTask)taskId = linearityDataId;
    else if(aTask == ncdThresholdTask)taskId = thresholdDataId;
    else if(aTask == ncdCableCheckTask)taskId = cableCheckDataId;
    else if(aTask == ncdPulseChannelsTask)taskId = pulseChannelsDataId;
    else if(aTask == ncdPDSStepTask){
        if( [ncdLogAmpTask taskState] != eTaskRunning    && 
		   [ncdLinearityTask taskState] != eTaskRunning &&
		   [ncdThresholdTask taskState] != eTaskRunning &&
		   [ncdCableCheckTask taskState] != eTaskRunning){
            taskId = stepPDSDataId;
        }
    }
    if(taskId!= -1){
        NSArray* triggerCards = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORTrigger32Model")];
        if([triggerCards count]){
            @try {
                
                unsigned long data[3];
                data[0] = taskId | 3; //size is two plus header 
                data[1] = [[[triggerCards objectAtIndex:0]crate] requestGTID];
                data[2] = aState;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
                                                                    object:[NSData dataWithBytes:data length:sizeof(long)*3]];
                
			}
			@catch(NSException* localException) {
                NSLog(@"\n");
                
                NSLogColor([NSColor redColor],@"HW exception on the trigger card.\n");
                NSLogColor([NSColor redColor],@"So didn't ship the Task start/stop record because no GTID.\n");
            }
        }
    }
}

#define CapturePListFile @"~/Library/Preferences/edu.washington.npl.orca.capture.plist"

- (NSMutableDictionary*) captureState
{
    NSMutableDictionary* stateDictionary = [NSMutableDictionary dictionary];
    [[self document] addParametersToDictionary: stateDictionary];
    
    [stateDictionary writeToFile:[CapturePListFile stringByExpandingTildeInPath] atomically:YES];
    
    [self setHardwareCheck:YES];
    [self setShaperCheck:YES];
    [self setMuxCheck:YES];
    [self setTriggerCheck:YES];
    [self setCaptureDate:[NSDate date]];
    return stateDictionary;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)aDictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    
    [[self detector] addParametersToDictionary:objDictionary];
    
    [aDictionary setObject:objDictionary forKey:@"NcdModel"];
    return aDictionary;
}


//a highly hardcoded config checker. Assumes things like only one crate, ect.
- (BOOL) preRunChecks
{
    NSMutableDictionary* newDictionary  = [[self document] addParametersToDictionary: [NSMutableDictionary dictionary]];
    NSDictionary* oldDictionary         = [NSDictionary dictionaryWithContentsOfFile:[CapturePListFile stringByExpandingTildeInPath]];
    
    [problemArray release];
    problemArray = [[NSMutableArray array]retain];
    // --crate presence must be same
    // --number of cards must match
    // --addresses and slots must match
    
    //init the checks to 'unknown'
    [self setHardwareCheck:2];
    [self setShaperCheck:2];
    [self setMuxCheck:2];
    [self setTriggerCheck:2];
    
    NSDictionary* newCrateDictionary = [newDictionary objectForKey:@"crate 0"];
    NSDictionary* oldCrateDictionary = [oldDictionary objectForKey:@"crate 0"];
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
    
    
    //first scan for the cards, i.e. shapers and trigger cards
    NSMutableDictionary* newAddressSet =[NSMutableDictionary dictionary];
    
    NSArray* newCardKeys = [newCrateDictionary allKeys];        
    NSArray* oldCardKeys = [oldCrateDictionary allKeys];
    NSEnumerator* eNew =  [newCardKeys objectEnumerator];
    id newCardKey;
    while( newCardKey = [eNew nextObject]){ 
        //loop over all cards, comparing old card records to new ones.
        NSDictionary* newCardRecord = [newCrateDictionary objectForKey:newCardKey];
        if(![[newCardRecord class] isSubclassOfClass:NSClassFromString(@"NSDictionary")])continue;
        NSEnumerator* eOld =  [oldCardKeys objectEnumerator];
        id oldCardKey;
        //grab some objects that we'll use more than once below
        NSNumber* newBaseAddress    = [newCardRecord objectForKey:@"baseAddress"];
        NSNumber* newSlot           = [newCardRecord objectForKey:@"slot"];
        NSString* newClassName      = [newCardRecord objectForKey:@"Class Name"];
        
        if(newBaseAddress){
            //put the address in a keyed dict.. if identical addresses are inserted, flag a duplicated address failure.
            if([newAddressSet objectForKey:[newBaseAddress stringValue]]){
                [self setHardwareCheck:NO];
                [problemArray addObject:[NSString stringWithFormat:@"**** Address <0x%lx> appears more than once: slot %@ and slot %@\n",[newBaseAddress longValue],newSlot,[newAddressSet objectForKey:[newBaseAddress stringValue]]]];
            }
            else [newAddressSet setObject:newSlot forKey:[newBaseAddress stringValue]];
        }
        
        while( oldCardKey = [eOld nextObject]){ 
            NSDictionary* oldCardRecord = [oldCrateDictionary objectForKey:oldCardKey];
            if(![[oldCardRecord class] isSubclassOfClass:NSClassFromString(@"NSDictionary")])continue;
            
            //grab some objects that we'll use more than once below
            NSNumber* oldBaseAddress    = [oldCardRecord objectForKey:@"baseAddress"];
            
            if(newBaseAddress && oldBaseAddress && [newBaseAddress isEqualToNumber:oldBaseAddress]){
                if([newClassName isEqualToString: @"ORShaperModel"]){
                    [self checkCardOld:oldCardRecord new:newCardRecord   check:@selector(setShaperCheckFailed) exclude:[NSSet setWithObjects:@"thresholdAdcs",nil]];
                }
                else if([newClassName isEqualToString: @"ORTrigger32Model"]){
                    [self checkCardOld:oldCardRecord new:newCardRecord   check:@selector(setTriggerCheckFailed) exclude:nil];                    
                }
                //found a card so we are done.
                break;
            }
        }
    }
    
    //check the muxes
    NSMutableDictionary* newBusSet =[NSMutableDictionary dictionary];
    NSArray* newMuxes = [newDictionary allKeysStartingWith:@"mux"];
    NSArray* oldMuxes = [oldDictionary allKeysStartingWith:@"mux"];
    if([newMuxes count] !=[oldMuxes count]){
        [self setMuxCheck:NO];
        [problemArray addObject:@"Mux count is different\n"];
    }
    eNew =  [newMuxes objectEnumerator];
    id newMuxKey;
    while( newMuxKey = [eNew nextObject]){
        NSDictionary* newMuxRecord = [newDictionary objectForKey:newMuxKey];
        //loop over all muxes, comparing old card records to new ones.
        if(![[newMuxRecord class] isSubclassOfClass:NSClassFromString(@"NSDictionary")])continue;
        //grab some objects that we'll use more than once below
        NSNumber* newBusNumber    = [newMuxRecord objectForKey:@"busNumber"];
        NSNumber* newBoxNumber    = [newMuxRecord objectForKey:@"muxID"];
        
        if(newBusNumber){
            //put the bus number in a keyed dict.. if identical buses are inserted, flag a duplicated address failure.
            if([newBusSet objectForKey:[newBusNumber stringValue]]){
                [self setMuxCheck:NO];
                [problemArray addObject:[NSString stringWithFormat:@"**** Mux Bus <0x%lx> appears more than once.\n",[newBusNumber longValue]]];
            }
            else [newBusSet setObject:newBoxNumber forKey:[newBusNumber stringValue]];
        }
        NSEnumerator* eOld =  [oldMuxes objectEnumerator];
        id oldMuxKey;
        while( oldMuxKey = [eOld nextObject]){ 
            NSDictionary* oldMuxRecord = [oldDictionary objectForKey:oldMuxKey];
            if(![[oldMuxRecord class] isSubclassOfClass:NSClassFromString(@"NSDictionary")])continue;
            
            //grab some objects that we'll use more than once below
            NSNumber* oldBusNumber    = [oldMuxRecord objectForKey:@"busNumber"];
            
            if(newBusNumber && oldBusNumber && [newBusNumber isEqualToNumber:oldBusNumber]){
                [self checkMuxOld:oldMuxRecord new:newMuxRecord  check:@selector(setMuxCheckFailed) exclude:[NSSet setWithObjects:@"thresholdsAdcs",nil]];
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
    
    if(shaperCheck == 2)[self setShaperCheck:YES];
    else if(shaperCheck == 0){
        NSLogColor([NSColor redColor],@"Failed Shaper Config Check\n");
        passed = NO;
    }
    
    if(triggerCheck == 2)[self setTriggerCheck:YES];
    else if(triggerCheck == 0) {
        NSLogColor([NSColor redColor],@"Failed Trigger Card Config Check\n");
        passed = NO;
    }
    
    if(muxCheck == 2)[self setMuxCheck:YES];
    else if(muxCheck == 0) {
        NSLogColor([NSColor redColor],@"Failed Mux Config Check\n");
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
    return passed;
}

- (void) printProblemSummary
{
    [self preRunChecks];
}
@end

@implementation NcdModel (private)

- (void) checkCardOld:(NSDictionary*)oldRecord new:(NSDictionary*)newRecord  check:(SEL)checkSelector exclude:(NSSet*)exclusionSet
{
    NSEnumerator* e = [oldRecord keyEnumerator];
    id aKey;
    while(aKey = [e nextObject]){
        if(![exclusionSet containsObject:aKey]){
            if(![[oldRecord objectForKey:aKey] isEqualTo:[newRecord objectForKey:aKey]]){
                [self performSelector:checkSelector];
                [problemArray addObject:[NSString stringWithFormat:@"%@ <0x%lx slot %@> %@ changed.\n",
										 [oldRecord objectForKey:@"Class Name"],
										 [[oldRecord objectForKey:@"baseAddress"]longValue],
										 [oldRecord objectForKey:@"slot"], aKey]];
                
                [problemArray addObject:[NSString stringWithFormat:@"%@: <%@/%@>\n",aKey,[oldRecord objectForKey:aKey],[newRecord objectForKey:aKey]]];
            }
        }
    }
}

- (void) checkMuxOld:(NSDictionary*)oldRecord new:(NSDictionary*)newRecord  check:(SEL)checkSelector exclude:(NSSet*)exclusionSet
{
    NSEnumerator* e = [oldRecord keyEnumerator];
    id aKey;
    while(aKey = [e nextObject]){
        if(![exclusionSet containsObject:aKey]){
            if(![[oldRecord objectForKey:aKey] isEqualTo:[newRecord objectForKey:aKey]]){
                [self performSelector:checkSelector];
                [problemArray addObject:[NSString stringWithFormat:@"%@ <0x%lx mux %@> %@ changed.\n",
										 [oldRecord objectForKey:@"Class Name"],
										 [[oldRecord objectForKey:@"busNumber"]longValue],
										 [oldRecord objectForKey:@"muxID"], aKey]];
                
                [problemArray addObject:[NSString stringWithFormat:@"%@: <%@/%@>\n",aKey,[oldRecord objectForKey:aKey],[newRecord objectForKey:aKey]]];
            }
        }
    }
}

- (void) checkBuilderConnection
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkBuilderConnection) object:nil];
	//check that the dispatcher is connected
    NSArray* dispatchers = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORDispatcherModel")];
    if([dispatchers count] == 1){
		//OK, only one dispatcher...see if it's connected.
		[noDispatcherAlarm clearAlarm];
		ORDispatcherModel* dispatcher = [dispatchers objectAtIndex:0];
		if([dispatcher clientCount]){
			[builderNotConnectedAlarm clearAlarm];
		}
		else { 
			//Not Connected
			if(!builderNotConnectedAlarm){
				builderNotConnectedAlarm = [[ORAlarm alloc] initWithName:@"No Builder Connected" severity:kDataFlowAlarm];
				[builderNotConnectedAlarm setSticky:YES];
			}
			[builderNotConnectedAlarm setAcknowledged:NO];
			[builderNotConnectedAlarm postAlarm];
			[builderNotConnectedAlarm setHelpStringFromFile:@"BuilderConnectHelp"];
		}
	}
	else {
		//either no dispatcher or multiple dispatchers..either way throw alarm
		if(!noDispatcherAlarm){
			noDispatcherAlarm = [[ORAlarm alloc] initWithName:@"No Dispatcher" severity:kDataFlowAlarm];
			[noDispatcherAlarm setSticky:YES];
		}
		[noDispatcherAlarm setAcknowledged:NO];
		[noDispatcherAlarm postAlarm];
		[noDispatcherAlarm setHelpStringFromFile:@"NoDispatcherHelp"];
		
		[builderNotConnectedAlarm clearAlarm]; //no reason to leave this alarm, so clear it.
	}
	[self performSelector:@selector(checkBuilderConnection) withObject:nil afterDelay:30];
}

@end

