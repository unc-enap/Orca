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
#import "ORRunScriptModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORScriptRunner.h"

NSString* ORRunScriptSlotChangedNotification = @"ORRunScriptSlotChangedNotification";

@implementation ORRunScriptModel

- (NSString*) helpURL
{
	return @"Data_Chain/Run_Scripts.html";
}

#pragma mark ***Initialization
- (void) registerNotificationObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORScriptRunnerRunningChanged
						object: nil];	
}

- (void) runningChanged:(NSNotification*)aNote
{
	[self setUpImage];
}

- (void) setUpImage
{
	
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"RunScript"];
	
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
	NSSize imageSize = [aCachedImage size];
	NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont labelFontOfSize:12], NSFontAttributeName,
								nil];		
	[[self identifier] drawInRect:NSMakeRect(30,-4, imageSize.width,imageSize.height) 
				   withAttributes:attributes];

	if([self running]){
		NSImage* runningImage = [NSImage imageNamed:@"ScriptRunning"];
		[runningImage setSize:NSMakeSize(40,40)];
		NSSize imageSize = [runningImage size];
		NSSize ourSize = [self frame].size;
        [runningImage drawAtPoint:NSMakePoint(ourSize.width - imageSize.width,-16) fromRect:[runningImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];        
    }
	
	[i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
}


- (void) setUniqueIdNumber:(uint32_t)anIdNumber
{
	[super setUniqueIdNumber:anIdNumber];
	[self setUpImage];
}

- (void) runOKSelectorNow
{
    if(selectorOK)[target performSelector:selectorOK withObject:anArg];
    selectorOK  = nil;
    selectorBAD = nil;
    [anArg release];
    anArg = nil;
    [target release];
    target = nil;
}

- (void) setSelectorOK:(SEL)aSelectorOK bad:(SEL)aSelectorBAD withObject:(id)anObject target:(id)aTarget
{
	selectorOK	= aSelectorOK;
	selectorBAD	= aSelectorBAD;
	anArg		= [anObject retain];
	target		= [aTarget retain];
}

- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue
{
	[super scriptRunnerDidFinish:normalFinish returnValue:aValue];
	if(normalFinish){
		if([aValue intValue]!=0) {
			if(selectorOK)[target performSelector:selectorOK withObject:anArg];
		}
		else {
			if(selectorBAD)[target performSelector:selectorBAD withObject:anArg];
		}
	}
	else {
		if(selectorBAD)[target performSelector:selectorBAD withObject:anArg];
	}
	[anArg release];
	anArg = nil;
	[target release];
	target = nil;
}

- (BOOL) runScript
{
    if([[self script] rangeOfString:@"startRun"].location != NSNotFound){
        NSLogColor([NSColor redColor], @"Explicit run control not allowed in script: [%@]. It will lead to infinite recursion. Start the run by other means.\n",[self scriptName]);
        
        return NO;
    }
    if([[self script] rangeOfString:@"stopRun"].location != NSNotFound){
        NSLogColor([NSColor redColor], @"Explicit run control not allowed in script: [%@]. Have the script return FALSE to abort the run start up process.\n",[self scriptName]);
        return NO;
    }
    return [super runScript];
}

- (int) slot
{
    return slot;
}
- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    slot = aSlot;
    [self setTag:aSlot];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunScriptSlotChangedNotification
	 object: self];
}

- (int)selectionIndex
{
    return selectionIndex;
}
- (void) setSelectionIndex:(int)anIndex
{
    selectionIndex = anIndex;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	[self registerNotificationObservers];
    [self setSlot:[decoder decodeIntForKey:@"slot"]];
    return self;
}
- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:[self slot] forKey:@"slot"];
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
	return	[super acceptsGuardian:aGuardian] ||
    [aGuardian isMemberOfClass:NSClassFromString(@"ORRunModel")];
}

- (NSComparisonResult)compare:(ORRunScriptModel *)otherObject
{
    return [self slot] - [otherObject slot];
}

@end

