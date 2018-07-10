//
//  ORStateLabelModel.m
//  Orca
//
//  Created by Mark Howe on Fri Dec 4,2009.
//  Copyright © 2009 University of North Carolina. All rights reserved.
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
#import "ORStateLabelModel.h"
#import "ORCommandCenter.h"

NSString* ORLabelModelBoolTypeChanged = @"ORLabelModelBoolTypeChanged";
NSString* ORLabelModelTrueColorChanged = @"ORLabelModelTrueColorChanged";
NSString* ORLabelModelFalseColorChanged = @"ORLabelModelFalseColorChanged";

@interface ORStateLabelModel (private)
- (NSString*) stringToDisplay;
@end

@implementation ORStateLabelModel

#pragma mark •••initialization
- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self setLabelType:kDynamicLabel];
	[self setTrueColor:	[NSColor blackColor]];
	[self setFalseColor:[NSColor blackColor]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) makeMainController
{
    [self linkToController:@"ORStateLabelController"];
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
		if([n length] == 0)n = [[[NSMutableAttributedString alloc] initWithString:@"State Label" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
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

#pragma mark ***Accessors
- (int) boolType
{
	return boolType;
}

- (void) setBoolType:(int)aType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setLabelType:labelType];
	boolType = aType;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelBoolTypeChanged object:self];
	[self setUpImage];
}

- (NSColor*) trueColor
{
	if(!trueColor)return [NSColor blackColor];
	return trueColor;
}

- (void) setTrueColor:(NSColor*)aColor
{
	[[[self undoManager] prepareWithInvocationTarget:self] setTrueColor:trueColor];
	[aColor retain];
	[trueColor release];
	trueColor = aColor;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelTrueColorChanged object:self];
	[self setUpImage];
}

- (NSColor*) falseColor
{
	if(!falseColor)return [NSColor blackColor];
	return falseColor;
}

- (void) setFalseColor:(NSColor*)aColor;
{
	[[[self undoManager] prepareWithInvocationTarget:self] setFalseColor:falseColor];
	[aColor retain];
	[falseColor release];
	falseColor = aColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelFalseColorChanged object:self];
	[self setUpImage];
}
- (void) setLabel:(NSString*)aLabel
{
    if(!aLabel)aLabel = @"";
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

- (NSAttributedString*) stringToDisplay:(BOOL)highlight
{
	int i;
	int n = [displayValues count];
	NSArray* formats = [displayFormat componentsSeparatedByString:@"\n"];
	NSString* aPrefix;
	NSMutableAttributedString* attribString;
	NSString* s = @"";
	if(n==0){
		if(highlight){
			attribString = [[NSMutableAttributedString alloc] initWithString:@"State Label" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																											  [NSFont fontWithName:@"Monaco"  size:textSize],NSFontAttributeName,
																											  [NSColor colorWithCalibratedRed:.5 green:.5 blue:.5 alpha:.3],NSBackgroundColorAttributeName,nil]];
		}
		else {
			attribString = [[NSMutableAttributedString alloc] initWithString:@"State Label" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																											  [NSFont fontWithName:@"Monaco" size:textSize],NSFontAttributeName,nil]];
		}
	}
	else {
		attribString = [[NSMutableAttributedString alloc] initWithString:@""];
		for(i=0;i<n;i++){
			id displayValue = [displayValues objectAtIndex:i];
			
			//get the prefix
			if(i<[formats count]) aPrefix = [formats objectAtIndex:i];
			else				  aPrefix = @"";
			
			//get the value part
			if([displayValue isEqual:@"?"]) s = [NSString stringWithFormat:@"%@%@%@",aPrefix,@"?",i<n-1?@"\n":@""];
			else							s = [NSString stringWithFormat:@"%@%@%@",aPrefix,displayValue==nil?@"?":[self boolString:[displayValue boolValue]],i<n-1?@"\n":@""];		

			//turn the result into an attributed string,with the right font, color, etc...
			NSMutableAttributedString* sPart;
			NSColor* theColor;
			if([displayValue boolValue])theColor = trueColor;
			else theColor=falseColor;
			if(highlight){
				sPart = [[[NSMutableAttributedString alloc] initWithString:[s length]?s:@"Text Label" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSFont fontWithName:@"Monaco"  size:textSize],NSFontAttributeName,
									  theColor,NSForegroundColorAttributeName,
									  [NSColor colorWithCalibratedRed:.5 green:.5 blue:.5 alpha:.3],NSBackgroundColorAttributeName,nil]] autorelease];
			}
			else {
				sPart = [[[NSMutableAttributedString alloc] initWithString:[s length]?s:@"Text Label" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
									  theColor,NSForegroundColorAttributeName,
									  [NSFont fontWithName:@"Monaco" size:textSize],NSFontAttributeName,nil]] autorelease];
			}
			
			//make the prefix part black
			if([aPrefix length]){
				NSString* s = [sPart string];
				NSRange prefixRange = [s rangeOfString:aPrefix];
				[sPart removeAttribute:NSForegroundColorAttributeName range:prefixRange];
			}
			
			//put all the results togther
			if(sPart)[attribString appendAttributedString:sPart];
		}
	}
	
	return [attribString autorelease];
}

- (NSString*) boolString:(BOOL)aValue
{
	switch(boolType){
		case 0: return aValue?@"Open":@"Closed";
		case 1: return aValue?@"Closed":@"Open";
		case 2: return aValue?@"On":@"Off";
		case 3: return aValue?@"Off":@"On";
		case 4: return aValue?@"Yes":@"No";
		case 5: return aValue?@"No":@"Yes";
		default:return aValue?@"1":@"0";
	}
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	[self setBoolType:	[decoder decodeIntForKey:    @"boolType"]];
	[self setTrueColor:	[decoder decodeObjectForKey: @"trueColor"]];
	[self setFalseColor:[decoder decodeObjectForKey: @"falseColor"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt:boolType		forKey:@"boolType"];
	[encoder encodeObject:trueColor	forKey:@"trueColor"];
	[encoder encodeObject:falseColor	forKey:@"falseColor"];
}

@end

