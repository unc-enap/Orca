//
//  MajoranaModel.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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
#import "MajoranaModel.h"
#import "MajoranaController.h"
#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"
#import "ORMJDSegmentGroup.h"
#import "ORRemoteSocketModel.h"
#import "SynthesizeSingleton.h"
#import "ORMPodCrateModel.h"
#import "ORiSegHVCard.h"
#import "ORAlarm.h"
#import "ORTimeRate.h"
#import "ORMJDInterlocks.h"
#import "ORVME64CrateModel.h"
#import "ORMJDSource.h"
#import "ORDataProcessing.h"
#import "ORMJDPreAmpModel.h"
#import "ORRunningAverage.h"
#import "OROnCallListModel.h"
#import "ORRunModel.h"
#import "ORCouchDBModel.h"

NSString* MajoranaModelIgnorePanicOnBChanged            = @"MajoranaModelIgnorePanicOnBChanged";
NSString* MajoranaModelIgnorePanicOnAChanged            = @"MajoranaModelIgnorePanicOnAChanged";
NSString* MajoranaModelIgnoreBreakdownPanicOnAChanged   = @"MajoranaModelIgnoreBreakdownPanicOnAChanged";
NSString* MajoranaModelIgnoreBreakdownPanicOnBChanged   = @"MajoranaModelIgnoreBreakdownPanicOnBChanged";
NSString* MajoranaModelIgnoreBreakdownCheckOnAChanged   = @"MajoranaModelIgnoreBreakdownCheckOnAChanged";
NSString* MajoranaModelIgnoreBreakdownCheckOnBChanged   = @"MajoranaModelIgnoreBreakdownCheckOnBChanged";
NSString* ORMajoranaModelViewTypeChanged                = @"ORMajoranaModelViewTypeChanged";
NSString* ORMajoranaModelPollTimeChanged                = @"ORMajoranaModelPollTimeChanged";
NSString* ORMJDAuxTablesChanged                         = @"ORMJDAuxTablesChanged";
NSString* ORMajoranaModelLastConstraintCheckChanged     = @"ORMajoranaModelLastConstraintCheckChanged";
NSString* ORMajoranaModelUpdateSpikeDisplay             = @"ORMajoranaModelUpdateSpikeDisplay";
NSString* ORMajoranaModelMaxNonCalibrationRate          = @"ORMajoranaModelMaxNonCalibrationRate";
NSString* ORMajoranaModelVerboseDiagnosticsChanged      = @"ORMajoranaModelVerboseDiagnosticsChanged";
NSString* ORMajoranaModelMinNumDetsToAlertExperts       = @"ORMajoranaModelMinNumDetsToAlertExperts";
NSString* ORMajoranaModelCalibrationStatusChanged       = @"ORMajoranaModelCalibrationStatusChanged";

static NSString* MajoranaDbConnector		= @"MajoranaDbConnector";

#define MJDStringMapFile(aPath)		[NSString stringWithFormat:@"%@_StringMap",	aPath]
#define MJDSpecialMapFile(aPath)    [NSString stringWithFormat:@"%@_SpecialMap",aPath]

@interface  MajoranaModel (private)
- (void)     checkConstraints;
- (void)     validateStringMap;
- (void)     validateSpecialMap;
- (NSArray*) linesInFile:(NSString*)aPath;
@end

@implementation MajoranaModel

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
    int i;
    for(i=0;i<2;i++){
        [mjdInterlocks[i] setDelegate:nil];
        [mjdInterlocks[i] stop];
        [mjdInterlocks[i] release];
        
        [rateSpikes[i] release];
        [baselineExcursions[i] release];
        [rateSpikeTime[i] release];
       
        [rampHVAlarm[i]   clearAlarm];
        [rampHVAlarm[i]   release];
        
        [breakdownAlarm[i]   clearAlarm];
        [breakdownAlarm[i]   release];

        [mjdSource[i] setDelegate:nil];
        [mjdSource[i] release];
        
    }
        
    [highRateChecker release];
    [anObjForCouchID release];
    [stringMap release];
    [specialMap release];
    [calibrationStatus release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
    [self getRunType:nil];
    [super awakeAfterDocumentLoaded];
}

- (void) getRunType:(ORRunModel*)rc
{
    if(!rc){
        NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
        if([objs count]){
            runType = [[objs objectAtIndex:0] runType];
        }
        else runType = 0x0;
    }
    else {
        runType = [rc runType];
    }
}

- (void) wakeUp
{
    [super wakeUp];
	if(pollTime){
        [self checkConstraints];
	}
}

- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super sleep];
}

- (void) setUpImage {
    [self setImage:[NSImage imageNamed:@"Majorana"]];
}

- (void) makeMainController
{
    [self linkToController:@"MajoranaController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:MajoranaDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[aConnector setConnectorType: 'DB O' ];
	[aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

//- (NSString*) helpURL
//{
//	return @"Majorana/Index.html";
//}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(hvInfoRequest:)
                         name : ORiSegHVCardRequestHVMaxValues
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(customInfoRequest:)
                         name : ORiSegHVCardRequestCustomInfo
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateSpike:)
                         name : @"ORGretina4MModelRateSpiked" //string so we don't have to import the .h file
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateSpike:)
                         name : @"ORGretina4AModelRateSpiked" //string so we don't have to import the .h file
                       object : nil];
  
    [notifyCenter addObserver : self
                     selector : @selector(baselineSpike:)
                         name : ORMJDPreAmpModelRateSpiked
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runTypeChanged:)
                         name : ORRunTypeChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(awakeAfterDocumentLoaded)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(awakeAfterDocumentLoaded)
                         name : ORGroupObjectsRemoved
                       object : nil];


}
- (void) runStatusChanged:(NSNotification*)aNote
{
    [super runStatusChanged:aNote];
    int running     = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
    int runTypeMask = [[[aNote userInfo] objectForKey:ORRunTypeMask] intValue];
    if((running == eRunInProgress) && !(runTypeMask & 0x00010018)){
        if(!highRateChecker){
            highRateChecker = [[ORHighRateChecker alloc] init:@"Sustained High Rate" timeFrame:60*10];
        }
    }
    else if((running == eRunStopped) || (running == eRunStopping)){
        [highRateChecker release];
        highRateChecker = nil;
    }

}

- (void) runTypeChanged:(NSNotification*) aNote
{
    [self getRunType:[aNote object]];
}

- (void) runStarted:(NSNotification*) aNote
{
//    if(!anObjForCouchID) anObjForCouchID = [[ORMJDHeaderRecordID alloc] init];
//    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
//                          [anObjForCouchID fullID],                     @"name",
//                          @"MJDHeader",                                 @"title",
//                          [[aNote userInfo] objectForKey:kHeader],      kHeader,
//                          [[aNote userInfo] objectForKey:kRunNumber],   kRunNumber,
//                          [[aNote userInfo] objectForKey:kSubRunNumber],kSubRunNumber,
//                          [[aNote userInfo] objectForKey:kRunMode],     kRunMode,
//                          nil];
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:anObjForCouchID userInfo:info];
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddHistoryAdcRecord" object:anObjForCouchID userInfo:info];
    [self resetSpikeDictionaries];
}

- (void) collectRates
{
    [super collectRates];
    highRateChecker.maxValue = maxNonCalibrationRate;
    if(maxNonCalibrationRate!=0)[highRateChecker checkRate:[[self segmentGroup:0] rate]];
}

- (void) customInfoRequest:(NSNotification*)aNote
{
    if([[aNote object] isKindOfClass:NSClassFromString(@"ORiSegHVCard")]){
        ORiSegHVCard* anHVCard = [aNote object];
        id userInfo     = [aNote userInfo];
        int aCrate      = [[userInfo objectForKey:@"crate"]     intValue];
        int aCard       = [[userInfo objectForKey:@"card"]      intValue];
        int aChannel    = [[userInfo objectForKey:@"channel"]   intValue];
        BOOL foundIt    = NO;
        int aSet;
        for(aSet =0;aSet<2;aSet++){
            ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
            int numSegments = [self numberSegmentsInGroup:aSet];
            int i;
            for(i = 0; i<numSegments; i++){
                NSDictionary* params = [[segmentGroup segment:i]params];
                if(!params)break;
                if([[params objectForKey:@"kHVCrate"]intValue] != aCrate)continue;
                if([[params objectForKey:@"kHVCard"]intValue] != aCard)continue;
                if([[params objectForKey:@"kHVChan"]intValue] != aChannel)continue;
                id preAmpChan       = [params objectForKey:@"kPreAmpChan"];
                id preAmpDigitizer  = [params objectForKey:@"kPreAmpDigitizer"];
                //get here and it's a match
                if(preAmpChan && preAmpDigitizer){
                    [anHVCard setCustomInfo:aChannel string:[NSString stringWithFormat:@"PreAmp: %d,%d",[preAmpDigitizer intValue],[preAmpChan intValue]]];
                }
                foundIt = YES;
                break;
            }
        }
        if(!foundIt){
            [anHVCard setCustomInfo:aChannel string:@""];
        }
    }
}
- (BOOL) verboseDiagnostics
{
    return verboseDiagnostics;
}

- (void) setVerboseDiagnostics:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVerboseDiagnostics:verboseDiagnostics];
    verboseDiagnostics = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelVerboseDiagnosticsChanged" object:self];
}
- (NSString*) calibrationStatus {return calibrationStatus;}
- (void) setCalibrationStatus:(NSString*)aString;
{
    [calibrationStatus autorelease];
    calibrationStatus = [aString copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelCalibrationStatusChanged" object:self];
}
- (void) hvInfoRequest:(NSNotification*)aNote
{
    if([[aNote object] isKindOfClass:NSClassFromString(@"ORiSegHVCard")]){
        ORiSegHVCard* anHVCard = [aNote object];
        id userInfo     = [aNote userInfo];
        int aCrate      = [[userInfo objectForKey:@"crate"]     intValue];
        int aCard       = [[userInfo objectForKey:@"card"]      intValue];
        int aChannel    = [[userInfo objectForKey:@"channel"]   intValue];
        BOOL foundIt    = NO;
        int aSet;
        for(aSet =0;aSet<2;aSet++){
            ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
            int numSegments = [self numberSegmentsInGroup:aSet];
            int i;
            for(i = 0; i<numSegments; i++){
                NSDictionary* params = [[segmentGroup segment:i]params];
                if(!params)break;
                if([[params objectForKey:@"kHVCrate"]intValue] != aCrate)continue;
                if([[params objectForKey:@"kHVCard"]intValue] != aCard)continue;
                if([[params objectForKey:@"kHVChan"]intValue] != aChannel)continue;
                id maxVoltNum = [params objectForKey:@"kMaxVoltage"];
                //get here and it's a match
                if(maxVoltNum){
                    //only if there is an entry for max voltage do we set it
                    [anHVCard setMaxVoltage:aChannel withValue:[maxVoltNum intValue] ];
                    [anHVCard setChan:aChannel name:[params objectForKey:@"kDetectorName"]];
                }
                foundIt = YES;
                break;
            }
        }
        if(!foundIt){
            [anHVCard setChan:aChannel name:@""];
            [anHVCard setMaxVoltage:aChannel withValue:0 ];
        }
    }
}
#pragma mark ¥¥¥Breakdown Methods
- (void) rateSpike:(NSNotification*) aNote
{
    NSDictionary*       userInfo  = [aNote userInfo];
    ORRunningAveSpike*  spikeInfo = [userInfo objectForKey:@"spikeInfo"];
    BOOL spiked                   = [spikeInfo spiked];
    
    int aCrate       = [[userInfo objectForKey:@"crate"] intValue];
    int index        = aCrate - 1;                                  //crates = 1 and 2 -- convert to 0 and 1 for index
    int aCard        = [[userInfo objectForKey:@"card"]  intValue];
    int aChan        = [[userInfo objectForKey:@"channel"]  intValue];
    
    if(spiked){
        if(     index == 0 && ignoreBreakdownCheckOnB) return;
        else if(index == 1 && ignoreBreakdownCheckOnA) return;
        [self scheduleConstraintCheck];
    }
    
    ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:0];
    for(id item in stringMap){
        
        int i;
        for(i=1;i<=5;i++){
            NSString* detIndexString = [item objectForKey:[@"kDet" stringByAppendingFormat:@"%d",i]];
            
            if([detIndexString length]==0 || [detIndexString rangeOfString:@"-"].location!=NSNotFound)continue;
            
            int detIndex    = [detIndexString intValue]*2; //x2 because the stringMap hi/low gains get expanded into a bigger table
            int crate       = [[aGroup segment:detIndex objectForKey:@"kVME"]        intValue];
            int card        = [[aGroup segment:detIndex objectForKey:@"kCardSlot"]   intValue];
            int loGainChan  = [[aGroup segment:detIndex objectForKey:@"kChannel"]    intValue];
            int hiGainChan  = [[aGroup segment:detIndex+1 objectForKey:@"kChannel"]    intValue];

            if((crate == aCrate) && (card  == aCard) && ((aChan == loGainChan) || (aChan == hiGainChan))){
                NSString* aKey = [NSString stringWithFormat:@"%@D%d",[aGroup segment:detIndex objectForKey:@"kStringName"],i];
                if(spiked){
                    NSMutableDictionary* data = [NSMutableDictionary dictionaryWithDictionary:[[aGroup segment:detIndex] params]];
                    [data setObject:[NSDate date]                                       forKey:@"date"];
                    [data setObject:[NSNumber numberWithFloat:[spikeInfo ave]]          forKey:@"averageValue"];
                    [data setObject:[NSNumber numberWithFloat:[spikeInfo spikeValue]]   forKey:@"spikeValue"];
                    [data setObject:aKey                                                forKey:@"kStringName"];
                    if(!rateSpikes[index])rateSpikes[index] = [[NSMutableDictionary dictionary] retain];
                    [rateSpikes[index] setObject:data forKey:aKey];
                    [self setRateSpikeTime:index time:[NSDate date]];
                    
                    [self alertExperts:index];
                    
                    if(verboseDiagnostics){
                        NSLog(@"added rate spike for %@\n",aKey);
                    }
                }
                else {
                    if(verboseDiagnostics){
                        if([rateSpikes[index] objectForKey:aKey]){
                            NSLog(@"removed rate spike for %@\n",aKey);
                        }
                    }
                    [rateSpikes[index] removeObjectForKey:aKey];
                    if([rateSpikes[index] count] == 0){
                        rateReportSent[index] = NO;
                        [rateSpikes[index] release];
                        rateSpikes[index] = nil;
                        [self setRateSpikeTime:index time:nil];
                        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceConstraintCheck) object:nil];
                    }
                }
                break;
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelUpdateSpikeDisplay" object:self];
}

- (void) baselineSpike:(NSNotification*) aNote
{
    NSDictionary* userInfo        = [aNote userInfo];
    ORRunningAveSpike*  spikeInfo = [userInfo objectForKey:@"spikeInfo"];
    BOOL spiked                   = [spikeInfo spiked];
    
    int aCrate       = [[userInfo objectForKey:@"crate"]      intValue];
    int aCard        = [[userInfo objectForKey:@"card"]       intValue];
    int aPreAmpChan  = [[userInfo objectForKey:@"adcChannel"] intValue];
    int index      = aCrate - 1;                                 //crates = 1 and 2 -- convert to 0 and 1 for index
    
    if(spiked){
        if(     index == 0 && ignoreBreakdownCheckOnB) return;
        else if(index == 1 && ignoreBreakdownCheckOnA) return;
        [self scheduleConstraintCheck];
    }

    ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:0];
    for(id item in stringMap){
        int i;
        for(i=1;i<=5;i++){
            NSString* detIndexString = [item objectForKey:[@"kDet" stringByAppendingFormat:@"%d",i]];
            
            if([detIndexString length]==0 || [detIndexString rangeOfString:@"-"].location!=NSNotFound)continue;
            
            int detIndex    = [detIndexString intValue]*2; //x2 because the stringMap hi/low gains get expanded into a bigger table
            int crate       = [[aGroup segment:detIndex objectForKey:@"kVME"]        intValue];
            int card        = [[aGroup segment:detIndex objectForKey:@"kCardSlot"]   intValue];
            int preAmpChan  = [[aGroup segment:detIndex objectForKey:@"kPreAmpChan"] intValue];
            
            if((crate == aCrate) && (card  == aCard) && (preAmpChan == aPreAmpChan)){
                NSString* aKey = [NSString stringWithFormat:@"%@D%d",[aGroup segment:detIndex objectForKey:@"kStringName"],i];
                if(spiked){
                    NSMutableDictionary* data = [NSMutableDictionary dictionaryWithDictionary:[[aGroup segment:detIndex] params]];
                    [data setObject:[NSDate date]                                       forKey:@"date"];
                    [data setObject:[NSNumber numberWithFloat:[spikeInfo ave]]          forKey:@"averageValue"];
                    [data setObject:[NSNumber numberWithFloat:[spikeInfo spikeValue]]   forKey:@"spikeValue"];
                    [data setObject:aKey                                                 forKey:@"kStringName"];
                    
                   if(!baselineExcursions[index])baselineExcursions[index] = [[NSMutableDictionary dictionary] retain];
                    
                    NSString* deleteKey = [NSString stringWithFormat:@"%d,%@",index,aKey];
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedRemoveBaselineExcursion:) object:deleteKey];
                    
                    [baselineExcursions[index] setObject:data forKey:aKey];
                    
                    [self alertExperts:index];
                    
                    if(verboseDiagnostics){
                        NSLog(@"added baseline excursion for %@\n",aKey);
                    }
                }
                else {
                    NSString* deleteKey = [NSString stringWithFormat:@"%d,%@",index,aKey];
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedRemoveBaselineExcursion:) object:deleteKey];
                    [self performSelector:@selector(delayedRemoveBaselineExcursion:) withObject:deleteKey afterDelay:45];
                }
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelUpdateSpikeDisplay" object:self];
}

- (void) delayedRemoveBaselineExcursion:(NSString*)aBigKey
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedRemoveBaselineExcursion:) object:aBigKey];
    int firstComma = [aBigKey rangeOfString:@","].location;
    int index      = [[aBigKey substringToIndex:firstComma] intValue];
    NSString* aKey = [aBigKey substringFromIndex:firstComma+1];
    
    if(verboseDiagnostics){
        if([baselineExcursions[index] objectForKey:aKey]){
            NSLog(@"removed baseline excursion %@\n",aKey);
        }
    }
    [baselineExcursions[index] removeObjectForKey:aKey];

    if([baselineExcursions[index] count] == 0){
        [baselineExcursions[index] release];
        baselineExcursions[index] = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelUpdateSpikeDisplay" object:self];
}

- (int) countCommonSpikes:(int)index
{
    int count = 0;
    NSArray* allKeys = rateSpikes[index].allKeys;
    for(NSString* aKey in allKeys){
        if([baselineExcursions[index] objectForKey:aKey]!=nil){
            count++;
        }
    }

    return count;
}

- (void) resetSpikeDictionaries
{
    int i;
    for(i=0;i<2;i++){
        [rateSpikes[i]         removeAllObjects];
        [baselineExcursions[i] removeAllObjects];
        
        [rateSpikes[i]         release];
        [baselineExcursions[i] release];

        rateSpikes[i]           = nil;
        baselineExcursions[i]   = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelUpdateSpikeDisplay" object:self];
}

- (int)  minNumDetsToAlertExperts {return minNumDetsToAlertExperts;}
- (void)  setMinNumDetsToAlertExperts:(int)aValue
{
    if(aValue<1)aValue=1;
    [[[self undoManager] prepareWithInvocationTarget:self] setMinNumDetsToAlertExperts:minNumDetsToAlertExperts];
    minNumDetsToAlertExperts = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelMinNumDetsToAlertExperts" object:self];
}

- (void) alertExperts:(int)index;
{
    //if([self calibrationRun:index])return; //do we need to skip this if calibrating??

    int count = [self countCommonSpikes:index];
    if(count >= minNumDetsToAlertExperts){
        OROnCallListModel* onCallObj = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"OROnCallListModel,1"];
        NSString* exclaim = @"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
        NSString* s = [NSString stringWithFormat:@"Simultaneous Rate Spikes and Baseline Excursions on %d detector%@ triggered this alert\n",count,count>1?@"s":@""];
        NSString* report = [NSString stringWithFormat:@"%@%@%@\n%@\n",exclaim,s,exclaim,[self fullBreakDownReport:index]];
        [onCallObj broadcastMessage:report];
    }
}

- (void) scheduleConstraintCheck
{
    if(pollTime){
        if(!scheduledToRunCheckBreakdown){
            scheduledToRunCheckBreakdown = YES;
            [self performSelector:@selector(forceConstraintCheck) withObject:nil afterDelay:10];
        }
    }
}

- (void) forceConstraintCheck
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceConstraintCheck) object:nil];
    scheduledToRunCheckBreakdown = NO;
    [self checkConstraints];
}

- (void) setRateSpikeTime:(unsigned short) index time:(NSDate*)aDate
{
    if(index<2){
        //time of the last rate spike
        [aDate retain];
        [rateSpikeTime[index] release];
        rateSpikeTime[index] = aDate;
    }
}

- (NSTimeInterval) timeSinceRateSpike:(unsigned short)index
{
    if(index<2){
        return [[NSDate date] timeIntervalSinceDate:rateSpikeTime[index]];
    }
    else return 0;
}

- (BOOL) calibrationRun:(unsigned short)index
{
    if(index == 0) return runType &= (0x1<<3); //module 1
    else           return runType &= (0x1<<4); //moduel 2
}

- (BOOL) fillingLN:(unsigned short)index
{
    if(index<2)return[[self mjdInterlocks:index] fillingLN];
    else return NO;
}

- (NSTimeInterval) pollingTimeForLN:(unsigned short)index
{
    if(index<2)return 1.5*(NSTimeInterval)[[self mjdInterlocks:index] pollingTimeForLN];
    else return 0;
}

- (BOOL) rateSpikesValid:(unsigned short)index
{
    if(index<2){
        if([self calibrationRun:index])           return NO;
        else if([rateSpikes[index] count] == 0)   return NO;
        else {
            NSTimeInterval dt           = [self timeSinceRateSpike:index];
            NSTimeInterval lnPolltime   = [self pollingTimeForLN:index];
            if(verboseDiagnostics){
                if(dt < lnPolltime){
                    NSLog(@"Rate is spiking but less than %d (pollTime: %d) seconds have passed\n",(int)dt,(int)lnPolltime);
                }
                else {
                    if(![self fillingLN:index]){
                        NSLog(@"Spikes exist and NOT filling\n");
                    }
                    else {
                        NSLog(@"Spikes ignored because LN fill in progress\n");
                    }
                }
            }
            return (dt > lnPolltime) && ![self fillingLN:index];
        }
    }
    else return NO;
}

- (BOOL) baselineExcursionValid:(unsigned short) index
{
    if(index<2){
        return [baselineExcursions[index] count] != 0;
    }
    else return NO;
}


- (NSDictionary*) rateSpikes:(unsigned short)index
{
    if(index<2)return rateSpikes[index];
    else return nil;
}

- (NSDictionary*) baselineExcursions:(unsigned short)index
{
    if(index<2)return baselineExcursions[index];
    else return nil;
}

- (NSString*) checkForBreakdown:(unsigned short)module vacSystem:(unsigned short)aVacSystem
{
    int index = module - 1;

    //M1 = Crate1 = index0 // vacSystemB ==vacIndex1
    //M2 = Crate2 = index1 // vacSystemA ==vacIndex0
    if(index      > 1) return @"Index??";
    if(aVacSystem > 1) return @"Index??";
    
    //first send out reports as needed
    if([self rateSpikesValid:index] && !rateReportSent[index]){
        //send out text to experts
        OROnCallListModel* onCallObj = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"OROnCallListModel,1"];
        NSString* report = [NSString stringWithFormat:@"%@\n",[self fullBreakDownReport:index]];
        [onCallObj broadcastMessage:report];
        rateReportSent[index] = YES;
    }
    
    //look for signs of breakdown
    if([self breakdownConditionsMet:index]){
        
        if(![self breakdownAlarmPosted:index]){
            breakdownAlarm[index] = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Breakdown M%d Vac%c",module,'A'+aVacSystem] severity:(kEmergencyAlarm)];
            
            [breakdownAlarm[index] setSticky:NO];
            [breakdownAlarm[index] setHelpString:[NSString stringWithFormat:@"Suggest ramping down HV of Module %d because Vac %c spiked and event rate spiked and baseline jumped.\nAcknowledging this alarm will prevent an automatic ramp down 20 minutes after if was posted.",module, 'A'+aVacSystem]];
            [breakdownAlarm[index] postAlarm];
            BOOL vacSpike  = [[self mjdInterlocks:index] vacuumSpike];
            if(vacSpike){
                NSLogColor([NSColor redColor], @"HV should be ramped down on Module %d because Vac %c spiked and event rate spiked and baseline jumped.\n",module,
                           'A'+aVacSystem);
            }
            else {
                NSLogColor([NSColor redColor],@"Event rate spiked and baseline jumped on Module %d.\n",module);
                NSLogColor([NSColor redColor],@"However there is NO vacuum spike on Vac %c\n",'A'+aVacSystem);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelUpdateSpikeDisplay" object:self];
            
            NSString* report = [NSString stringWithFormat:@"%@\n",[self fullBreakDownReport:index]];

            OROnCallListModel* onCallObj = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"OROnCallListModel,1"];
            NSString* textMessage = [NSString stringWithFormat:@"The following problems will cause the HV to be ramped down 80%% in a few minutes on some channels\nAn Alarm has been posted. Acknowledge it to prevent the ramp down.\n\n%@",report];
            [onCallObj broadcastMessage:textMessage];
        }
        [self rampDownChannelsWithBreakdown:index vac:aVacSystem];
    }
    else {
        if([self breakdownAlarmPosted:index]){
            [self clearBreakdownAlarm:index];
        }
    }
    
    if(breakdownAlarm[index])                                                    return @"Breakdown";
    else if([self rateSpikesValid:index] || [self baselineExcursionValid:index]) return @"Concerns";
    else                                                                         return @"No Issues";

}
- (void) printBreakDownReport
{
    int i;
    for(i=0;i<2;i++){
        NSString* s1 = [self rateSpikeReport:i];
        NSLog(@"%@\n",[s1 length]?s1:[NSString stringWithFormat:@"No spikes on Module %d",i+1]);
        NSString* s2 = [self baselineExcursionReport:i];
        NSLog(@"%@\n",[s2 length]?s2:[NSString stringWithFormat:@"No baseline excursions on Module %d",i+1]);
    }
}

- (NSString*) fullBreakDownReport:(unsigned short)index
{
    if(index>1)return [NSString stringWithFormat:@"Bad index in %@ : %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd)];
    NSMutableString* report = [NSMutableString stringWithFormat:@"%@\n%@\n",[self rateSpikeReport:index],[self baselineExcursionReport:index]];
    
    [report appendString:@"--------------------------\n"];
    
    if([self fillingLN:index])[report appendString:@"*** LN Fill in Progress\n"];
    else                      [report appendString:@"*** NO LN Fill in Progress\n"];

    if([self vacuumSpike:index])[report appendString:@"*** Vac Spike\n"];
    else                        [report appendString:@"*** Vac appears OK\n"];

    return report;
}

- (NSString*) rateSpikeReport:(unsigned short)index
{
    if(index>1)return [NSString stringWithFormat:@"Bad index in %@ : %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd)];
    if([rateSpikes[index] count]){
        NSMutableString* report = [NSMutableString stringWithFormat:@"---Rate Spikes (Module %d)---\n",index+1];
        for(NSString* aKey in rateSpikes[index]){
            NSDictionary* d = [rateSpikes[index] objectForKey:aKey];
            [report appendFormat:@"--> %@ %@ %@ Ave:%.1f Spike:%.1f\n",
             [[d objectForKey:@"date"]stdDescription],
             [d objectForKey:@"kStringName"],
             [d objectForKey:@"kDetectorName"],
             [[d objectForKey:@"averageValue"] floatValue],
             [[d objectForKey:@"spikeValue"] floatValue]
             ];
        }
        [report appendString:@"\n"];
        return report;
    }
    else return @"";
}

- (NSString*) baselineExcursionReport:(unsigned short)index
{
    if(index>1)return [NSString stringWithFormat:@"Bad index in %@ : %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd)];
    if([baselineExcursions[index] count]){
        NSMutableString* report = [NSMutableString stringWithFormat:@"---Baseline Excursions (Module %d)---\n",index+1];
        for(NSString* aKey in baselineExcursions[index]){
            NSDictionary* d = [baselineExcursions[index] objectForKey:aKey];
            [report appendFormat:@"--> %@ %@ %@ Ave:%.1f Spike:%.1f\n",
             [[d objectForKey:@"date"]stdDescription],
             [d objectForKey:@"kStringName"],
             [d objectForKey:@"kDetectorName"],
             [[d objectForKey:@"averageValue"] floatValue],
             [[d objectForKey:@"spikeValue"] floatValue]
             ];
        }
        return report;
    }
    else return @"";
}


- (BOOL) breakdownAlarmPosted:(unsigned short)index
{
    if(index<2)return [breakdownAlarm[index] isPosted];
    else return NO;
}

- (void) clearBreakdownAlarm:(unsigned short)index
{
    if(index<2){
        [breakdownAlarm[index] clearAlarm];
        [breakdownAlarm[index] release];
        breakdownAlarm[index] = nil;
    }
}

- (BOOL) vacuumSpike:(unsigned short)index
{
    if(index<2) return[[self mjdInterlocks:index] vacuumSpike];
    else        return NO;
}

- (BOOL) matchingRateAndBaselineIssues:(unsigned short)index
{
    if([self rateSpikesValid:index] && [self baselineExcursionValid:index]){
        for(NSString* aKey in rateSpikes[index]){
            if([baselineExcursions[index] objectForKey:aKey])return YES;
        }
    }
    return NO;
}

- (BOOL) breakdownConditionsMet:(unsigned short)index
{
    if(index>1) return NO;
       
    BOOL ratesAndBaselinesBad   = [self matchingRateAndBaselineIssues:index];
    BOOL areBaselineExcursions  = [self baselineExcursionValid:index];
    BOOL fillingLN              = [[self mjdInterlocks:index] fillingLN];
    BOOL vacSpike               = [[self mjdInterlocks:index] vacuumSpike];
    
    if([self calibrationRun:index]){
        return (areBaselineExcursions && !fillingLN && vacSpike);
    }
    else return (ratesAndBaselinesBad && !fillingLN && vacSpike);
}

- (void) rampDownChannelsWithBreakdown:(int)index vac:(int)aVacSystem
{
    //double check
    if(![self breakdownAlarmPosted:index])return;
    
    //OK, we know something has breakdown or there wouldn't be an alarm. Figure out which one(s) to ramp down 80%

    if(aVacSystem==0 && ignorePanicOnA)return;
    if(aVacSystem==1 && ignorePanicOnB)return;
    
    if((index == 1) && ignoreBreakdownCheckOnA)return;
    if((index == 0) && ignoreBreakdownCheckOnB)return;

    if((index == 1) && ignoreBreakdownPanicOnA)return;
    if((index == 0) && ignoreBreakdownPanicOnB)return;
    
    if(![breakdownAlarm[index] acknowledged] && [breakdownAlarm[index] timeSincePosted] >= 20*60){
        for(NSString* aKey in rateSpikes[index]){
            NSDictionary* anEntry = [rateSpikes[index] objectForKey:aKey];
            
            int hvCrate             = [[anEntry objectForKey:@"kHVCrate"]    intValue];
            int hvCard              = [[anEntry objectForKey:@"kHVCard"]     intValue];
            int hvChannel           = [[anEntry objectForKey:@"kHVChannel"]  intValue];
            NSString* stringName    = [anEntry  objectForKey:@"kStringName"];
            NSString* detectorName  = [anEntry  objectForKey:@"kDetectorName"];
                
            NSLogColor([NSColor redColor],@"Breakdown detected on string %@ Detector %@\n",stringName,detectorName);
            
            ORMPodCrateModel* hvCrateObj = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:[NSString stringWithFormat:@"ORMPodCrateModel,%d",hvCrate]];
            
            ORiSegHVCard* theHVCard = [hvCrateObj cardInSlot:hvCard];
            float target = [theHVCard target:hvChannel];
            float newTarget = .80*target;
            [theHVCard setTarget:hvChannel withValue:newTarget];
            [theHVCard commitTargetToHwGoal:hvChannel];
            [theHVCard loadValues:hvChannel];
            NSLogColor([NSColor redColor],@"Ramping %@,%d from %.2f to %.2f\n",[theHVCard fullID],hvChannel,target,newTarget);
        }
    }
}

- (BOOL) validateSegmentParam:(NSString*)aParam
{
    if([aParam length]==0 || [aParam rangeOfString:@"-"].location!=NSNotFound)return NO;
    else return YES;
}


- (float) maxNonCalibrationRate
{
    return maxNonCalibrationRate;
}

- (void) setMaxNonCalibrationRate:(float)aValue
{
    if(aValue>3000)aValue=3000;
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxNonCalibrationRate:maxNonCalibrationRate];
    maxNonCalibrationRate = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelMaxNonCalibrationRate" object:self];
}

#pragma mark ***Accessors
- (NSDate*) lastConstraintCheck
{
    return lastConstraintCheck;
}

- (void) setLastConstraintCheck:(NSDate*)aDate
{
    [aDate retain];
    [lastConstraintCheck release];
    lastConstraintCheck = aDate;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMajoranaModelLastConstraintCheckChanged object:self];
}

- (BOOL) ignorePanicOnB
{
    return ignorePanicOnB;
}

- (void) setIgnorePanicOnB:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnorePanicOnB:ignorePanicOnB];
    
    if(ignorePanicOnB != aState){
        ignorePanicOnB = aState;
        if(ignorePanicOnB){
            NSLogColor([NSColor redColor],@"WARNING: HV checks will ignore HV Ramp Action on Module 1\n");
        }
        else {
            NSLog(@"HV checks will NOT ignore HV ramp action on Module 1\n");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnorePanicOnBChanged object:self];
}

- (BOOL) ignorePanicOnA
{
    return ignorePanicOnA;
}

- (void) setIgnorePanicOnA:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnorePanicOnA:ignorePanicOnA];
    
    if(ignorePanicOnA != aState){
        ignorePanicOnA = aState;
        if(ignorePanicOnA){
            NSLogColor([NSColor redColor],@"WARNING: HV checks will ignore HV Ramp Action on Module 2\n");
        }
        else {
            NSLog(@"HV checks will NOT ignore HV ramp action on Module 2\n");
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnorePanicOnAChanged object:self];
}

- (BOOL) ignoreBreakdownCheckOnB
{
    return ignoreBreakdownCheckOnB;
}

- (void) setIgnoreBreakdownCheckOnB:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnoreBreakdownCheckOnB:ignoreBreakdownCheckOnB];
    
    if(ignoreBreakdownCheckOnB!= aState){
        ignoreBreakdownCheckOnB = aState;
        if(ignoreBreakdownCheckOnB){
            NSLogColor([NSColor redColor],@"WARNING: Breakdown check will be SKIPPED on Module 1\n");
            [self clearBreakdownAlarm:0];
        }
        else {
            NSLog(@"Breakdown checks on Module 1\n");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnoreBreakdownCheckOnBChanged object:self];
}

- (BOOL) ignoreBreakdownCheckOnA
{
    return ignoreBreakdownCheckOnA;
}

- (void) setIgnoreBreakdownCheckOnA:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnoreBreakdownCheckOnA:ignoreBreakdownCheckOnA];
    
    if(ignoreBreakdownCheckOnA!= aState){
        ignoreBreakdownCheckOnA = aState;
        if(ignoreBreakdownCheckOnA){
            NSLogColor([NSColor redColor],@"WARNING: Breakdown check will be SKIPPED on Module 2\n");
            [self clearBreakdownAlarm:1];
         }
        else {
            NSLog(@"Breakdown checks on Module 2\n");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnoreBreakdownCheckOnAChanged object:self];
}

- (BOOL) ignoreBreakdownPanicOnB
{
    return ignoreBreakdownPanicOnB;
}

- (void) setIgnoreBreakdownPanicOnB:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnoreBreakdownPanicOnB:ignoreBreakdownPanicOnB];
    
    if(ignoreBreakdownPanicOnB!= aState){
        ignoreBreakdownPanicOnB = aState;
        if(ignoreBreakdownPanicOnB){
            NSLogColor([NSColor redColor],@"WARNING: Breakdowns on Module 1 will be checked, but HV will NOT ramp down\n");
            [self clearBreakdownAlarm:0];
        }
        else {
            NSLog(@"Breakdown panic enabled on Module 1\n");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnoreBreakdownPanicOnBChanged object:self];
}

- (BOOL) ignoreBreakdownPanicOnA
{
    return ignoreBreakdownPanicOnA;
}

- (void) setIgnoreBreakdownPanicOnA:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnoreBreakdownPanicOnA:ignoreBreakdownPanicOnA];
    
    if(ignoreBreakdownPanicOnA!= aState){
        ignoreBreakdownPanicOnA = aState;
        if(ignoreBreakdownPanicOnA){
            NSLogColor([NSColor redColor],@"WARNING: Breakdowns on Module 2 will be checked, but HV will NOT ramp down\n");
            [self clearBreakdownAlarm:1];
        }
        else {
            NSLog(@"Breakdown panic enabled on Module 2\n");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnoreBreakdownPanicOnAChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMajoranaModelPollTimeChanged object:self];
	
	if(pollTime){
		[self performSelector:@selector(checkConstraints) withObject:nil afterDelay:.2];
	}
	else {
        int i;
        for(i=0;i<2;i++){
            [mjdInterlocks[i] reset:NO];
        }
        NSLog(@"HV interlocks have been turned OFF\n");
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkConstraints) object:nil];
	}
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)aDictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
	
	[[segmentGroups objectAtIndex:0] addParametersToDictionary:objDictionary useName:@"DetectorGeometry" addInGroupName:NO];
	[[segmentGroups objectAtIndex:1] addParametersToDictionary:objDictionary useName:@"VetoGeometry" addInGroupName:NO];
    
    NSString* stringMapContents = [self stringMapFileAsString];
    if([stringMapContents length]){
        stringMapContents = [stringMapContents stringByAppendingString:@"\n"];
        [objDictionary setObject:stringMapContents forKey:@"StringGeometry"];
    }
    NSString* specialMapContents = [self specialMapFileAsString];
    if([specialMapContents length]){
        specialMapContents = [specialMapContents stringByAppendingString:@"\n"];
        [objDictionary setObject:specialMapContents forKey:@"SpecialStrings"];
    }

    [aDictionary setObject:objDictionary forKey:[self className]];

    return aDictionary;
}


- (NSMutableArray*) setupMapEntries:(int) groupIndex
{
    [self setCrateIndex:1];
    [self setCardIndex:2];
    [self setChannelIndex:3];
    
    NSMutableArray* mapEntries = [NSMutableArray array];
    if(groupIndex == 0){
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",     @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kVME",               @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",          @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",           @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreAmpChan",        @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCrate",           @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCard",            @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVChan",            @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kMaxVoltage",        @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kDetectorName",      @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kDetectorType",      @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreAmpDigitizer",   @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
     }
    else if(groupIndex == 1){
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber", @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kVME",			@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",      @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",       @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCrate",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCard",        @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVChan",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
    }
	return mapEntries;
}

- (void) postCouchDBRecord
{    
    NSMutableDictionary*  values  = [NSMutableDictionary dictionary];
    int aSet;
    int numGroups = [segmentGroups count];
    for(aSet=0;aSet<numGroups;aSet++){
        NSMutableDictionary* aDictionary= [NSMutableDictionary dictionary];
        NSMutableArray* thresholdArray  = [NSMutableArray array];
        NSMutableArray* totalCountArray = [NSMutableArray array];
        NSMutableArray* rateArray       = [NSMutableArray array];
        NSMutableArray* onlineArray     = [NSMutableArray array];
        
        ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
        int numSegments = [self numberSegmentsInGroup:aSet];
        int i;
        for(i = 0; i<numSegments; i++){
            [thresholdArray     addObject:[NSNumber numberWithFloat:[segmentGroup getThreshold:i]]];
            [totalCountArray    addObject:[NSNumber numberWithFloat:[segmentGroup getTotalCounts:i]]];
            [rateArray          addObject:[NSNumber numberWithFloat:[segmentGroup getRate:i]]];
            [onlineArray        addObject:[NSNumber numberWithFloat:[segmentGroup online:i]]];
        }
        
        NSArray* mapEntries = [[segmentGroup paramsAsString] componentsSeparatedByString:@"\n"];
        
        if([thresholdArray count])  [aDictionary setObject:thresholdArray   forKey: @"thresholds"];
        if([totalCountArray count]) [aDictionary setObject:totalCountArray  forKey: @"totalcounts"];
        if([rateArray count])       [aDictionary setObject:rateArray        forKey: @"rates"];
        if([onlineArray count])     [aDictionary setObject:onlineArray      forKey: @"online"];
        if([mapEntries count])      [aDictionary setObject:mapEntries       forKey: @"geometry"];
        
        NSArray* totalRateArray = [[[self segmentGroup:aSet] totalRate] ratesAsArray];
        if(totalRateArray)[aDictionary setObject:totalRateArray forKey:@"totalRate"];

        [values setObject:aDictionary forKey:[segmentGroup groupName]];
    }
    
    NSMutableDictionary* aDictionary= [NSMutableDictionary dictionary];
    NSArray* stringMapEntries = [[self stringMapFileAsString] componentsSeparatedByString:@"\n"];
    [aDictionary setObject:stringMapEntries forKey: @"geometry"];
    [values setObject:aDictionary           forKey:@"Strings"];
  
    aDictionary= [NSMutableDictionary dictionary];
    NSArray* specialMapEntries = [[self specialMapFileAsString] componentsSeparatedByString:@"\n"];
    [aDictionary setObject:specialMapEntries forKey: @"list"];
    [values setObject:aDictionary           forKey:@"SpecialChannels"];

    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
    ORMJDSegmentGroup* group = [[ORMJDSegmentGroup alloc] initWithName:@"Detectors" numSegments:kNumDetectors mapEntries:[self setupMapEntries:0]];
	[self addGroup:group];
	[group release];
    
    ORSegmentGroup* group2 = [[ORSegmentGroup alloc] initWithName:@"Veto" numSegments:kNumVetoSegments mapEntries:[self setupMapEntries:1]];
	[self addGroup:group2];
	[group2 release];
}

- (int)  maxNumSegments
{
	return kNumDetectors;
}

- (int) numberSegmentsInGroup:(int)aGroup
{
	if(aGroup == 0) return kNumDetectors;
	else			return kNumVetoSegments;
}
- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		NSString* crateName  = [aGroup segment:index objectForKey:@"kVME"];
		NSString* cardName = [aGroup segment:index objectForKey:@"kCardSlot"];
		NSString* chanName = [aGroup segment:index objectForKey:@"kChannel"];
        
        
        
		if(cardName && chanName && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
                    
                    NSString* cardObjectName = [self objectNameForCrate:crateName andCard:cardName];
                    //have to get the class name of the card in question. First look for the crate
 
                    
                    if(cardObjectName){
                    
                        id histoObj = [arrayOfHistos objectAtIndex:0];
                        aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:cardObjectName, @"Energy",
															[NSString stringWithFormat:@"Crate %2d",[crateName intValue]],
															[NSString stringWithFormat:@"Card %2d",[cardName intValue]],
															[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
															nil]];
					
                        [aDataSet doDoubleClick:nil];
                    }
				}
			}
		}
	}
}

- (NSString*) objectNameForCrate:(NSString*)aCrateName andCard:(NSString*)aCardName
{
    NSArray* crates = [[self document] collectObjectsOfClass:NSClassFromString(@"ORVme64CrateModel")];
    for(ORVme64CrateModel* aCrate in crates){
        if([aCrate crateNumber] == [aCrateName intValue]){
            //OK, got the crate. Get the card
            NSArray* cards = [aCrate orcaObjects];
            for(id aCard in cards){
                if([aCard slot] == [aCardName intValue]){
                    NSString* cardObjectName  = [[aCard className] stringByReplacingOccurrencesOfString:@"OR" withString:@""];
                    return [cardObjectName stringByReplacingOccurrencesOfString:@"Model" withString:@""];
                }
            }
        }
    }
    return nil;
}

- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index
{
	ORSegmentGroup* theGroup = [segmentGroups objectAtIndex:aGroup];
	
	NSString* crateName = [theGroup segment:index objectForKey:@"kCrate"];
	NSString* cardName  = [theGroup segment:index objectForKey:@"kCardSlot"];
	NSString* chanName  = [theGroup segment:index objectForKey:@"kChannel"];
	
	return [NSString stringWithFormat:@"Gretina4M,Energy,Crate %2d,Card %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}

- (id) mjdInterlocks:(int)index
{
    if(!mjdInterlocks[index]){
        mjdInterlocks[index] = [[ORMJDInterlocks alloc] initWithDelegate:self slot:index];
    }
    return mjdInterlocks[index];
}

- (id) mjdSource:(int)index
{
    if(index>=0 && index<2){
        if(!mjdSource[index]){
            mjdSource[index] = [[ORMJDSource alloc] initWithDelegate:self slot:index];
        }
        return mjdSource[index];
    }
    else return nil;
}

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock     { return @"MajoranaMapLock";      }
- (NSString*) vetoMapLock           { return @"MajoranaVetoMapLock";  }
- (NSString*) experimentDetectorLock{ return @"MajoranaDetectorLock"; }
- (NSString*) experimentDetailsLock	{ return @"MajoranaDetailsLock";  }
- (NSString*) calibrationLock       { return @"MajoranaCalibrationLock";  }

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMajoranaModelViewTypeChanged object:self userInfo:nil];
}

- (int) viewType { return viewType; }

- (ORRemoteSocketModel*) remoteSocket:(int)anIndex
{
    for(id obj in [self orcaObjects]){
        if([obj tag] == anIndex)return obj;
    }
    return nil;
}

- (BOOL) anyHvOnVMECrate:(int)aVmeCrate
{
    //tricky .. we have to location the HV crates based on the hv map using the VME crate (detector group 0).
    //But we don't care about the Veto system (group 1).
    ORMPodCrateModel* hvCrateObj[2] = {nil,nil}; //will check for up to two HV crates (should just be one)
    hvCrateObj[0] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,0"];
    hvCrateObj[1] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,1"];

    ORSegmentGroup* group = [self segmentGroup:0]; //detector group
    int n = [group numSegments]; //both DAQ and Veto on the same HV supply for now
    int i;
    for(i=0;i<n;i++){
        ORDetectorSegment* seg =  [group segment:i];                    //get a segment from the group
		int vmeCrate = [[seg objectForKey:@"kVME"] intValue];           //pull out the crate
        if(vmeCrate == aVmeCrate){
            int hvCrate = [[seg objectForKey:@"kHVCrate"]intValue];    //pull out the crate
            int hvCard  = [[seg objectForKey:@"kHVCard"]intValue];    //pull out the card
            if(hvCrate<2){
                ORiSegHVCard* card = [hvCrateObj[hvCrate] cardInSlot:hvCard];
                if([card hvOnAnyChannel])return YES;
            }
        }
    }
    return NO;
}

- (void) setVmeCrateHVConstraint:(int)aVmeCrate state:(BOOL)aState
{
    if(aVmeCrate>=2)return;
    //tricky .. we have to location the HV crates based on the hv map using the VME crate (group 0).
    //But we don't care about the Veto system (group 1).
    ORMPodCrateModel* hvCrateObj[2] = {nil,nil};
    hvCrateObj[0] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,0"];
    hvCrateObj[1] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,1"];
    
    ORSegmentGroup* group = [self segmentGroup:0];
    int n = [group numSegments];    //both DAQ and Veto on the same HV supply now
    int i;
    for(i=0;i<n;i++){
        ORDetectorSegment* seg =  [group segment:i];        //get a segment from the group
		int vmeCrate = [[seg objectForKey:@"kVME"] intValue];           //pull out the crate
        if(vmeCrate == aVmeCrate){
            int hvCrate = [[seg objectForKey:@"kHVCrate"]intValue];    //pull out the crate
            int hvCard  = [[seg objectForKey:@"kHVCard"]intValue];     //pull out the card
            if(hvCrate<2){
                if(aState) {
                    [[hvCrateObj[hvCrate] cardInSlot:hvCard] addHvConstraint:@"MJD Vac" reason:[NSString stringWithFormat:@"HV (%d) Card (%d) mapped to VME %d and Vacuum Is Bad or Vacuum system is not communicating",hvCrate,hvCard,aVmeCrate]];
                }
                else {
                    [[hvCrateObj[hvCrate] cardInSlot:hvCard] removeHvConstraint:@"MJD Vac"];
                    [rampHVAlarm[aVmeCrate] setAcknowledged:NO];
                }
            }
        }
    }
}

- (void) rampDownHV:(int)aCrate vac:(int)aVacSystem
{
    if(aVacSystem==0 && ignorePanicOnA)return;
    if(aVacSystem==1 && ignorePanicOnB)return;
    
    if(!rampHVAlarm[aVacSystem]){
        rampHVAlarm[aVacSystem] = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Panic HV (Vac %c)",'A'+aVacSystem] severity:(kEmergencyAlarm)];
        [rampHVAlarm[aVacSystem] setSticky:NO];
        [rampHVAlarm[aVacSystem] setHelpString:[NSString stringWithFormat:@"HV was ramped down on Module %d because Vac %c failed interlocks\nThe alarm can be cleared by acknowledging it.",aCrate, 'A'+aVacSystem]];
        NSLogColor([NSColor redColor], @"HV was ramped down on Module %d because Vac %c failed interlocks\n",aCrate,
                   'A'+aVacSystem);
    }
    
    if(![rampHVAlarm[aVacSystem] acknowledged]){
       [rampHVAlarm[aVacSystem] postAlarm];
    }
    
    
    [[NSNotificationCenter defaultCenter]
            postNotificationName:ORRequestRunHalt
                          object:self
                        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"HV Panic",@"Reason",nil]];
    
    //tricky .. we have to location the HV crates based on the hv map using the VME crate (group 0).
    //But we don't care about the Veto system (group 1).
    ORMPodCrateModel* hvCrateObj[2] = {nil,nil};
    hvCrateObj[0] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,0"];
    hvCrateObj[1] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,1"];
    
    ORSegmentGroup* group = [self segmentGroup:0];
    //both DAQ and Veto on the same HV supply now
    int n = [group numSegments];
    int i;
    for(i=0;i<n;i++){
        ORDetectorSegment* seg = [group segment:i];                    //get a segment from the group
		int vmeCrate = [[seg objectForKey:@"kVME"] intValue];           //pull out the crate
        if(vmeCrate == aCrate){
            int hvCrate   = [[seg objectForKey:@"kHVCrate"]intValue];     //pull out the crate
            int hvCard    = [[seg objectForKey:@"kHVCard"]intValue];     //pull out the card
            if(hvCrate<2){
                [[hvCrateObj[hvCrate] cardInSlot:hvCard] panicAllChannels];
            }
        }
    }
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setIgnorePanicOnB:[decoder decodeBoolForKey:@"ignorePanicOnB"]];
    [self setIgnorePanicOnA:[decoder decodeBoolForKey:@"ignorePanicOnA"]];
    [self setIgnoreBreakdownCheckOnB:[decoder decodeBoolForKey:@"ignoreBreakdownCheckOnB"]];
    [self setIgnoreBreakdownCheckOnA:[decoder decodeBoolForKey:@"ignoreBreakdownCheckOnA"]];
    [self setIgnoreBreakdownPanicOnB:[decoder decodeBoolForKey:@"ignoreBreakdownPanicOnB"]];
    [self setIgnoreBreakdownPanicOnA:[decoder decodeBoolForKey:@"ignoreBreakdownPanicOnA"]];
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];
    [self setVerboseDiagnostics:[decoder decodeBoolForKey:@"verboseDiagnostics"]];
    [self setMinNumDetsToAlertExperts:[decoder decodeIntForKey:@"minNumDetsToAlertExperts"]];

    int i;
    for(i=0;i<2;i++){
        mjdInterlocks[i] = [[ORMJDInterlocks alloc] initWithDelegate:self slot:i];
        mjdSource[i] = [[ORMJDSource alloc] initWithDelegate:self slot:i];
    }
    pollTime   = [decoder  decodeIntForKey:	@"pollTime"];
    stringMap  = [[decoder decodeObjectForKey:@"stringMap"] retain];
    specialMap = [[decoder decodeObjectForKey:@"specialMap"] retain];

    [self validateStringMap];
    [self validateSpecialMap];
    [self setDetectorStringPositions];
    
    float maxCalRate = [decoder decodeFloatForKey:@"maxNonCalibrationRate"];
    if(maxCalRate==0)maxCalRate = 1000;
    [self setMaxNonCalibrationRate:maxCalRate];
	[[self undoManager] enableUndoRegistration];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:verboseDiagnostics       forKey:@"verboseDiagnostics"];
    [encoder encodeBool:ignorePanicOnB           forKey:@"ignorePanicOnB"];
    [encoder encodeBool:ignorePanicOnA           forKey:@"ignorePanicOnA"];
    [encoder encodeBool:ignoreBreakdownCheckOnB  forKey:@"ignoreBreakdownCheckOnB"];
    [encoder encodeBool:ignoreBreakdownCheckOnA  forKey:@"ignoreBreakdownCheckOnA"];
    [encoder encodeBool:ignoreBreakdownPanicOnB  forKey:@"ignoreBreakdownPanicOnB"];
    [encoder encodeBool:ignoreBreakdownPanicOnA  forKey:@"ignoreBreakdownPanicOnA"];
    [encoder encodeInt:viewType                  forKey: @"viewType"];
	[encoder encodeInt:pollTime		             forKey: @"pollTime"];
    [encoder encodeObject:stringMap	             forKey: @"stringMap"];
    [encoder encodeObject:specialMap             forKey: @"specialMap"];
    [encoder encodeFloat:maxNonCalibrationRate   forKey: @"maxNonCalibrationRate"];
    [encoder encodeInt:minNumDetsToAlertExperts  forKey: @"minNumDetsToAlertExperts"];

}

- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if([aString length] == 0)return @"Not Mapped";
	if(aSet==0){
        NSString* finalString = @"";
        NSArray* parts = [aString componentsSeparatedByString:@"\n"];
        
        NSString* gainType = [self getValueForPartStartingWith: @" GainType"   parts:parts];
        if([gainType length]==0)return @"Not Mapped";
        if([gainType intValue]==0)gainType = @"LG";
        else gainType = @"HG";
 
        NSString* detType = [self getValueForPartStartingWith: @" DetectorType"   parts:parts];
        if([detType length]==0)return @"Not Mapped";
        if([detType intValue]==0)    detType = @" BeGe";
        else if([detType intValue]==2)detType = @" Enriched";
        else detType = @"";

        
        finalString = [finalString stringByAppendingFormat: @"%@\n",[parts objectAtIndex:0]];
        finalString = [finalString stringByAppendingFormat: @"%@%@\n",[self getPartStartingWith:    @" DetectorName"   parts:parts],detType];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" VME"       parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" CardSlot"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@ (%@)\n\n",[self getPartStartingWith: @" Channel"   parts:parts],gainType];
        
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" PreAmpDigitizer"   parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" PreAmpChan"   parts:parts]];

        finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:      @" HVCrate"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" HVCard"   parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" HVChan"   parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" Threshold" parts:parts]];
        
        return finalString;
    }
    else if(aSet==1){
        NSString* finalString = @"";
        NSArray* parts = [aString componentsSeparatedByString:@"\n"];
        if([parts count]<6)return @"Not Mapped";
        
        finalString = [finalString stringByAppendingFormat:@"%@\n",[parts objectAtIndex:0]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" Segment"   parts:parts]];
        finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith: @" VME"       parts:parts]       ];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" CardSlot"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" Channel"   parts:parts]];
 
        finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith: @" HVCrate" parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" HVCard"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" HVChan"  parts:parts]];
        
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" Threshold" parts:parts]];

        return finalString;
    }
    else return @"Not Mapped";
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}

- (NSString*) getValueForPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound){
            NSArray* subParts = [aLine componentsSeparatedByString:@":"];
            if([subParts count]>=2){
                return [subParts objectAtIndex:1];
            }
        }
	}
	return @"";
}

- (void) readAuxFiles:(NSString*)aPath
{
    NSFileManager* fm = [NSFileManager defaultManager];
	NSString* path = MJDStringMapFile([aPath stringByDeletingPathExtension]);
    
	if([fm fileExistsAtPath:path]){
		NSArray* lines  = [self linesInFile:path];
		for(id aLine in lines){
			if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
				NSArray* parts =  [aLine componentsSeparatedByString:@","];
				if([parts count]>=3){
                    
                    if([[parts objectAtIndex:0] rangeOfString:@"S"].location != NSNotFound)continue;
                    
					int index = [[parts objectAtIndex:0] intValue];
					if(index<14){
						NSMutableDictionary* dict = [stringMap objectAtIndex:index];
                        [dict setObject:[parts objectAtIndex:0] forKey:@"kStringNum"];
						[dict setObject:[parts objectAtIndex:1] forKey:@"kDet1"];
						[dict setObject:[parts objectAtIndex:2] forKey:@"kDet2"];
						[dict setObject:[parts objectAtIndex:3] forKey:@"kDet3"];
						[dict setObject:[parts objectAtIndex:4] forKey:@"kDet4"];
                        [dict setObject:[parts objectAtIndex:5] forKey:@"kDet5"];
                        //added....
                        if([parts objectAtIndex:6])[dict setObject:[parts objectAtIndex:6] forKey:@"kStringName"];
                        else [dict setObject:@"-" forKey:@"kStringName"];
					}
				}
			}
		}
	}
    
    path = MJDSpecialMapFile([aPath stringByDeletingPathExtension]);
    
    if([fm fileExistsAtPath:path]){
        NSArray* lines  = [self linesInFile:path];
        for(id aLine in lines){
            if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
                NSArray* parts =  [aLine componentsSeparatedByString:@","];
                if([parts count]>=9){
                    
                    int index = [[parts objectAtIndex:0] intValue];
                    NSMutableDictionary* dict = [specialMap objectAtIndex:index];
                    [dict setObject:[parts objectAtIndex:0] forKey:@"kIndex"];
                    [dict setObject:[parts objectAtIndex:1] forKey:@"kDescription"];
                    [dict setObject:[parts objectAtIndex:2] forKey:@"kVME"];
                    [dict setObject:[parts objectAtIndex:3] forKey:@"kCard"];
                    [dict setObject:[parts objectAtIndex:4] forKey:@"kChannel"];
                    [dict setObject:[parts objectAtIndex:5] forKey:@"kPreAmpDigitizer"];
                    [dict setObject:[parts objectAtIndex:6] forKey:@"kPreAmpChan"];
                    [dict setObject:[parts objectAtIndex:7] forKey:@"kCableLabel"];
                    [dict setObject:[parts objectAtIndex:8] forKey:@"kSpecialType"];
                }
            }
        }
    }
    else {
        [specialMap release];
        specialMap = nil;
        [self validateSpecialMap];
    }
}

- (void) saveAuxFiles:(NSString*)aPath
{
    NSFileManager*   fm       = [NSFileManager defaultManager];

	NSString* stringMapPath = MJDStringMapFile([aPath stringByDeletingPathExtension]);
	if([fm fileExistsAtPath: stringMapPath])[fm removeItemAtPath:stringMapPath error:nil];
	NSData* data = [[self stringMapFileAsString] dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:stringMapPath contents:data attributes:nil];

    NSString* specialMapPath = MJDSpecialMapFile([aPath stringByDeletingPathExtension]);
    if([fm fileExistsAtPath: specialMapPath])[fm removeItemAtPath:specialMapPath error:nil];
    data = [[self specialMapFileAsString] dataUsingEncoding:NSASCIIStringEncoding];
    [fm createFileAtPath:specialMapPath contents:data attributes:nil];
}

- (NSString*) stringMapFileAsString
{
   	NSMutableString* stringRep = [NSMutableString string];
    [stringRep appendFormat:@"Index,Det1,Det2,Det3,Det4,Det5,Name\n"];
    for(id item in stringMap){
        //special, handle the lastest additions
        NSString* name = [item objectForKey:@"kStringName"];
        if([name length]==0)name = @"-";
        
        [stringRep appendFormat:@"%@,%@,%@,%@,%@,%@,%@\n",
                              [item objectForKey:@"kStringNum"],
                              [item objectForKey:@"kDet1"],
                              [item objectForKey:@"kDet2"],
                              [item objectForKey:@"kDet3"],
                              [item objectForKey:@"kDet4"],
                              [item objectForKey:@"kDet5"],
                              name
                              ];
    }
    [stringRep deleteCharactersInRange:NSMakeRange([stringRep length]-1,1)];
    return stringRep;
}

- (NSString*) specialMapFileAsString
{
   	NSMutableString* stringRep = [NSMutableString string];
    [stringRep appendFormat:@"Index,Description,VME,Slot,Chan,PADig,PAChan,Cable,Type\n"];
    for(id item in specialMap){
        
        [stringRep appendFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
         [item objectForKey:@"kIndex"],
         [item objectForKey:@"kDescription"],
         [item objectForKey:@"kVME"],
         [item objectForKey:@"kCard"],
         [item objectForKey:@"kChannel"],
         [item objectForKey:@"kPreAmpDigitizer"],
         [item objectForKey:@"kPreAmpChan"],
         [item objectForKey:@"kCableLabel"],
         [item objectForKey:@"kSpecialType"]
         ];
    }
    [stringRep deleteCharactersInRange:NSMakeRange([stringRep length]-1,1)];
    return stringRep;
}


#pragma mark ¥¥¥String Map Access Methods

- (BOOL) validateDetector:(int)aDetectorIndex
{
    int numSegments = [self numberSegmentsInGroup:0];
    if(aDetectorIndex>=0 && aDetectorIndex<numSegments){
        ORSegmentGroup* segmentGroup = [self segmentGroup:0];
        NSDictionary* params = [[segmentGroup segment:aDetectorIndex]params];
        if(!params)return NO;
        NSString* aCrate = [params objectForKey:@"kVME"];
        if([aCrate length]==0 || [aCrate rangeOfString:@"-"].location!=NSNotFound)return NO;

        NSString* aCard = [params objectForKey:@"kCardSlot"];
        if([aCard length]==0 || [aCard rangeOfString:@"-"].location!=NSNotFound)return NO;
                                 
         NSString* aChannel = [params objectForKey:@"kChannel"];
         if([aChannel length]==0 || [aChannel rangeOfString:@"-"].location!=NSNotFound)return NO;

        NSString* aName = [params objectForKey:@"kDetectorName"];
        if([aName length]==0 || [aName rangeOfString:@"-"].location!=NSNotFound)return NO;

        return YES;
    }
    
    return NO;
}

- (id) stringMap:(int)i objectForKey:(id)aKey
{
    if(i>=0 && i<kMaxNumStrings){
        return [[stringMap objectAtIndex:i] objectForKey:aKey];
    }
    else return @"";
}

- (void) stringMap:(int)i setObject:(id)anObject forKey:(id)aKey
{
	if(i>=0 && i<kMaxNumStrings){
		id entry = [stringMap objectAtIndex:i];
		id oldValue = [self stringMap:i objectForKey:aKey];
		if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] stringMap:i setObject:oldValue forKey:aKey];
		[entry setObject:anObject forKey:aKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDAuxTablesChanged object:self userInfo:nil];
		
	}
}

- (id) specialMap:(int)i objectForKey:(id)aKey
{
    if(i>=0 && i<kNumSpecialChannels){
        return [[specialMap objectAtIndex:i] objectForKey:aKey];
    }
    else return @"";
}
- (void) specialMap:(int)i setObject:(id)anObject forKey:(id)aKey
{
    if(i>=0 && i<kNumSpecialChannels){
        id entry = [specialMap objectAtIndex:i];
        id oldValue = [self specialMap:i objectForKey:aKey];
        if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] specialMap:i setObject:oldValue forKey:aKey];
        [entry setObject:anObject forKey:aKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDAuxTablesChanged object:self userInfo:nil];
    }
}


#pragma mark ¥¥¥CardHolding Protocol
- (int) maxNumberOfObjects              { return 3; }
- (int) objWidth                        { return 50; }	//In this case, this is really the obj height.
- (int) groupSeparation                 { return 0; }
- (NSString*) nameForSlot:(int)aSlot    { return [NSString stringWithFormat:@"Slot %d",aSlot]; }
- (int) slotForObj:(id)anObj            { return [anObj tag]; }
- (int) numberSlotsNeededFor:(id)anObj  { return 1;           }
- (int) slotAtPoint:(NSPoint)aPoint     { return floor(((int)aPoint.y)/[self objWidth]); }
- (NSPoint) pointForSlot:(int)aSlot     { return NSMakePoint(0,aSlot*[self objWidth]); }

- (NSRange) legalSlotsForObj:(id)anObj
{
	if([anObj isKindOfClass:NSClassFromString(@"ORRemoteSocketModel")])			return NSMakeRange(0,3);
    else return NSMakeRange(0,0);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj
{
	if([anObj isKindOfClass:NSClassFromString(@"ORRemoteSocketModel")])	return NO;
    else return YES;
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
    [anObj setTag:aSlot];
	NSPoint slotPoint = [self pointForSlot:aSlot];
	[anObj moveTo:slotPoint];
}

- (void) openDialogForComponent:(int)i
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj tag] == i){
			[anObj makeMainController];
			break;
		}
	}
}

- (void) setDetectorStringPositions
{
    //first must reset all positions
    ORSegmentGroup* segmentGroup = [self segmentGroup:0];
    int numSegments = [self numberSegmentsInGroup:0];
    int i;
    for(i = 0; i<numSegments; i++){
        [segmentGroup setSegment:i object:@"-" forKey:@"kStringName"];
    }
    
    for(i=0;i<14;i++){
        int j;
        for(j=0;j<5;j++){
            NSString* detectorNum = [self stringMap:i objectForKey:[NSString stringWithFormat:@"kDet%d",j+1]];
            NSString* stringName  = [self stringMap:i objectForKey:@"kStringName"];
            if([detectorNum rangeOfString:@"-"].location == NSNotFound && [detectorNum length]!=0){
                int detIndex = [detectorNum intValue];
                [segmentGroup setSegment:detIndex*2 object:[NSNumber numberWithInt:i] forKey:@"kStringNum"];
                [segmentGroup setSegment:detIndex*2 object:[NSNumber numberWithInt:j] forKey:@"kPosition"];
                [segmentGroup setSegment:detIndex*2 object:stringName                 forKey:@"kStringName"];
            }
        }
    }
}
- (NSString*) detectorLocation:(int)index
{
    ORMJDSegmentGroup* segmentGroup = (ORMJDSegmentGroup*)[self segmentGroup:0];
    return [segmentGroup segmentLocation:index];
}

- (void) deploySource:(int)index
{
    if(index>=0 && index<2)[mjdSource[index] startDeployment];
}

- (void) retractSource:(int)index
{
    if(index>=0 && index<2)[mjdSource[index] startRetraction];
}

- (void) stopSource:(int)index
{
    if(index>=0 && index<2)[mjdSource[index] stopSource];
}

- (void) checkSourceGateValve:(int)index
{
    if(index>=0 && index<2)[mjdSource[index] checkGateValve];
}

- (void) initDigitizers
{
    @try {
        [[[segmentGroups objectAtIndex:0]hwCards] makeObjectsPerformSelector:@selector(initBoard)];
        NSLog(@"%@ Digitizers inited\n",[self className]);
    }
    @catch (NSException * e) {
        NSLogColor([NSColor redColor],@"%@ Digitizers init failed\n",[self className]);
    }
}

- (void) initVeto
{
    @try {
        [[[segmentGroups objectAtIndex:1]hwCards] makeObjectsPerformSelector:@selector(initBoard)];
        NSLog(@"%@ Veto inited\n",[self className]);
    }
    @catch (NSException * e) {
        NSLogColor([NSColor redColor],@"%@ Veto init failed\n",[self className]);
    }
}

- (void) constraintCheckFinished:(int)aCrate
{
}

@end

@implementation MajoranaModel (private)
- (void) checkConstraints
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkConstraints) object:nil];
    int i;
    
    if(pollTime){
        [self performSelector:@selector(checkConstraints) withObject:nil afterDelay:pollTime*60];
        for(i=0;i<2;i++){
            if([self remoteSocket:i])[mjdInterlocks[i] start];
        }
        [self setLastConstraintCheck:[NSDate date]];
    }
    else {
       for(i=0;i<2;i++){
           if([self remoteSocket:i])[mjdInterlocks[i] stop];
       }
       
    }
}



- (void) validateStringMap
{
    if(!stringMap){
        stringMap = [[NSMutableArray array] retain];
        int i;
        for(i=0;i<kMaxNumStrings;i++){
            [stringMap addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:i], @"kStringNum",
                                  @"-",						 @"kDet1",
                                  @"-",						 @"kDet2",
                                  @"-",						 @"kDet3",
                                  @"-",						 @"kDet4",
                                  @"-",						 @"kDet5",
                                  @"-",                      @"kStringName",
                                  nil]];
        }
    }
}

- (void) validateSpecialMap
{
    if([specialMap count]<kNumSpecialChannels){
        [specialMap release];
        specialMap = nil;
    }
    if(!specialMap){
        specialMap = [[NSMutableArray array] retain];
        int i;
        for(i=0;i<kNumSpecialChannels;i++){
            [specialMap addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:i], @"kIndex",
                                  @"-",						 @"kDescription",
                                  @"-",						 @"kVME",
                                  @"-",						 @"kCard",
                                  @"-",						 @"kChannel",
                                  @"-",						 @"kPreAmpDigitizer",
                                  @"-",                      @"kPreAmpChan",
                                  @"-",                      @"kCableLabel",
                                  @"-",                      @"kSpecialType",
                                  nil]];
        }
    }
}

- (NSArray*) linesInFile:(NSString*)aPath
{
	NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
	contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
    return [contents componentsSeparatedByString:@"\n"];
}

@end

@implementation ORMJDHeaderRecordID
- (NSString*) fullID
{
   return @"MJDDataHeader";
}
@end

