//-------------------------------------------------------------------------
//  ORSciptTaskModel.m
//
//  Created by Mark A. Howe on Tuesday 12/26/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORScriptIDEModel.h"
#import "ORScriptRunner.h"
#import "ORLineMarker.h"
#import "ORNodeEvaluator.h"
#import "NSNotifications+Extensions.h"
#import "NSString+Extensions.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

NSString* ORScriptIDEModelNextPeriodicRunChanged	= @"ORScriptIDEModelNextPeriodicRunChanged";
NSString* ORScriptIDEModelPeriodicRunIntervalChanged = @"ORScriptIDEModelPeriodicRunIntervalChanged";
NSString* ORScriptIDEModelRunPeriodicallyChanged	= @"ORScriptIDEModelRunPeriodicallyChanged";
NSString* ORScriptIDEModelAutoRunAtQuitChanged		= @"ORScriptIDEModelAutoRunAtQuitChanged";
NSString* ORScriptIDEModelShowCommonOnlyChanged		= @"ORScriptIDEModelShowCommonOnlyChanged";
NSString* ORScriptIDEModelAutoStopWithRunChanged	= @"ORScriptIDEModelAutoStopWithRunChanged";
NSString* ORScriptIDEModelAutoStartWithRunChanged	= @"ORScriptIDEModelAutoStartWithRunChanged";
NSString* ORScriptIDEModelAutoStartWithDocumentChanged = @"ORScriptIDEModelAutoStartWithDocumentChanged";
NSString* ORScriptIDEModelCommentsChanged			= @"ORScriptIDEModelCommentsChanged";
NSString* ORScriptIDEModelShowSuperClassChanged		= @"ORScriptIDEModelShowSuperClassChanged";
NSString* ORScriptIDEModelScriptChanged				= @"ORScriptIDEModelScriptChanged";
NSString* ORScriptIDEModelNameChanged				= @"ORScriptIDEModelNameChanged";
NSString* ORScriptIDEModelLastFileChangedChanged	= @"ORScriptIDEModelLastFileChangedChanged";
NSString* ORScriptIDEModelLock						= @"ORScriptIDEModelLock";
NSString* ORScriptIDEModelBreakpointsChanged		= @"ORScriptIDEModelBreakpointsChanged";
NSString* ORScriptIDEModelBreakChainChanged			= @"ORScriptIDEModelBreakChainChanged";
NSString* ORScriptIDEModelGlobalsChanged			= @"ORScriptIDEModelGlobalsChanged";

@interface ORScriptIDEModel (private)
- (void) scheduleNextPeriodicRun;
@end

@implementation ORScriptIDEModel

#pragma mark ***Initialization
- (id) init
{
	self = [super init];
	[self registerNotificationObservers];
	return self;
}

- (void) dealloc 
{
    [nextPeriodicRun release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [comments release];
	[scriptName release];
	[inputValues release];
	[scriptRunner release];
    [temporaryStore release];
    [persistantStore release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
	[self registerNotificationObservers];
    [super wakeUp];
}

- (void) sleep
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self stopScript];
	[super sleep];
}

- (void) makeMainController
{
    [self linkToController:@"ORScriptIDEController"];
}

- (NSString*) helpURL
{
	return @"Subsystems/Script_IDE.html";
}

- (void) decorateIcon:(NSImage*)anImage
{
    if(autoStopWithRun || autoStartWithRun || autoStartWithDocument || autoRunAtQuit || runPeriodically){
		NSSize iconSize = [anImage size];
		NSFont *font = [NSFont fontWithName:@"Helvetica" size:18.0];
		NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
										 font,NSFontAttributeName,
										 [NSColor redColor],NSForegroundColorAttributeName,nil];
		NSAttributedString* s = [[NSAttributedString alloc] initWithString:@"A" attributes:attrsDictionary];
		NSSize labelSize = [s size];
		float height = iconSize.height;
		[s drawAtPoint:NSMakePoint(50 - labelSize.width-10,height-labelSize.height-5)];
		[s release];
    }
}


- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];

    
	[notifyCenter addObserver : self
					 selector : @selector(runStarted:)
						 name : ORRunStartedNotification
					   object : nil];

	[notifyCenter addObserver : self
					 selector : @selector(runEnded:)
						 name : ORRunStoppedNotification
					   object : nil];

    [ notifyCenter addObserver: self
                      selector: @selector( aboutToQuit: )
                          name: ORDocumentClosedNotification
                        object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(aboutToQuit:)
                         name: OROrcaAboutToQuitNotice
                       object: nil];
 
    [notifyCenter addObserver: self
                     selector: @selector(finalQuitNotice:)
                         name: OROrcaFinalQuitNotice
                       object: nil];

}

- (void) aboutToQuit:(NSNotification*)aNote
{
    if([scriptRunner running]){
        [scriptRunner stop];
    }
}

- (void) finalQuitNotice:(NSNotification*)aNote
{
    if(autoRunAtQuit && ![scriptRunner running]){
		runPeriodically = NO; //disable for the final run
        [self runScript];
        [(ORAppDelegate*)[NSApp delegate] delayTermination];
    }
}


- (void) awakeAfterDocumentLoaded
{
	if(autoStartWithDocument){
		[self runScript];
	}
}

- (void) runAboutToStart:(NSNotification*)aNote
{
    if(autoStartWithRun && ![scriptRunner running]){
        [self parseScript];
        if(!parsedOK){
            NSString* reason = [NSString stringWithFormat:@"Script <%@> has errors",[self scriptName]];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORRequestRunHalt
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:reason,@"Reason",nil]];
        }
    }
}

- (void) runStarted:(NSNotification*)aNote
{
	if(autoStartWithRun && ![scriptRunner running]){
		[self runScript];
	}
}

- (void) runEnded:(NSNotification*)aNote
{		
	if(autoStopWithRun && [scriptRunner running]){
		[self stopScript]; 
	}
}

#pragma mark ***Accessors
- (NSString*) runStatusString
{
	if([scriptRunner running]){
		return [[self scriptRunner] debugging]?@"Debugging":@"Running";
	}
	else if(nextPeriodicRun!=nil){
		NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"HH:mm:ss"];
		NSString* nextTime = [dateFormatter stringFromDate:nextPeriodicRun];
		return [NSString stringWithFormat:@"Idle until %@",nextTime];
	}
	else return @"";
}
- (NSDate*) nextPeriodicRun
{
    return nextPeriodicRun;
}

- (void) setNextPeriodicRun:(NSDate*)aNextPeriodicRun
{
    [aNextPeriodicRun retain];
    [nextPeriodicRun release];
    nextPeriodicRun = aNextPeriodicRun;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelNextPeriodicRunChanged object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptRunnerRunningChanged object:self];

}

- (int) periodicRunInterval
{
    return periodicRunInterval;
}

- (void) setPeriodicRunInterval:(int)aPeriodicRunInterval
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPeriodicRunInterval:periodicRunInterval];
    if(aPeriodicRunInterval<=0)aPeriodicRunInterval=1;
    periodicRunInterval = aPeriodicRunInterval;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelPeriodicRunIntervalChanged object:self];
}

- (BOOL) runPeriodically
{
    return runPeriodically;
}

- (void) setRunPeriodically:(BOOL)aRunPeriodically
{
	if(runPeriodically && !aRunPeriodically){
		NSLog(@"[%@] Periodic running manually ended. Script will not repeat.\n",[self identifier]);
	}
    [[[self undoManager] prepareWithInvocationTarget:self] setRunPeriodically:runPeriodically];
    runPeriodically = aRunPeriodically;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelRunPeriodicallyChanged object:self];
	if(!runPeriodically){
		[self setNextPeriodicRun:nil];
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	}
	[self setUpImage];

}

- (BOOL) autoRunAtQuit
{
    return autoRunAtQuit;
}

- (void) setAutoRunAtQuit:(BOOL)aAutoRunAtQuit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoRunAtQuit:autoRunAtQuit];
    
    autoRunAtQuit = aAutoRunAtQuit;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelAutoRunAtQuitChanged object:self];
}

- (BOOL) showCommonOnly
{
    return showCommonOnly;
}

- (void) setShowCommonOnly:(BOOL)aShowCommonOnly
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowCommonOnly:showCommonOnly];
    
    showCommonOnly = aShowCommonOnly;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelShowCommonOnlyChanged object:self];
}

- (BOOL) autoStopWithRun
{
    return autoStopWithRun;
}

- (void) setAutoStopWithRun:(BOOL)aAutoStopWithRun
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoStopWithRun:autoStopWithRun];
    
    autoStopWithRun = aAutoStopWithRun;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelAutoStopWithRunChanged object:self];
	[self setUpImage];
}

- (BOOL) autoStartWithRun
{
    return autoStartWithRun;
}

- (void) setAutoStartWithRun:(BOOL)aAutoStartWithRun
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoStartWithRun:autoStartWithRun];
    
    autoStartWithRun = aAutoStartWithRun;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelAutoStartWithRunChanged object:self];
	[self setUpImage];
}

- (BOOL) autoStartWithDocument
{
    return autoStartWithDocument;
}

- (void) setAutoStartWithDocument:(BOOL)aAutoStartWithDocument
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoStartWithDocument:autoStartWithDocument];
    
    autoStartWithDocument = aAutoStartWithDocument;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelAutoStartWithDocumentChanged object:self];
	[self setUpImage];
}

- (BOOL) breakChain
{
	return breakChain;
}

- (void) setBreakChain:(BOOL)aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setBreakChain:breakChain];
	breakChain = aState;
	[self setUpImage];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelBreakChainChanged object:self];
	
}
- (NSDictionary*) breakpoints
{
	return breakpoints;
}

- (void) setBreakpoints:(NSDictionary*) someBreakpoints
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setBreakpoints:breakpoints];
	
	[someBreakpoints retain];
	[breakpoints release];
	breakpoints = someBreakpoints;
	
	if([scriptRunner debugging] && [scriptRunner running]){
		[scriptRunner setBreakpoints:[self breakpointSet]];
	}
	
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelBreakpointsChanged object:self];
}

- (NSMutableIndexSet*) breakpointSet
{
	NSMutableIndexSet* aBreakpointSet = [NSMutableIndexSet indexSet];
	if([breakpoints count]){
		NSEnumerator* e = [breakpoints objectEnumerator];
		ORLineMarker* aMarker;
		while (aMarker = [e nextObject]) {
			[aBreakpointSet addIndex: [aMarker lineNumber]];
		}	
	}
	return aBreakpointSet;
}
- (id) evaluator
{
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	return [scriptRunner eval];
}

- (NSString*) comments
{
	if(!comments)return @"";
    return comments;
}

- (void) setComments:(NSString*)aComments
{
	if(!aComments)aComments = @"";
    //[[[self undoManager] prepareWithInvocationTarget:self] setComments:comments];
    
    [comments autorelease];
    comments = [aComments copy];    
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelCommentsChanged object:self];
}

- (void) setCommentsNoNote:(NSString*)aString
{
	if(!aString)aString= @"";
    [comments autorelease];
    comments = [aString copy];	
}

- (BOOL) showSuperClass
{
    return showSuperClass;
}

- (void) setShowSuperClass:(BOOL)aShowSuperClass
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowSuperClass:showSuperClass];
    showSuperClass = aShowSuperClass;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelShowSuperClassChanged object:self];
}

- (NSString*) lastFile
{
	if(!lastFile)return @"";
	else return lastFile;
}

- (void) setLastFile:(NSString*)aFile
{
	if(!aFile)aFile = [[NSHomeDirectory() stringByAppendingPathComponent:@"Untitled"] stringByExpandingTildeInPath];
	[[[self undoManager] prepareWithInvocationTarget:self] setLastFile:lastFile];
    [lastFile autorelease];
    lastFile = [aFile copy];		
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelLastFileChangedChanged object:self];
}

- (NSString*) script
{
	if(!script)return @"";
	return script;
}

- (void) setScript:(NSString*)aString
{
	if(!aString)aString= @"";
    //[[[self undoManager] prepareWithInvocationTarget:self] setScript:script];
    [script autorelease];
    script = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelScriptChanged object:self];
}

- (void) setScriptNoNote:(NSString*)aString
{
	if(!aString)aString= @"";
    [script autorelease];
    script = [aString copy];	
}

- (NSString*) scriptName
{
	if(!scriptName)return @"ORCAScript";
	return scriptName;
}

- (void) setScriptName:(NSString*)aString
{
	if(!aString)aString = @"OrcaScript";
    [[[self undoManager] prepareWithInvocationTarget:self] setScriptName:scriptName];
    [scriptName autorelease];
    scriptName = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelNameChanged object:self];
	[self setUpImage];
}

- (NSString*) identifier
{
    if([[self scriptName] isEqualToString:@"OrcaScript"])return [NSString stringWithFormat:@"%@ %u",[self scriptName],[self uniqueIdNumber]];
    else return [self scriptName];
}

- (NSMutableArray*) inputValues
{
	return inputValues;
}

- (void) addInputValue
{
	if(!inputValues)inputValues = [[NSMutableArray array] retain];
	[inputValues addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							[NSString stringWithFormat:@"$%d",(int)[inputValues count]],	@"name",
							[NSDecimalNumber numberWithUnsignedLong:0],				@"iValue",
							nil]];
	
}

- (void) removeInputValue:(NSUInteger)i
{
	[inputValues removeObjectAtIndex:i];
}



#pragma mark ***Script Methods
- (BOOL) suppressStartStopMessage
{
	return [scriptRunner suppressStartStopMessage];
}

- (void) setSuppressStartStopMessage:(BOOL)aState
{
	[scriptRunner setSuppressStartStopMessage:aState];
}

- (id) inputValue
{
	return inputValue;
}

- (void) setInputValue:(id)aValue
{
	[aValue retain];
	[inputValue release];
	inputValue = aValue;
}

- (ORScriptRunner*) scriptRunner
{
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	return scriptRunner;
}

- (BOOL) parsedOK
{
	return parsedOK;
}

- (BOOL) scriptExists
{
	return scriptExists;
}

- (void) parseScript
{
	parsedOK = YES;
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	if(![scriptRunner running]){
		[scriptRunner setScriptName:scriptName];
        NSLog(@"==================================\n");
        NSLog(@"Parse check for %@\n",scriptName);
		[scriptRunner parse:script];
		parsedOK = [scriptRunner parsedOK];
		scriptExists = [scriptRunner scriptExists];
        [scriptRunner printAll];
        if(parsedOK)NSLog(@"%@ Parsed OK\n",scriptName);
	}
}
- (BOOL) runScript
{
	return [self runScriptWithMessage:@""];
}

- (void) postCouchDBRecord:(NSDictionary*)aRecord
{
    NSMutableDictionary* values = [NSMutableDictionary dictionaryWithDictionary:aRecord];
    [values setObject:scriptName forKey:@"scriptName"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}

- (void) postCouchDBRecordToHistory:(NSDictionary*)aRecord
{
    NSMutableDictionary* values;
    if(aRecord) values = [NSMutableDictionary dictionaryWithDictionary:aRecord];
    else        values = [NSMutableDictionary dictionary];
    [values setObject:@"Scripts" forKey:@"title"];
    if([values objectForKey:@"scriptName"]==nil) [values setObject:scriptName forKey:@"scriptName"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddHistoryAdcRecord" object:self userInfo:values];
}

- (BOOL) runScriptWithMessage:(NSString*) startMessage
{
	parsedOK = YES;
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	if(![scriptRunner running]){
		[scriptRunner setScriptName:scriptName];
		[scriptRunner setInputValue:inputValue];
		[scriptRunner parse:script];
		parsedOK = [scriptRunner parsedOK];
		if(parsedOK){
			if([scriptRunner scriptExists]){
				[scriptRunner setFinishCallBack:self selector:@selector(scriptRunnerDidFinish:returnValue:)];
				if([scriptRunner debugging]){
					[scriptRunner setBreakpoints:[self breakpointSet]];
				}
				[scriptRunner setDebugMode:kRunToBreakPoint];
				[self shipTaskRecord:self running:YES];
				if([startMessage length]>0){
					NSLog(@"%@\n",startMessage);
				}
				[scriptRunner run:inputValues sender:self];
			}
			else {
				[self scriptRunnerDidFinish:YES returnValue:[NSNumber numberWithInt:1]];
			}
		}
	}
	else {
		[scriptRunner stop];
	}
	return parsedOK;
}

- (void) stopScript
{
	if([scriptRunner running] || (nextPeriodicRun!=nil)){
		[self setNextPeriodicRun:nil];
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		if(runPeriodically)NSLog(@"[%@] Manually stopped. Will not repeat.\n",[self identifier]);
		if([scriptRunner running]){
			[scriptRunner stop];
		}
	}
}

- (id) nextScriptConnector
{
	//default is nil. If subclasses use the breakchain variable and have a chain of scripts they can override
	return nil;
}

- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue
{	
	[self setInputValue:nil];
	if(normalFinish && !breakChain){
		if([self nextScriptConnector]){
			ORScriptIDEModel* nextScriptTask =  [self objectConnectedTo: [self nextScriptConnector]];
			[nextScriptTask setInputValue:aValue];
			[nextScriptTask runScript];
		}
	}
	if(normalFinish){
		if(![scriptRunner suppressStartStopMessage]){
			NSLog(@"[%@] Returned with: %@\n",[self identifier],aValue);
		}
	}
	else NSLogColor([NSColor redColor],@"[%@] Abnormal exit!\n",[[self scriptRunner] scriptName]);

	[self shipTaskRecord:self running:NO];
	
	if(runPeriodically){
		[self scheduleNextPeriodicRun];
	}
}

- (BOOL) running
{
	return [scriptRunner running] || nextPeriodicRun;
}

- (void) loadScriptFromFile:(NSString*)aFilePath
{
	[self setLastFile:aFilePath];
	NSString* theContents = [[[NSString alloc] initWithContentsOfFile:[lastFile stringByExpandingTildeInPath] encoding:NSUTF8StringEncoding error:nil] autorelease];
	//NSString* theContents = [NSString stringWithContentsOfFile:[lastFile stringByExpandingTildeInPath]];
	//if the name and description are prepended then strip off and restore
	//the name is always first if it exists
	if([theContents hasPrefix:@"//#Name:"]){
		NSUInteger eofLoc = [theContents rangeOfString:@"\n"].location;
		NSString* theName = [theContents substringToIndex:eofLoc];
		theContents = [theContents substringFromIndex:eofLoc+1];
		theName = [theName substringFromIndex:[theName rangeOfString:@":"].location+1];
		if(theName)[self setScriptName:theName];
	}
	else [self setScriptName:@"OrcaScript"];
	//the description comment is always second if it exists
	if([theContents hasPrefix:@"//#Comments:"]){
		NSUInteger eofLoc = [theContents rangeOfString:@"\n"].location;
		NSString* theComments = [theContents substringToIndex:eofLoc];
		theContents = [theContents substringFromIndex:eofLoc+1];
		theComments = [theComments substringFromIndex:[theComments rangeOfString:@":"].location+1];
		if(theComments)[self setComments:theComments];
		else [self setComments:@""];
	}
	else [self setComments:@""];
	
	//next the globals
	[inputValues release];
	inputValues = [[NSMutableArray array] retain];
	
	do {
		if([theContents hasPrefix:@"//#Global:"]){
			NSUInteger eofLoc = [theContents rangeOfString:@"\n"].location;
			NSString* theLine = [theContents substringToIndex:eofLoc];
			theContents = [theContents substringFromIndex:eofLoc+1];
			theLine = [theLine substringFromIndex:[theLine rangeOfString:@":"].location+1];
			if(theLine){
				NSArray* theParts = [theLine componentsSeparatedByString:@" "];
				if([theParts count] == 2){
					NSDictionary* d = [NSMutableDictionary dictionaryWithObjectsAndKeys:
															[NSString stringWithFormat:@"%@",[theParts objectAtIndex:0]],@"name",
															[NSDecimalNumber decimalNumberWithString:[theParts objectAtIndex:1]],@"iValue",
															 nil];
					[inputValues addObject:d];
				}
			}
		}
		else break;
	} while(1);
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelGlobalsChanged object:self];

	[self setScript: theContents];
}

- (void) saveFile
{
	[self saveScriptToFile:lastFile];
}

- (void) saveScriptToFile:(NSString*)aFilePath
{
	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:[aFilePath stringByExpandingTildeInPath]]){
		[fm removeItemAtPath:[aFilePath stringByExpandingTildeInPath] error:nil];
	}
	NSMutableString* theScript = [script mutableCopy];
	//prepend the globals
	NSEnumerator* e = [inputValues reverseObjectEnumerator];
	NSDictionary* aGlobal;
	while(aGlobal = [e nextObject]){
		[theScript insertString:[NSString stringWithFormat:@"//#Global:%@ %@\n",[aGlobal objectForKey:@"name"],[aGlobal objectForKey:@"iValue"]] atIndex:0];
	}
	//prepend the name and description
	if([[self comments] length]){
		[theScript insertString:[NSString stringWithFormat:@"//#Comments:%@\n",[[self comments]removeNLandCRs]] atIndex:0];
	}
	if([[self scriptName] length]){
		[theScript insertString:[NSString stringWithFormat:@"//#Name:%@\n",[[self scriptName] removeNLandCRs]] atIndex:0];
	}
	else {
		[theScript insertString:@"//#Name:OrcaScript\n" atIndex:0];
	}
    if(![theScript canBeConvertedToEncoding:NSUTF8StringEncoding])NSLog(@"Can not convert\n");
	NSData* theData = [theScript dataUsingEncoding:NSUTF8StringEncoding];
	BOOL result = [fm createFileAtPath:[aFilePath stringByExpandingTildeInPath] contents:theData attributes:nil];
	if(result)[self setLastFile:aFilePath];
    else NSLogColor([NSColor redColor], @"Unable to save <%@> Reason unknown\n",aFilePath);
	[theScript release];
}

//functions for testing script objC calls
- (float) testNoArgFunc											{ return 1.1; }
- (float) testOneArgFunc:(float)aValue							{ return aValue; }
- (float) testTwoArgFunc:(float)aValue argTwo:(float)aValue2	{ return aValue + aValue2; }
- (NSString*) testFuncStringReturn								{ return @"PASSED";}
- (NSPoint) testFuncPointReturn:(NSPoint)aPoint					{ return aPoint; }
- (NSRect) testFuncRectReturn:(NSRect)aRect						{ return aRect; }

#pragma mark ***Data ID
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}
- (uint32_t) recordDataId { return recordDataId; }
- (void) setRecordDataId: (uint32_t) aDataId
{
    recordDataId = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId        = [assigner assignDataIds:kLongForm];
    recordDataId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
    [self setRecordDataId:[anotherObj recordDataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORScriptDecoderForState",		@"decoder",
								 [NSNumber numberWithLong:dataId],	@"dataId",
								 [NSNumber numberWithBool:NO],      @"variable",
								 [NSNumber numberWithLong:4],       @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"State"];
  
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORScriptDecoderForRecord",			@"decoder",
								 [NSNumber numberWithLong:recordDataId],	@"dataId",
								 [NSNumber numberWithBool:YES],				@"variable",
								 [NSNumber numberWithLong:-1],				@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Record"];
	
	
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORCAScript"];
    
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
	if(inputValues) [objDictionary setObject:inputValues forKey:@"inputValues"];
    if(scriptName)  [objDictionary setObject:scriptName forKey:@"scriptName"];
    if(lastFile) [objDictionary setObject:lastFile forKey:@"lastFile"];
    [dictionary setObject:objDictionary forKey:@"Script"];
	return objDictionary;
}

- (int) scriptType
{
	short scriptType = 0;
	if([self class] == NSClassFromString(@"ORRunScriptModel"))scriptType = 1;
	else if([self class] == NSClassFromString(@"ORScriptTaskModel"))scriptType = 2;
	return scriptType;
}

- (void) shipTaskRecord:(id)aTask running:(BOOL)aState
{
    if([gOrcaGlobals runRunning]){
		
		//get the time(UT!)
		time_t	ut_time;
		time(&ut_time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		//time_t ut_time = mktime(theTimeGMTAsStruct); //seconds since 1970
		
		uint32_t data[4];		
		data[0] = dataId | 4; 
		data[1] = ([self scriptType]&0xf)<<24 | [self uniqueIdNumber]; 
		data[2] = (uint32_t)ut_time;
		data[3] = aState;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(int32_t)*4]];
    }
}

- (void) shipDataRecord:(id)someData tag:(uint32_t)anID
{
    if([gOrcaGlobals runInProgress]){
		if([someData respondsToSelector:@selector(description)]){
			id plist = nil;
			//this just wrapps the data in a top level dictionary to make it easy for orca root decoders
			someData = [NSDictionary dictionaryWithObject:someData	forKey:@"DataRecord"];

            plist = [NSPropertyListSerialization dataWithPropertyList:someData
                                                               format:NSPropertyListXMLFormat_v1_0
                                                              options:NSPropertyListImmutable
                                                                error:nil];
			
			
			if([plist length]){
				//get the time(UT!)
				time_t	theTime;
				time(&theTime);
				struct tm* theTimeGMTAsStruct = gmtime(&theTime);
				time_t ut_time = mktime(theTimeGMTAsStruct);
				
				NSMutableData*  theRecord = [NSMutableData dataWithCapacity:1024];
				uint32_t data[5];
				data[0] = recordDataId | (uint32_t)(5 + ([plist length]+3)/4) ;
				data[1] = ([self scriptType]&0xf)<<24 | [self uniqueIdNumber]; 
				data[2] = (uint32_t)ut_time;	//seconds since 1970
				data[3] = anID;
				data[4] = (uint32_t)[plist length];
				
				[theRecord appendBytes:data length:sizeof(int32_t) * 5];
				[theRecord appendData:plist];
				int pad = [plist length]%4;
				if(pad){
					uint32_t padWord = 0;
					[theRecord appendBytes:&padWord length:4-pad]; //pad to nearest int32_t
				}
				[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																	object:theRecord];
			}
		}
	}
}
- (id)   temporaryObjectWithKey:(id)aKey
{
    return [temporaryStore objectForKey:aKey];
}

- (void) setTemporaryObject:(id)anObj forKey:(id)aKey
{
    if(!temporaryStore){
        temporaryStore = [[NSMutableDictionary dictionary] retain];
    }
    [temporaryStore setObject:anObj forKey:aKey];
}

- (id)   storedObjectWithKey:(id)aKey
{
    return [persistantStore objectForKey:aKey];
}

- (void) setStoredObject:(id)anObj forKey:(id)aKey
{
    if(!persistantStore){
        persistantStore = [[NSMutableDictionary dictionary] retain];
    }
    [persistantStore setObject:anObj forKey:aKey];
}

- (void) clearStoredObjects
{
    [persistantStore release];
    persistantStore = nil;
}
#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
    persistantStore             = 	[[decoder decodeObjectForKey:@"persistantStore"] retain];
    [self setPeriodicRunInterval:	[decoder decodeIntForKey:@"periodicRunInterval"]];
    [self setRunPeriodically:		[decoder decodeBoolForKey:@"runPeriodically"]];
    [self setAutoRunAtQuit:			[decoder decodeBoolForKey:@"autoRunAtQuit"]];
    [self setShowCommonOnly:		[decoder decodeBoolForKey:@"showCommonOnly"]];
    [self setShowSuperClass:		[decoder decodeBoolForKey:@"showSuperClass"]];
    [self setAutoStopWithRun:		[decoder decodeBoolForKey:@"autoStopWithRun"]];
    [self setAutoStartWithRun:		[decoder decodeBoolForKey:@"autoStartWithRun"]];
    [self setAutoStartWithDocument:	[decoder decodeBoolForKey:@"autoStartWithDocument"]];
	[self setBreakChain:			[decoder decodeBoolForKey:@"breakChain"]];
	[self setComments:				[decoder decodeObjectForKey:@"comments"]];
    [self setScript:				[decoder decodeObjectForKey:@"script"]];
    [self setScriptName:			[decoder decodeObjectForKey:@"scriptName"]];
    [self setLastFile:				[decoder decodeObjectForKey:@"lastFile"]];
	[self setBreakpoints:			[decoder decodeObjectForKey:@"breakpoints"]];
    inputValues = [[decoder decodeObjectForKey:@"inputValues"] retain];	
    [[self undoManager] enableUndoRegistration];
	
	[self registerNotificationObservers];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:persistantStore       forKey:@"persistantStore"];
    [encoder encodeInteger:periodicRunInterval      forKey:@"periodicRunInterval"];
    [encoder encodeBool:runPeriodically         forKey:@"runPeriodically"];
    [encoder encodeBool:autoRunAtQuit           forKey:@"autoRunAtQuit"];
    [encoder encodeBool:showCommonOnly			forKey:@"showCommonOnly"];
    [encoder encodeBool:showSuperClass			forKey:@"showSuperClass"];
    [encoder encodeBool:autoStopWithRun			forKey:@"autoStopWithRun"];
    [encoder encodeBool:autoStartWithRun		forKey:@"autoStartWithRun"];
    [encoder encodeBool:autoStartWithDocument	forKey:@"autoStartWithDocument"];
    [encoder encodeBool:breakChain				forKey:@"breakChain"];
    [encoder encodeObject:comments				forKey:@"comments"];
    [encoder encodeObject:script				forKey:@"script"];
    [encoder encodeObject:scriptName			forKey:@"scriptName"];
    [encoder encodeObject:inputValues			forKey:@"inputValues"];
    [encoder encodeObject:lastFile				forKey:@"lastFile"];
    // comment out because this throws an exception if the config contains breakpoints! - PH
    //[encoder encodeObject:breakpoints			forKey:@"breakpoints"];
}

- (uint32_t) currentTime
{
	return [NSDate timeIntervalSinceReferenceDate];
}
@end


/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length (fixed at 4)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^------------------------------------ Script Type 1==RunScript 2==TaskScript
 -----------------------------------^^^^- Script Object ID number
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Unix Time (seconds from 1970)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Script state 1==started. 0==stopped
*/

@implementation ORScriptDecoderForState
- (uint32_t) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t value = *((uint32_t*)someData);
    return ExtractLength(value);
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"ORCA Script\n";
	int theObjID = ptr[1] & 0xff;
	int scriptType = (ptr[1]>>24) & 0xff;
	NSString* typeString;
	if(scriptType == 1)			typeString = @"ORRunScriptModel";
	else if(scriptType == 2)	typeString = @"ORScriptTaskModel";
	else						typeString = @"ID"; //should never use this one if all types defined.
	
    NSString* state = [NSString stringWithFormat:@"%@,%d %@\n",typeString,theObjID,ptr[3]?@"Started":@"Stopped"];
	
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:ptr[2]];
    return [NSString stringWithFormat:@"%@%@%@\n",title,state,[date descriptionFromTemplate:@"MM/dd/yy HH:mm:ss %z"]];
}

@end

@implementation ORScriptIDEModel (private)
- (void) scheduleNextPeriodicRun
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(runScript) withObject:nil afterDelay:periodicRunInterval];
	[self setNextPeriodicRun:[[NSDate date] dateByAddingTimeInterval:periodicRunInterval]];
}

@end

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^------------------------------------ Script Type 1==RunScript 2==TaskScript
 -----------------------------------^^^^- Script Object ID number
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Unix Time (seconds from 1970)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -An Arbitrary data tag (User specified)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -length of xml data in bytes
 ...
 XML data follows									
 ...
 */

@implementation ORScriptDecoderForRecord
- (uint32_t) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t value = *((uint32_t*)someData);
    return ExtractLength(value);
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"ORCA Script Record\n";
	int theObjID = ptr[1] & 0xff;
	int scriptType = (ptr[1]>>24) & 0xff;
	NSString* typeString;
	if(scriptType == 1)			typeString = @"ORRunScriptModel";
	else if(scriptType == 2)	typeString = @"ORScriptTaskModel";
	else						typeString = @"ID"; //should never use this one if all types defined.
    NSString* idString = [NSString stringWithFormat:@"%@,%d id: %u\n",typeString,theObjID,ptr[3]];
	
	NSPropertyListFormat format;
	NSData *plistXML = [NSData dataWithBytes:&ptr[5] length:ptr[4]];
	id result = [NSPropertyListSerialization
                        propertyListWithData:plistXML
                        options:NSPropertyListMutableContainersAndLeaves
                        format:&format
                        error:nil];
	
	
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:ptr[2]];	
    return [NSString stringWithFormat:@"%@%@%@Data:%@",title,[date descriptionFromTemplate:@"MM/dd/yy HH:mm:ss z\n"],idString,result];
}
@end


