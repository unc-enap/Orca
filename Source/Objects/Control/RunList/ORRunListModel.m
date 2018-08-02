//
//  ORRunListModel.m
//  Orca
//
//  Created by Mark Howe on Tues Feb 09 2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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
#import "ORRunListModel.h"
#import "ORDataPacket.h"
#import "ORDataProcessing.h"
#import "TimedWorker.h"
#import "ORRunModel.h"
#import "ORScriptIDEModel.h"
#import "ORScriptRunner.h"

#define kTimeDelta .1

enum eRunListStates {
    kStartup,
    kWaitForRunToStop,
    kWaitForSubRun,
    kReadyToStart,
    kStartRun,
    kStartSubRun,
    kStartScript,
    kWaitForScript,
    kWaitForRunTime,
    kStartEndScript,
    kWaitForEndScript,
    kRunFinished,
    kCheckForRepeat,
    kFinishUp,
    kPause,
}eRunListStates;

#pragma mark •••Local Strings
NSString* ORRunListModelTimesToRepeatChanged	= @"ORRunListModelTimesToRepeatChanged";
NSString* ORRunListModelLastFileChanged			= @"ORRunListModelLastFileChanged";
NSString* ORRunListModelRandomizeChanged		= @"ORRunListModelRandomizeChanged";
NSString* ORRunListModelWorkingItemIndexChanged = @"ORRunListModelWorkingItemIndexChanged";
NSString* ORRunListItemsAdded		= @"ORRunListItemsAdded";
NSString* ORRunListItemsRemoved		= @"ORRunListItemsRemoved";
NSString* ORRunListListLock			= @"ORRunListListLock";
NSString* ORRunListRunStateChanged	= @"ORRunListRunStateChanged";
NSString* ORRunListModelReloadTable	= @"ORRunListModelReloadTable";

static NSString* ORRunListDataOut	= @"ORRunListDataOut";
static NSString* ORRunListDataOut1	= @"ORRunListDataOut1";

@interface ORRunListModel (private)
- (void) checkStatus;
- (void) restoreRunModelOptions;
- (void) saveRunModelOptions;
- (void) goToNextWorkingIndex;
- (id)   getScriptParameters;
- (id)   getEndScriptParameters;
- (void) resetItemStates;
- (void) setWorkingItemState;
- (id) objectAtWorkingIndex;
- (void) calcTotalExpectedTime;
- (void) setUpWorkingOrder;
- (void) collectSubRunsAtIndex:(int)anIndex intoRun:(NSMutableDictionary*) aRun;

@end

@implementation ORRunListModel

#pragma mark •••initialization

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [lastFile release];
	[runModel release];
    [scriptAtStartModel release];
    [scriptAtEndModel release];
	[timedWorker release];
	[items release];
	[orderArray release];
    [timeStarted release];
    [timeRunStarted release];
    [super dealloc];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(10,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORRunListDataOut];
	[aConnector setIoType:kOutputConnector];
	[aConnector setConnectorType: 'SCRO'];
	[aConnector addRestrictedConnectionType: 'SCRI']; //can only connect to Script Inputs
    [aConnector release];
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint(50,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORRunListDataOut1];
    [aConnector setIoType:kOutputConnector];
    [aConnector setConnectorType: 'SCRO'];
    [aConnector addRestrictedConnectionType: 'SCRI']; //can only connect to Script Inputs
    [aConnector release];

}

//- (BOOL) solitaryObject
//{
//    return YES;
//}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"RunList"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORRunListController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Run_List.html";
}

#pragma mark ***Accessors

- (int) executionCount
{
    return executionCount;
}

- (int) timesToRepeat
{
    return timesToRepeat;
}

- (void) setTimesToRepeat:(int)aTimesToRepeat
{
	if(aTimesToRepeat<1)aTimesToRepeat=1;
    [[[self undoManager] prepareWithInvocationTarget:self] setTimesToRepeat:timesToRepeat];
    
    timesToRepeat = aTimesToRepeat;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelTimesToRepeatChanged object:self];
}

- (NSString*) lastFile
{
	if(![lastFile length]) return @"--";
    else return lastFile;
}

- (void) setLastFile:(NSString*)aLastFile
{
    [lastFile autorelease];
    lastFile = [aLastFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelLastFileChanged object:self];
}

- (BOOL) randomize
{
    return randomize;
}

- (void) setRandomize:(BOOL)aRandomize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRandomize:randomize];
    
    randomize = aRandomize;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelRandomizeChanged object:self];
}
- (TimedWorker*) timedWorker
{
	return timedWorker;
}

- (BOOL) isRunning
{
    return timedWorker != nil;
}
- (BOOL) isPaused
{
    return runListState == kPause;
}
- (void) startRunning
{
    timedWorker = [[TimedWorker TimeWorkerWithInterval:kTimeDelta] retain];
    [timedWorker runWithTarget:self selector:@selector(checkStatus)];
    runListState = kStartup;
    executionCount = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListRunStateChanged object:self];
}

- (void) pauseRunning;
{
    runListState = kPause;
}
- (void) restartRunning;
{
    runListState = kStartRun;
    if([orderArray count]>0){
        id anItem = [self objectAtWorkingIndex];
        [anItem setObject:@"Incomplete"  forKey:@"RunState"];
    }
    [self setUpWorkingOrder];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListRunStateChanged object:self];
}

- (void) stopRunning
{
	runListState = kFinishUp;
}

- (void) addItem
{
	if(!items) items= [[NSMutableArray array] retain];
	id newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"-",@"RunState",nil];
	[self addItem:newItem atIndex:[items count]];
}

- (void) addItem:(id)anItem atIndex:(NSInteger)anIndex
{
	if(!items) items= [[NSMutableArray array] retain];
	if([items count] == 0)anIndex = 0;
	anIndex = MIN(anIndex,[items count]);
	[[[self undoManager] prepareWithInvocationTarget:self] removeItemAtIndex:anIndex];
	[items insertObject:anItem atIndex:anIndex];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListItemsAdded object:self userInfo:userInfo];
}

- (void) removeItemAtIndex:(NSInteger) anIndex
{
	id anItem = [items objectAtIndex:anIndex];
	[[[self undoManager] prepareWithInvocationTarget:self] addItem:anItem atIndex:anIndex];
	[items removeObjectAtIndex:anIndex];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListItemsRemoved object:self userInfo:userInfo];
}

- (id) itemAtIndex:(NSInteger)anIndex
{
	if(anIndex>=0 && anIndex<[items count])return [items objectAtIndex:anIndex];
	else return nil;
}

- (uint32_t) itemCount
{
	return (uint32_t)[items count];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(runHalted:)
                         name : ORRunModelRunHalted
                       object : nil];
}

- (void)runHalted:(NSNotification*)aNote
{   
    runListState = kFinishUp;
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setTimesToRepeat:[decoder decodeIntForKey:@"timesToRepeat"]];
    [self setLastFile:[decoder decodeObjectForKey:@"lastFile"]];
    [self setRandomize:[decoder decodeBoolForKey:@"randomize"]];
	items = [[decoder decodeObjectForKey:@"items"] retain];
	
	for(id anItem in items){ 
		[anItem setObject:@"" forKey:@"RunState"];
	}
	
    [self registerNotificationObservers];

    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInteger:timesToRepeat    forKey:@"timesToRepeat"];
	[encoder encodeObject:lastFile      forKey:@"lastFile"];
	[encoder encodeBool:randomize       forKey:@"randomize"];
	[encoder encodeObject:items			forKey:@"items"];
}

- (void) saveToFile:(NSString*)aPath
{
	NSString* s = @"#Script Parameters:RunLength:SubRun\n";
	for(id anItem in items){ 
        id isSubRun             = [anItem objectForKey:@"SubRun"];
        if(!isSubRun)isSubRun   = [NSNumber numberWithBool:NO];
		s = [s stringByAppendingFormat:@"%@:%@:%@:%@\n",
             [[anItem objectForKey:@"ScriptParameters"]length]   > 0 ? [anItem objectForKey:@"ScriptParameters"]:@"",
             [[anItem objectForKey:@"EndScriptParameters"]length]> 0 ? [anItem objectForKey:@"EndScriptParameters"]:@"",
			 [[anItem objectForKey:@"RunLength"]length]          > 0 ? [anItem objectForKey:@"RunLength"]:@"0",
             isSubRun];
	}
    [[NSFileManager defaultManager] removeItemAtPath:aPath error:nil];
	[s writeToFile:aPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
}

- (void) restoreFromFile:(NSString*)aPath
{
	[self setLastFile:aPath];
	NSStringEncoding* encoding = nil;
	NSString* s = [NSString stringWithContentsOfFile:[lastFile stringByExpandingTildeInPath] usedEncoding:encoding error:nil];
	[items release];
	items = [[NSMutableArray array] retain];
	NSArray* lines = [s componentsSeparatedByString:@"\n"];
    int lineNumber = 0;
	for(id aLine in lines){
		aLine = [aLine trimSpacesFromEnds];
		if(![aLine hasPrefix:@"#"]){
			NSArray* parts = [aLine componentsSeparatedByString:@":"];
			if([parts count] == 4){
                NSString* args = [[parts objectAtIndex:0] trimSpacesFromEnds];
                if([args isEqualToString:@"(null)"])args = @"";
                NSString* endArgs = [[parts objectAtIndex:1] trimSpacesFromEnds];
                if([endArgs isEqualToString:@"(null)"])endArgs = @"";
				NSMutableDictionary* anItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										args,@"ScriptParameters",endArgs,@"EndScriptParameters",
										[NSNumber numberWithFloat:[[[parts objectAtIndex:2] trimSpacesFromEnds]floatValue]],@"RunLength",
                                               lineNumber==0?@0:[NSNumber numberWithInt:[[[parts objectAtIndex:3] trimSpacesFromEnds]intValue]],@"SubRun",
										@"",@"RunState",
										nil];
				[items addObject:anItem];
			}
            
            else if([parts count] == 3){ //old version
                NSString* args = [[parts objectAtIndex:0] trimSpacesFromEnds];
                if([args isEqualToString:@"(null)"])args = @"";
                NSMutableDictionary* anItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               args,@"ScriptParameters",@"",@"EndScriptParameters",
                                               [NSNumber numberWithFloat:[[[parts objectAtIndex:1] trimSpacesFromEnds]floatValue]],@"RunLength",
                                               lineNumber==0?@0:[NSNumber numberWithInt:[[[parts objectAtIndex:2] trimSpacesFromEnds]intValue]],@"SubRun",
                                               @"",@"RunState",
                                               nil];
                [items addObject:anItem];
            }
            lineNumber++;
		}
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelReloadTable object:self];    
}

- (NSString*) runStateName
{
	switch(runListState){
		case kStartup:			return @"Startup";
		case kWaitForRunToStop:	return @"Run Wait";
		case kWaitForSubRun:	return @"Subrun Wait";
		case kReadyToStart:     return @"Ready";
		case kStartRun:			return @"StartRun";
		case kStartSubRun:		return @"StartSubRun";
		case kStartScript:		return @"Starting Script";
		case kWaitForScript:	return @"Script Wait";
		case kWaitForRunTime:	return [NSString stringWithFormat:@"%.0f",runLength - runTimeElapsed];
        case kStartEndScript:   return @"Starting End Script";
        case kWaitForEndScript:	return @"Script Wait";
		case kRunFinished:		return @"Done";
		case kCheckForRepeat:	return @"Repeat Check";
        case kFinishUp:         return @"Manual Quit";
        case kPause:            return @"Paused";
		default:			    return @"-";
	}
}
- (float) totalExpectedTime
{
	return totalExpectedTime;
}

- (float) accumulatedTime
{
	return accumulatedTime;
}

@end


@implementation ORRunListModel (private)
- (void) calcTotalExpectedTime
{
    [timeStarted release];
    timeStarted = [[NSDate alloc]init];
	accumulatedTime   = 0;
	totalExpectedTime = 0;
    skippedTime       = 0;
	for(id anItem in items){
		totalExpectedTime += [[anItem objectForKey:@"RunLength"] floatValue];
	}
}
	
- (void) setUpWorkingOrder
{
    if([orderArray count]){
        //starting from pause, not done with previous list
        //pop down to the next run to do
        [orderArray popTop];
        while([orderArray count]>0){
            id anItem = [orderArray objectAtIndex:0];
            int index = [anItem intValue];
            BOOL isSubRun = [[[items objectAtIndex:index] objectForKey:@"SubRun"]boolValue];
            if(isSubRun){
                id anItem = [self objectAtWorkingIndex];
                [anItem setObject:@"Skipped"  forKey:@"RunState"];
                float dt = [[anItem objectForKey:@"RunLength"]floatValue];
                skippedTime += dt;
                [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelWorkingItemIndexChanged object:self];
                [orderArray popTop];
            }
            else break;
        }
        return;
    }
    
    if(orderArray)[orderArray release];
    NSMutableArray* tempArray = [NSMutableArray array];

    if(randomize){
        //make array of dictionaries that hold the indexes
        //each dictionary may or may not have subruns and may have a dictionary of subruns
        NSMutableArray* runArray = [NSMutableArray array];
        //first collect all the runs into an array of dictionaries
        int index = 0;
        for(id anItem in items){
            if(![[anItem objectForKey:@"SubRun"] boolValue] || index==0){
                NSMutableDictionary* aRun = [NSMutableDictionary dictionary];
                [aRun setObject:[NSNumber numberWithInt:index] forKey:@"Index"];
                [runArray addObject:aRun];
            }
            index++;

        }
        //now loop over items and put subruns into the run dictionaries
        for(NSMutableDictionary* aRun in runArray){
            int nextRunIndex = [[aRun objectForKey:@"Index"] intValue]+1;
            if(nextRunIndex < [items count]){
                NSMutableDictionary* nextRunItem = [items objectAtIndex:nextRunIndex];
                if([nextRunItem objectForKey:@"SubRun"]){
                    [self collectSubRunsAtIndex: nextRunIndex intoRun:aRun];
                }
            }
        }
        //now we can randomize the runs and their subruns separately
        [runArray shuffle];
        //now shuffle the subruns (if any)
        for(NSMutableDictionary* aRun in runArray){
            NSMutableArray* subRuns = [aRun objectForKey:@"SubRuns"];
            [subRuns shuffle];
        }
        //finally create the orderArray
        for(NSDictionary* aRun in runArray){
            [tempArray addObject:[aRun objectForKey:@"Index"]];
            NSArray* subRuns = [aRun objectForKey:@"SubRuns"];
            for(id aSubRun in subRuns){
                [tempArray addObject:aSubRun];
            }
        }
    }
    else {
        int i=0;
        for(id anItem in items){
#pragma unused(anItem)
            [tempArray addObject:[NSNumber numberWithInt:i]];
            i++;
        }
    }
    orderArray = [[NSMutableArray arrayWithArray:tempArray] retain];

}

- (void) collectSubRunsAtIndex:(int)anIndex intoRun:(NSMutableDictionary*) aRun
{
    NSMutableArray* subRunArray = [NSMutableArray array];
    int index = 0;
    for(id anItem in items){
        if(index >= anIndex){
            if([[anItem objectForKey:@"SubRun"] boolValue]){
                [subRunArray addObject:[NSNumber numberWithInt:index]];
           }
            else break;
        }
        index++;
    }
    if([subRunArray count])[aRun setObject:subRunArray forKey:@"SubRuns"];
}

- (id) objectAtWorkingIndex
{
    if([orderArray count]){
        int index = [[orderArray objectAtIndex:0] intValue];
        return [items objectAtIndex:index];
    }
    else return 0;
}

- (void) checkStatus
{
	BOOL doSubRun;
	NSArray* runObjects;
	
	switch(runListState){
		case kStartup:
			[self resetItemStates];
			runObjects          = [[self document] collectObjectsOfClass:[ORRunModel class]];
			runModel            = [[runObjects objectAtIndex:0] retain];
            scriptAtStartModel  = [[self objectConnectedTo:ORRunListDataOut] retain];
            scriptAtEndModel    = [[self objectConnectedTo:ORRunListDataOut1] retain];
			[self saveRunModelOptions];
            if([runModel isRunning]){
                [runModel stopRun];
                runListState = kWaitForRunToStop;
                nextState = kReadyToStart;
            }
            else   runListState = kReadyToStart;
        break;
            
        case kWaitForRunToStop:
			[self setWorkingItemState];
            if(![runModel isRunning])runListState = nextState;
        break;
			
		case kWaitForSubRun:
			[self setWorkingItemState];
			if([runModel runningState] == eRunBetweenSubRuns) runListState = nextState;
		break;
			
        case kReadyToStart:
			if(!scriptAtStartModel) runListState = kStartRun;
			else                    runListState = kStartScript;
			[self calcTotalExpectedTime];
			[self setUpWorkingOrder];
		break;
			
		case kStartRun:
			[self setWorkingItemState];
			runLength = [[[self objectAtWorkingIndex] objectForKey:@"RunLength"] floatValue];
            [timeRunStarted release];
            timeRunStarted = [[NSDate alloc] init];
			if(runLength>0)[runModel startRun];
			runListState = kWaitForRunTime;
		break;
			
		case kStartSubRun:
			[self setWorkingItemState];
			runLength = [[[self objectAtWorkingIndex] objectForKey:@"RunLength"] intValue];
            [timeRunStarted release];
            timeRunStarted = [[NSDate alloc] init];
			[runModel startNewSubRun];
			runListState = kWaitForRunTime;
			break;
			
		case kStartScript:
			[self setWorkingItemState];
			[scriptAtStartModel setInputValue:[self getScriptParameters]];
			[scriptAtStartModel runScript];
			runListState = kWaitForScript;
		break;
			
		case kWaitForScript:
			[self setWorkingItemState];
			if(![[scriptAtStartModel scriptRunner] running]) {
				doSubRun = [[[self objectAtWorkingIndex] objectForKey:@"SubRun"] intValue];
				if(doSubRun) runListState = kStartSubRun;
				else         runListState = kStartRun;
			}
		break;
			
		case kWaitForRunTime:
			[self setWorkingItemState];
            NSTimeInterval dt     = [[NSDate date] timeIntervalSinceDate:timeStarted];
            runTimeElapsed = [[NSDate date] timeIntervalSinceDate:timeRunStarted];
			accumulatedTime = dt+skippedTime;
            if(runTimeElapsed>=runLength){
                if(scriptAtEndModel)runListState = kStartEndScript;
                else                runListState = kRunFinished;
            }
		break;
			
        case kStartEndScript:
            [self setWorkingItemState];
            [scriptAtEndModel setInputValue:[self getEndScriptParameters]];
            [scriptAtEndModel runScript];
            runListState = kWaitForEndScript;
            break;
            
        case kWaitForEndScript:
            [self setWorkingItemState];
            if(![[scriptAtEndModel scriptRunner] running]) {
                //doSubRun = [[[self objectAtWorkingIndex] objectForKey:@"SubRun"] intValue];
                runListState = kRunFinished;
            }
            break;
            
		case kRunFinished:
			[self setWorkingItemState];
			[self goToNextWorkingIndex];
			if([orderArray count]==0) runListState = kCheckForRepeat;
			else {
				doSubRun = [[[self objectAtWorkingIndex] objectForKey:@"SubRun"] intValue];
				if(doSubRun){
					[runModel prepareForNewSubRun];
					runListState = kWaitForSubRun;
					if(!scriptAtStartModel) nextState = kStartSubRun;
					else                    nextState = kStartScript;
				}
				else {
					[runModel stopRun];
					runListState = kWaitForRunToStop;
					if(!scriptAtStartModel) nextState = kStartRun;
					else                    nextState = kStartScript;
				}
			}
		break;
			
		case kCheckForRepeat:
			executionCount++;
			if(executionCount>=timesToRepeat){
				runListState = kFinishUp;
			}
			else {
				runListState = kStartup;
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:ORRunListRunStateChanged object:self];
		break;
			
		case kFinishUp:
            accumulatedTime = totalExpectedTime;
            [[NSNotificationCenter defaultCenter] postNotificationName:ORRunElapsedTimesChangedNotification object:self];
            [self setWorkingItemState];
			[[scriptAtStartModel scriptRunner] stop];
			if([runModel isRunning])[runModel stopRun];
			[self restoreRunModelOptions];
			
			[runModel release];		runModel = nil;
            [scriptAtStartModel release];	scriptAtStartModel = nil;
            [scriptAtEndModel release];     scriptAtEndModel = nil;

			[timedWorker stop];
			[timedWorker release];
			timedWorker = nil;
			[orderArray release];
			orderArray = nil;
					
			[[NSNotificationCenter defaultCenter] postNotificationName:ORRunListRunStateChanged object:self];
		break;
        case kPause:
            if([runModel isRunning]){
                [runModel stopRun];
                runListState = kWaitForRunToStop;
                nextState = kPause;
            }

            [self setWorkingItemState];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListRunStateChanged object:self];
            break;

	}
}

- (void) restoreRunModelOptions
{
	[runModel setTimedRun:oldTimedRun];
	[runModel setRepeatRun:oldRepeatRun];
	[runModel setTimeLimit:oldRepeatTime];
}

- (void) saveRunModelOptions
{
	oldTimedRun = [runModel timedRun];
	oldRepeatRun = [runModel repeatRun];
	oldRepeatTime = [runModel timeLimit];
	[runModel setTimedRun:NO];
	[runModel setRepeatRun:NO];
}
			   
- (void) goToNextWorkingIndex
{
    [orderArray popTop];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelWorkingItemIndexChanged object:self];
}

- (id) getScriptParameters
{
	NSString* s = [[self objectAtWorkingIndex] objectForKey:@"ScriptParameters"];
	if([s length] == 0) return nil;
	else if([s rangeOfString:@","].location == NSNotFound)return [NSDecimalNumber decimalNumberWithString:s];
	else {
		NSArray* parts = [s componentsSeparatedByString:@","];
		NSMutableArray* numbers = [NSMutableArray array];
		for(id anItem in parts){
			[numbers addObject:[NSDecimalNumber decimalNumberWithString:anItem]];
		}
		return numbers;
	}
}

- (id) getEndScriptParameters
{
    NSString* s = [[self objectAtWorkingIndex] objectForKey:@"EndScriptParameters"];
    if([s length] == 0) return nil;
    else if([s rangeOfString:@","].location == NSNotFound)return [NSDecimalNumber decimalNumberWithString:s];
    else {
        NSArray* parts = [s componentsSeparatedByString:@","];
        NSMutableArray* numbers = [NSMutableArray array];
        for(id anItem in parts){
            [numbers addObject:[NSDecimalNumber decimalNumberWithString:anItem]];
        }
        return numbers;
    }
}

- (void) resetItemStates
{
	for(id anItem in items){
		[anItem setObject:@"-" forKey:@"RunState"];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelReloadTable object:self];
}


- (void) setWorkingItemState
{
	if([orderArray count]){
		id anItem = [self objectAtWorkingIndex];
		[anItem setObject:[self runStateName]  forKey:@"RunState"];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelReloadTable object:self];
}

@end
