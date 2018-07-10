//
//  ORCmdLabelModel.m
//  Orca
//
//  Created by Mark Howe on Tuesday Apr 6,2009.
//  Copyright © 20010 University of North Carolina. All rights reserved.
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
#import "ORCmdLabelModel.h"
#import "ORCommandCenter.h"
#import "NSString+Extensions.h"
#import "NSInvocation+Extensions.h"

NSString* ORCmdLableDetailsChanged  = @"ORCmdLableDetailsChanged";

@interface ORCmdLabelModel (private)
- (NSAttributedString*) stringToDisplay:(BOOL)highlight;
- (void) setDefaults;
@end

@implementation ORCmdLabelModel

#pragma mark •••initialization
- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self setDefaults];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
	[commands release];
	[super dealloc];
}

- (void) makeMainController
{
    [self linkToController:@"ORCmdLabelController"];
}

- (void) setUpImage
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setUpImage) object:nil];
	
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each Label can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
	NSAttributedString* n = [self stringToDisplay:NO];
	if(n){
		if([n length] == 0)n = [[[NSMutableAttributedString alloc] initWithString:@"Cmd Label" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
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
		[self setImage:[NSImage imageNamed:@"CmdLabel"]];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:OROrcaObjectImageChanged object:self];
	scheduledForUpdate = NO;
}

- (NSString*) helpURL
{
	//return @"Subsystems/Containers_and_Dynamic_Labels.html";
	return nil;
}

#pragma mark ***Accessors

- (void) postDetailsChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCmdLableDetailsChanged object:self];
	[self setUpImage];
}

- (NSMutableArray*) commands
{
	return commands;
}

- (void) setCommands:(NSMutableArray*)anArray
{
	[anArray retain];
	[commands release];
	commands = anArray;
}

- (NSDictionary*) commandAtIndex:(int)index
{
	if(index < [commands count]){
		return [commands objectAtIndex:index];
	}
	else return nil;
}

- (NSUInteger) commandCount
{
	return [commands count];
}

- (BOOL) checkSyntax:(int) index
{
	BOOL syntaxOK = YES;
	if(index<[commands count]){
		id aCommand = [commands objectAtIndex:index];
		NSString* objID = [aCommand objectForKey:@"Object"];
		id obj = [[self document] findObjectWithFullID:objID];
		if(obj){
			[aCommand setObject:@"OK" forKey:@"ObjectOK"];
			NSString* s	= [aCommand objectForKey:@"SetSelector"];			
			if([obj respondsToSelector:[NSInvocation makeSelectorFromString:s]]){
				[aCommand setObject:@"OK" forKey:@"SetSelectorOK"];
			}
			else {
				syntaxOK = NO;
				[aCommand removeObjectForKey:@"SetSelectorOK"];
			}
			s	= [aCommand objectForKey:@"LoadSelector"];
			if([s length]){
				if([obj respondsToSelector:[NSInvocation makeSelectorFromString:s]]){
					[aCommand setObject:@"OK" forKey:@"LoadSelectorOK"];
				}
				else {
					syntaxOK = NO;
					[aCommand removeObjectForKey:@"LoadSelectorOK"];
				}
			}
			else [aCommand setObject:@"OK" forKey:@"LoadSelectorOK"]; //nil selector will be skipped.
		}
		else {
			syntaxOK = NO;
			[aCommand removeObjectForKey:@"ObjectOK"];
		}
	}	
	return syntaxOK;
}

- (void) executeCommand:(int) index
{
	if(index<[commands count]){
		id aCommand = [commands objectAtIndex:index];
		NSString* objID = [aCommand objectForKey:@"Object"];
		id obj = [[self document] findObjectWithFullID:objID];
		if(obj){
			BOOL goodToGo = YES;
			@try {
				NSMutableString* setterString	= [[[aCommand objectForKey:@"SetSelector"] mutableCopy] autorelease];	
				NSDecimalNumber* theValue       = [NSDecimalNumber decimalNumberWithString:[aCommand objectForKey:@"Value"]];
				SEL theSetterSelector			= [NSInvocation makeSelectorFromString:setterString];
				
				//do the setter
				NSMethodSignature*	theSignature	= [obj methodSignatureForSelector:theSetterSelector];
				NSInvocation*		theInvocation	= [NSInvocation invocationWithMethodSignature:theSignature];
				NSArray*			selectorItems	= [NSInvocation argumentsListFromSelector:setterString];
				
				[theInvocation setSelector:theSetterSelector];
				int n = [theSignature numberOfArguments];
				int i;
				int count=0;
				for(i=1;i<n;i+=2){
					if(i<[selectorItems count]){
						id theArg = [selectorItems objectAtIndex:i];
						if([theArg isEqualToString:@"$1"]){
							theArg = theValue;
						}
						[theInvocation setArgument:count++ to:theArg];
					}
				}
				[theInvocation setTarget:obj];
				[theInvocation invoke];
			}
			@catch(NSException* localException){
				goodToGo = NO;
				NSLogColor([NSColor redColor],@"%@: <%@>\n",[self fullID],[aCommand objectForKey:@"SetSelector"]);
				NSLogColor([NSColor redColor],@"Exception: %@\n",localException);
			}
			
			if(!goodToGo) return;  //possible early bailout.

			@try {
				//do the init loader
				NSMutableString*	loadString	    = [aCommand objectForKey:@"LoadSelector"];
				if([loadString length]){
					SEL					theLoadSelector	= [NSInvocation makeSelectorFromString:loadString];
					NSMethodSignature*	theSignature	= [obj methodSignatureForSelector:theLoadSelector];
					NSInvocation*		theInvocation	= [NSInvocation invocationWithMethodSignature:theSignature];
					NSArray*			selectorItems = [NSInvocation argumentsListFromSelector:loadString];
					
					[theInvocation setSelector:theLoadSelector];
					int n = [theSignature numberOfArguments];
					int count=0;
					int i;
					//load selectors shouldn't have any arguments, but just in case the user is trying something funny....
					for(i=1;i<n;i+=2){
						if(i<[selectorItems count]){
							[theInvocation setArgument:count++ to:[selectorItems objectAtIndex:i]];
						}
					}
					[theInvocation setTarget:obj];
					[theInvocation invoke];
				}
			}
			@catch(NSException* localException){
				NSLogColor([NSColor redColor],@"%@: <%@>\n",[self fullID],[aCommand objectForKey:@"LoadSelector"]);
				NSLogColor([NSColor redColor],@"Exception: %@\n",localException);
			}
		}
	}
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	[self setCommands:	[decoder decodeObjectForKey:@"commands"]];
    [[self undoManager] enableUndoRegistration];
	
	if(!commands)[self setDefaults];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject:commands	forKey:@"commands"];
}

- (void) addCommand
{
	[commands addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						 @"",@"Object",
						 @"",@"SetSelector",
						 @"Value: %.1f",@"DisplayFormat",
						 @"",@"LoadSelector",
						 @"0.0",@"Value",	
						 nil]];
	[self postDetailsChanged];
}

- (void) removeCommand:(int)index
{
	if(index<[commands count] && [commands count]>1){
		[commands removeObjectAtIndex:index];
	}
}

@end

@implementation ORCmdLabelModel (private)
- (void) setDefaults
{
	[self setCommands:[NSMutableArray array]];
	[self addCommand];
}



- (NSAttributedString*) stringToDisplay:(BOOL)highlight
{
	NSString* s = @"";
	for(id cmd in commands){
		id aValue = [cmd objectForKey:@"Value"];
		NSNumber* displayValue = [NSNumber numberWithFloat:[aValue floatValue]];
		NSString* newString = @"";
		NSString* aFormat  = [cmd objectForKey:@"DisplayFormat"];
		NSString* f;
		if([aFormat length])f = aFormat;
		else				f = @"%.2f";
		if([f rangeOfString:@"%@"].location != NSNotFound){
			newString = [NSString stringWithFormat:f,displayValue];
		}
		else if([f rangeOfString:@"%d"].location != NSNotFound){
			newString = [NSString stringWithFormat:f,[displayValue intValue]];
		}
		else {
			newString = [NSString stringWithFormat:f,[displayValue floatValue]];
		}
		s = [s stringByAppendingFormat:@"%@\n",newString];
	}
	
	NSAttributedString* n;
	if(highlight){
		n = [[NSAttributedString alloc] initWithString:[s length]?s:@"Cmd Label"
											attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco"  size:textSize],NSFontAttributeName,
														[NSColor colorWithCalibratedRed:.5 green:.5 blue:.5 alpha:.3],NSBackgroundColorAttributeName,nil]];
	}
	else {
		n= [[NSAttributedString alloc] initWithString:[s length]?s:@"Cmd Label"
										   attributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Monaco" size:textSize] forKey:NSFontAttributeName]];
	}
	
	return [n autorelease];
	 
}
	 
@end
