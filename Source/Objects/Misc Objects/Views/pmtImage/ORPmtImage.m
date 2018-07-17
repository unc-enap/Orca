//
//  ORPmtImage.m
//  Orca
//
//  Created by Mark Howe on Fri Oct 22, 2004.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORPmtImage.h"
#import "SynthesizeSingleton.h"

@implementation ORPmtImages

SYNTHESIZE_SINGLETON_FOR_ORCLASS(PmtImages);

- (ORPmtImage *) pmtWithColor:(NSColor *)aColor angle:(float)anAngle
{
	id anImage = [[pmtImages objectForKey:aColor] objectForKey:[NSNumber numberWithInt:(int)anAngle]];
	if(anImage)return anImage;
	else {																		//couldn't find one already made.
		anImage = [ORPmtImage pmtWithColor:aColor angle:anAngle];				//make one
		if(!pmtImages) pmtImages = [[NSMutableDictionary dictionary] retain];	//check the top level dictionary
		NSMutableDictionary* colorGroup = [pmtImages objectForKey:aColor];		//check the top level entry
		if(!colorGroup) {														//couldn't find anything for this color
			colorGroup = [NSMutableDictionary dictionary];				//make an dictionary
			[pmtImages setObject:colorGroup forKey:aColor];						//enter it
		}
		[colorGroup setObject:anImage forKey:[NSNumber numberWithInt:(int)anAngle]];
	}
	return anImage;
}
@end


static NSImage *pmtImage, *colorMaskImage, *topImage;

@implementation ORPmtImage
+ (void)initialize 
{
	pmtImage         =  [[NSImage imageNamed:@"pmt"] retain];
	colorMaskImage   =  [[NSImage imageNamed:@"pmtColorMask"] retain];
	topImage		 =	[[NSImage imageNamed:@"pmtShadow"] retain];
}


+ (ORPmtImage *)pmtWithColor:(NSColor *)aColor angle:(float)anAngle
{
     return [[[self alloc] initWithColor:aColor angle:anAngle] autorelease];
}

- (id) initWithColor:(NSColor*)aColor angle:(float)anAngle
{
    if (self = [super initWithSize:[pmtImage size]]) {
		if(!pmtImage)		pmtImage         =  [[NSImage imageNamed:@"pmt"] retain];
		if(!colorMaskImage)	colorMaskImage   =  [[NSImage imageNamed:@"pmtColorMask"] retain];
		if(!topImage)		topImage		 =	[[NSImage imageNamed:@"pmtShadow"] retain];
		angle = anAngle;
		[self setColor:aColor];
    }
    return self;
}

- (void) setColor:(NSColor*)aColor
{
	NSImage *anImage = [[colorMaskImage copy] autorelease];        
	NSRect imageBounds = NSMakeRect(0, 0, [anImage size].width, [anImage size].height); 
	[anImage lockFocus];
	[aColor set];
	NSRectFillUsingOperation(imageBounds, NSCompositingOperationSourceAtop);
	[anImage unlockFocus];
	
	anImage = [[anImage copy] autorelease];        
	[anImage lockFocus];
    [pmtImage drawAtPoint:NSZeroPoint fromRect:[pmtImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    [anImage drawAtPoint:NSZeroPoint fromRect:[anImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    [topImage drawAtPoint:NSZeroPoint fromRect:[topImage imageRect] operation:NSCompositingOperationSourceOver fraction:0.6];
	[anImage unlockFocus];
	
	NSImage* newImage =     [self rotateIndividualImage: anImage angle:angle];
	[self lockFocus];
    [newImage drawInRect:NSMakeRect (0,0,80,80) fromRect:[newImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
	[self unlockFocus];
	
}

@end
