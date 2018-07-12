//
//  ORAutoTester.mh
//  Orca
//
//  Created by Mark Howe on Sat Dec 28 2002.
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

#import "ORAutoTester.h"
#import "ORGroup.h"
#import "AutoTesting.h"
#import "SynthesizeSingleton.h"
#import "ORVmeTests.h"

NSString*  AutoTesterLock						= @"AutoTesterLock";
NSString*  ORAutoTesterRepeatNotification		= @"ORAutoTesterRepeatNotification";
NSString*  ORAutoTesterRepeatCountNotification	= @"ORAutoTesterRepeatCountNotification";

@interface ORAutoTester (private)
- (void) runTestThread:(NSArray*)objectsToTest;
- (void) testIsStopped;
- (void) testIsRunning;
@end

@implementation ORAutoTester

SYNTHESIZE_SINGLETON_FOR_ORCLASS(AutoTester);

- (id)init
{
    self = [super initWithWindowNibName:@"AutoTester"];
	resultLock = [[NSLock alloc] init];
    return self;
}

- (void) dealloc
{
	//we are a singleton, so we should never get here. But this prevents some warnings in
	//the 10.6 static analysis builds
	[testResults release];
	[resultLock release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
	[totalListView reloadData];
	[totalListView setAction:@selector(tableClick:)];
	[self repeatChanged:nil];
	[self repeatCountChanged:nil];
	[self securityStateChanged:nil];
	[self runStatusChanged:nil];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [(ORAppDelegate*)[NSApp delegate]  undoManager];
}

- (BOOL) repeat
{
	return repeat;
}

- (void) setRepeat:	(BOOL)aValue
{
    repeat = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAutoTesterRepeatNotification object:self];
}

- (int) repeatCount
{
	if(repeatCount == 0)repeatCount = 1;
	return repeatCount;
}

- (void) setRepeatCount:(int)aValue
{
    repeatCount = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAutoTesterRepeatCountNotification object:self];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : AutoTesterLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(securityStateChanged:)
                         name : ORGlobalSecurityStateChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(repeatChanged:)
                         name : ORAutoTesterRepeatNotification
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(repeatCountChanged:)
                         name : ORAutoTesterRepeatCountNotification
                        object: nil];
	
	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
}

- (void) repeatChanged:(NSNotification*)aNote
{
	[repeatCB setIntValue:[self repeat]];
	[repeatCountField setEnabled:repeat?YES:NO];
}

- (void) repeatCountChanged:(NSNotification*)aNote
{
	[repeatCountField setIntValue:[self repeatCount]];
}

- (void) runStatusChanged:(NSNotification*)aNote
{
	[runTestsButton setEnabled:![gOrcaGlobals runInProgress] && [[totalListView allSelectedItems] count]!=0];
}

- (void) objectsChanged:(NSNotification*)aNote
{
	[totalListView reloadData];
}

- (void) securityStateChanged:(NSNotification*)aNote
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:AutoTesterLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:AutoTesterLock];
	[lockButton setState: locked];

	[runTestsButton setEnabled: !locked && [[totalListView allSelectedItems] count]!=0];
	[stopTestsButton setEnabled:!locked && [gOrcaGlobals testInProgress]];
	[totalListView setEnabled: !locked];
}

- (IBAction) runTest:(id)sender
{
	if(!testsRunning){
		if(![[self window] makeFirstResponder:[self window]]){
			[[self window] endEditingFor:nil];		
		}
		[testResults removeAllObjects];
		id objectsToTest = [totalListView allSelectedItems];
		for(id obj in objectsToTest){
			[self setTestResult:@"Waiting" forObject:obj];
		}
		[NSThread detachNewThreadSelector:@selector(runTestThread:) toTarget:self withObject:[totalListView allSelectedItems]];
	}
}

- (IBAction) tableClick:(id)sender
{
	if(sender == totalListView){
		[runTestsButton setEnabled:[[totalListView allSelectedItems] count]!=0];
	}
}

- (IBAction) stopTests:(id)sender
{
	stopTesting  = YES;
}

- (BOOL) stopTests
{
	return stopTesting;
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:AutoTesterLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) repeatAction:(id)sender
{
	[self setRepeat:[sender intValue]];
}

- (IBAction) repeatCountAction:(id)sender
{
	[self setRepeatCount:[sender intValue]];
}


#pragma mark •••Delegate Methods
- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item
{
	if([item conformsToProtocol:@protocol(AutoTesting)])return YES;
	else return NO;		
}

#pragma mark •••Data Source Methods

#define GET_CHILDREN NSArray* children; \
if(!item) children = [[[[(ORAppDelegate*)[NSApp delegate] document] group] orcaObjects] sortedArrayUsingSelector:@selector(sortCompare:)]; \
else if([item respondsToSelector:@selector(orcaObjects)])children = [[item orcaObjects]sortedArrayUsingSelector:@selector(sortCompare:)]; \
else children = nil;\

- (BOOL) outlineView:(NSOutlineView*)ov isItemExpandable:(id)item 
{
	GET_CHILDREN; //macro: given an item, sets children array and guardian.
	if(!children || ([children count] < 1)) return NO;
	return YES;
}

- (NSUInteger)  outlineView:(NSOutlineView*)ov numberOfChildrenOfItem:(id)item
{
	GET_CHILDREN; //macro: given an item, sets children array and guardian.
	return [children count];
}

- (id)   outlineView:(NSOutlineView*)ov child:(int)index ofItem:(id)item
{
	GET_CHILDREN; //macro: given an item, sets children array and guardian.
	if(!children || ([children count] <= index)) return nil;
	return [children objectAtIndex:index];
}

- (id)   outlineView:(NSOutlineView*)ov objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
	if([[tableColumn identifier] isEqualToString:@"isAutoTester"]){
		if([item conformsToProtocol:@protocol(AutoTesting)])return @"YES";
		else return @"NO";
	}
	else if([[tableColumn identifier] isEqualToString:@"results"]){
		if([item conformsToProtocol:@protocol(AutoTesting)])return [self testResultForObject:item];
		else return @" ";
	}
	else return [item valueForKey:[tableColumn identifier]];
}

- (void) setTestResult:(id)aResult forObject:(id)anObj
{
	[resultLock lock];
	@try {
		if(!testResults)testResults = [[NSMutableDictionary alloc] init];
		[testResults setObject:aResult forKey:[anObj fullID]];
	}
	@catch(NSException* e){
	}
	@finally {
		[resultLock unlock];
	}
	[totalListView reloadData];
}

- (id) testResultForObject:(id)anObj
{
	id theResult;
	@try {
		[resultLock lock];
		theResult = [testResults objectForKey:[anObj fullID]];
	}
	@catch(NSException* e)
	{
	}
	@finally {
		[resultLock unlock];
	}
	return theResult;
}
@end

@implementation ORAutoTester (private)
- (void) runTestThread:(NSArray*)objectsToTest
{
	NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
		
	[[objectsToTest retain] autorelease];
	
	stopTesting  = NO;
	[self performSelectorOnMainThread:@selector(testIsRunning) withObject:nil waitUntilDone:YES];
	int i;
	int numberTimesToRepeat;
	if(repeat)numberTimesToRepeat = repeatCount;
	else numberTimesToRepeat = 1;
	int failCount=0;
	for(id obj in objectsToTest){
		[self setTestResult:@"Running" forObject:obj];
		for(i=0;i<numberTimesToRepeat;i++){
			NSAutoreleasePool* innerPool = [[NSAutoreleasePool alloc] init];
			NSArray* theTests = [obj autoTests];
			for(id aTest in theTests){
				if(stopTesting)break;
				[aTest runTest:obj];
				NSArray* failureLog = [aTest failureLog];
				if(failureLog){
					NSLog(@"%@:  %@ %@\n",[obj fullID], [aTest name],failureLog);
					failCount++;
				}
			}
			[innerPool release];
			if(stopTesting)break;
		}
	
		if(stopTesting){
			[self setTestResult:@"Stopped" forObject:obj];
			NSLog(@"Testing stopped manually\n");
		}
		else if(failCount==0){
			NSLog(@"%@: PASSED ALL\n",[obj fullID]);
			[self setTestResult:@"PASSED" forObject:obj];
		}
		else {
			[self setTestResult:@"FAILED" forObject:obj];
		}
		if(stopTesting) break;
		
	}
	[self performSelectorOnMainThread:@selector(testIsStopped) withObject:nil waitUntilDone:NO];
	[outerPool release];
}

- (void) testIsRunning
{
	[gOrcaGlobals addRunVeto:@"AutoTestinger" comment:@"Can't run while AutoTester running"];
	[gOrcaGlobals setTestInProgress:YES];
	[runTestsButton setEnabled:NO];
	[stopTestsButton setEnabled:YES];
	[repeatCB setEnabled:NO];
	[repeatCountField setEnabled:NO];
}

- (void) testIsStopped
{
	[runTestsButton setEnabled:[[totalListView allSelectedItems] count]!=0];
	[stopTestsButton setEnabled:NO];
	[gOrcaGlobals removeRunVeto:@"AutoTestinger"];
	[gOrcaGlobals setTestInProgress:NO];
	[repeatCB setEnabled:YES];
	[repeatCountField setEnabled:repeat?YES:NO];
}
@end

