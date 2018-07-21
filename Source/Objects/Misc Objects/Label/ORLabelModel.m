//
//  ORLabelModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORLabelModel.h"
#import "TimedWorker.h"
#import "ORCommandCenter.h"

NSString* ORLabelModelControllerStringChanged	 = @"ORLabelModelControllerStringChanged";
NSString* ORLabelModelTextSizeChanged			 = @"ORLabelModelTextSizeChanged";
NSString* ORLabelModelLabelChangedNotification   = @"ORLabelModelLabelChangedNotification";
NSString* ORLabelLock							 = @"ORLabelLock";
NSString* ORLabelPollRateChanged				 = @"ORLabelPollRateChanged";
NSString* ORLabelModelLabelTypeChanged			 = @"ORLabelModelLabelTypeChanged";
NSString* ORLabelModelUpdateIntervalChanged		 = @"ORLabelModelUpdateIntervalChanged";
NSString* ORLabelModelFormatChanged				 = @"ORLabelModelFormatChanged";

@implementation ORLabelModel

#pragma mark ¥¥¥initialization
- (id) init
{
    self = [super init];
    return self;
}

-(void) dealloc
{
    [controllerString release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [poller stop];
    [poller release];
	[displayValues release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
	if(labelType == kDynamicLabel){
		[poller runWithTarget:self selector:@selector(updateValue)];
	}
}

- (void) sleep
{
    [super sleep];
    [poller stop];
}

- (NSString*) helpURL
{
	return @"Subsystems/Containers_and_Dynamic_Labels.html";
}

- (NSString*) label
{
	if(!label)return @"?";
	else return label;
}

- (NSString*) elementName
{
	return @"Text Label";
}

- (int) state
{
	return 0;
}
- (NSString*) comment
{
	if(!label)return @"";
	else return label;
}

- (void) setComment:(NSString*)aComment
{
	[self setLabel:aComment];
}

- (NSString*) description:(NSString*)prefix
{
    return [NSString stringWithFormat:@"%@%@ %u",prefix,[self elementName],[self uniqueIdNumber]];
}


- (id) stateValue
{
	return 0;
}

- (NSString*) fullHwName
{
    return @"N/A";
}

- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey
{
    NSString* ourKey   = [self valueForKey:aKey];
    NSString* theirKey = [anElement valueForKey:aKey];
    if(!ourKey && theirKey)         return 1;
    else if(ourKey && !theirKey)    return -1;
    else if(!ourKey || !theirKey)   return 0;
    return [ourKey compare:theirKey];
}

- (void) makeMainController
{
    [self linkToController:@"ORLabelController"];
}

- (void) doDoubleClick:(id)sender
{
	if([controllerString length]) [self openAltDialog:self];		
    else						  [self openMainDialog:self];
}

- (void) doCmdDoubleClick:(id)sender  atPoint:(NSPoint)aPoint
{
	if([controllerString length]) [self openMainDialog:self];//TODO: I think this should be vice versa? -tb-		
    else				 [self openAltDialog:self];
}

- (void) openMainDialog:(id)sender
{
	[self makeMainController];
}

- (void) openAltDialog:(id)sender
{
	if([controllerString length]!=0){
		id obj = [[self document] findObjectWithFullID:controllerString];
		if([obj respondsToSelector:@selector(makeMainController)]){
			[obj makeMainController];
		}
	}
	else [self makeMainController];

}

#pragma mark ***Accessors

- (NSString*) controllerString
{
	if(!controllerString)return @"";
    else return controllerString;
}

- (void) setControllerString:(NSString*)aControllerString
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControllerString:controllerString];
    
    [controllerString autorelease];
    controllerString = [aControllerString copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelControllerStringChanged object:self];
}

- (int) updateInterval
{
	return updateInterval;
}

- (void) setUpdateInterval:(int) anInterval
{
	if(anInterval==0)anInterval = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setUpdateInterval:updateInterval];
	updateInterval = anInterval;
	if(labelType == kDynamicLabel){
		[self setPollingInterval:updateInterval];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelUpdateIntervalChanged object:self];
}

- (int) textSize
{
    return textSize;
}

- (void) setTextSize:(int)aTextSize
{
	if(aTextSize==0)aTextSize = 16;
	else if(aTextSize<9)aTextSize = 9;
	else if(aTextSize>36)aTextSize = 36;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setTextSize:textSize];
    
    textSize = aTextSize;
	
    [self setUpImage];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelTextSizeChanged object:self];

}

- (void) setLabel:(NSString*)aLabel
{
    
    if(![aLabel isKindOfClass:NSClassFromString(@"NSString")])aLabel = @"Bad Label";
    
    if(!aLabel)aLabel = @"Text Label";
    [[[self undoManager] prepareWithInvocationTarget:self] setLabel:label];
    
    [label autorelease];
    label = [aLabel copy];
	if(!scheduledForUpdate){
		scheduledForUpdate = YES;
		[self performSelector:@selector(setUpImage) withObject:nil afterDelay:1];
	}
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORLabelModelLabelChangedNotification
                              object:self];
}

- (void) setLabelNoNotify:(NSString*)aLabel
{
    if(!aLabel)aLabel = @"Text Box";
    [label autorelease];
    label = [aLabel copy];
    [self setUpImage];
}

- (void) setFormatNoNotify:(NSString*)aFormat
{
    if(!aFormat)aFormat = @"Text Box";
    [displayFormat autorelease];
    displayFormat = [aFormat copy];
    [self setUpImage];
}


- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian isMemberOfClass:NSClassFromString(@"ORGroup")]           || 
			[aGuardian isMemberOfClass:NSClassFromString(@"ORProcessModel")]	||
            [aGuardian isMemberOfClass:NSClassFromString(@"ORContainerModel")];
}


- (void) setUpImage
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setUpImage) object:nil];

    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each Label can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
	if(label){
		NSAttributedString* n = [self stringToDisplay:NO];
		if([n length] == 0)n = [[[NSMutableAttributedString alloc] initWithString:@"Text Label" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																												[NSFont fontWithName:@"Monaco" size:textSize],NSFontAttributeName,nil]] autorelease];
		NSSize theSize = [n size];

		NSImage* i = [[NSImage alloc] initWithSize:theSize];
		[i lockFocus];
		
		[n drawInRect:NSMakeRect(0,0,theSize.width,theSize.height)];
		[i unlockFocus];
		[self setImage:i];
		[i release];
    }
	else {
		[self setImage:[NSImage imageNamed:@"Label"]];
	}
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];
	scheduledForUpdate = NO;
}

- (void) setImage:(NSImage*)anImage
{
	[super setImage:anImage];
	if(anImage){
		[highlightedImage release];
		highlightedImage = [[NSImage alloc] initWithSize:[anImage size]];
		[highlightedImage lockFocus];
		NSAttributedString* n = [self stringToDisplay:YES];
		NSSize theSize = [n size];
		[n drawInRect:NSMakeRect(0,0,theSize.width,theSize.height)];
		[highlightedImage unlockFocus];
	}
}


- (int) labelType
{
	return labelType;
}

- (void) setLabelType:(int)aType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setLabelType:labelType];
	labelType = aType;
	[displayValues release];
	displayValues = nil;
	if(labelType == kDynamicLabel){
		[self setPollingInterval:updateInterval];
	}
	else {
		[self setLabel:[self label]];
		[poller stop];
		[poller release];
		poller = nil;
		[self setUpImage];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelLabelTypeChanged object:self];
}

- (NSString*) displayFormat
{
	if(!displayFormat)return @"";
	else return displayFormat;
}


- (void) setDisplayFormat:(NSString*)aFormat
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLabel:label];
    [displayFormat autorelease];
    displayFormat = [aFormat copy];
	[self setUpImage];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORLabelModelFormatChanged
	 object:self];
}

- (TimedWorker *) poller
{
    return poller; 
}

- (void) setPoller: (TimedWorker *) aPoller
{
    if(aPoller == nil){
        [poller stop];
    }
    [aPoller retain];
    [poller release];
    poller = aPoller;
}

- (void) setPollingInterval:(float)anInterval
{
    if(!poller){
        [self makePoller:(float)anInterval];
    }
    else [poller setTimeInterval:anInterval];
    
	[poller stop];
	[self updateValue];
    [poller runWithTarget:self selector:@selector(updateValue)];
}


- (void) makePoller:(float)anInterval
{
    [self setPoller:[TimedWorker TimeWorkerWithInterval:anInterval]];
}

- (void) updateValue
{
	NSMutableArray* newValues = [NSMutableArray array];;
	@try {
		NSArray* cmds = [[self label] componentsSeparatedByString:@"\n"];
		if([cmds count]>0){
			for(id aCmd in cmds){
				if([aCmd length]>0){
					id aValue = [[ORCommandCenter sharedCommandCenter] executeSimpleCommand:aCmd];
					if(aValue)	[newValues addObject:aValue];
					else		[newValues addObject:@"?"];
				}
			}
		}
		else [newValues addObject:@"?"];
	}
	@catch (NSException* e){
	}
	//check to see if any of the values are different. If not, there's not need to update
	if(!displayValues){
		displayValues = [newValues retain];
		[self setUpImage];
	}
	else if([displayValues count] != [newValues count]){
		[displayValues release];
		displayValues = [newValues retain];
		[self setUpImage];
	}
	else {
		if(![newValues isEqualToArray:displayValues]){
			[displayValues release];
			displayValues = [newValues retain];
			[self setUpImage];
		}
	}

}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setLabel:				[decoder decodeObjectForKey:@"label"]];
	[self setLabelType:			[decoder decodeIntForKey:	@"labelType"]];
    [self setDisplayFormat:		[decoder decodeObjectForKey:@"displayFormat"]];
    [self setTextSize:			[decoder decodeIntForKey:	@"textSize"]];
    [self setUpdateInterval:	[decoder decodeIntForKey:	@"updateInterval"]];
    [self setControllerString:	[decoder decodeObjectForKey:@"controllerString"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:label				forKey:@"label"];
    [encoder encodeObject:displayFormat		forKey:@"displayFormat"];
    [encoder encodeInteger:textSize				forKey:@"textSize"];
	[encoder encodeInteger:labelType			forKey:@"labelType"];
    [encoder encodeObject:controllerString	forKey:@"controllerString"];
	[encoder encodeInteger:updateInterval		forKey:@"updateInterval"];
}
- (void) doCntrlClick:(NSView*)aView
{
	NSEvent* theCurrentEvent = [NSApp currentEvent];
    NSEvent *event =  [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
                                         location:[theCurrentEvent locationInWindow]
                                    modifierFlags:NSEventModifierFlagControl // 0x100
                                        timestamp:(NSTimeInterval)0
                                     windowNumber:[theCurrentEvent windowNumber]
                                          context:nil
                                      eventNumber:0
                                       clickCount:1
                                         pressure:1];
	
    NSMenu *menu = [[NSMenu alloc] init];
	[[menu insertItemWithTitle:@"Open Label Dialog"
						action:@selector(openMainDialog:)
				 keyEquivalent:@""
					   atIndex:0] setTarget:self];
	if([controllerString length]){
		[[menu insertItemWithTitle:[NSString stringWithFormat:@"Open %@",controllerString]
							action:@selector(openAltDialog:)
					 keyEquivalent:@""
						   atIndex:0] setTarget:self];
	}
	[[menu insertItemWithTitle:@"Help"
						action:@selector(openHelp:)
				 keyEquivalent:@""
					   atIndex:1] setTarget:self];
	[menu setDelegate:self];
    [NSMenu popUpContextMenu:menu withEvent:event forView:aView];
}

- (NSAttributedString*) stringToDisplay:(BOOL)highlight
{
	NSString* s = @"";
	NSString* f;
	if(labelType == kStaticLabel){
		s = label;
	}
	else {
		int i;
		int n = (int)[displayValues count];
		NSArray* formats = [displayFormat componentsSeparatedByString:@"\n"];
		NSString* newString = @"";
		NSString* aFormat;
		for(i=0;i<n;i++){
			id displayValue = [displayValues objectAtIndex:i];
			if(i<[formats count]){
				aFormat = [formats objectAtIndex:i];
			}
			else aFormat = @"";
			if([displayValue isKindOfClass:NSClassFromString(@"NSNumber")]){
				if([aFormat length])f = aFormat;
				else f = @"%.2f";
				if([f rangeOfString:@"%@"].location != NSNotFound){
					newString = [NSString stringWithFormat:f,displayValue];
				}
				else if([f rangeOfString:@"%d"].location != NSNotFound){
					newString = [NSString stringWithFormat:f,[displayValue intValue]];
				}
				else {
					newString = [NSString stringWithFormat:f,[displayValue floatValue]];
				}
			}
			else {
				if([aFormat length])f = aFormat;
				else f = @"%@";
				newString = [NSString stringWithFormat:f,displayValue];
			}
			s = [s stringByAppendingFormat:@"%@\n",newString];
		}
		if([s hasSuffix:@"\n"])s = [s substringToIndex:[s length]-1];
	}
    NSAttributedString* n = nil;
    if([s isKindOfClass:NSClassFromString(@"NSString")]){
        if(highlight){
            n = [[NSAttributedString alloc] initWithString:[s length]?s:@"Text Label"
                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco"  size:textSize],NSFontAttributeName,
                             [NSColor colorWithCalibratedRed:.5 green:.5 blue:.5 alpha:.3],NSBackgroundColorAttributeName,nil]];
        }
        else {
            n= [[NSAttributedString alloc] initWithString:[s length]?s:@"Text Label"
                attributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Monaco" size:textSize] forKey:NSFontAttributeName]];
        }
    }

	
	return [n autorelease];
}
@end
