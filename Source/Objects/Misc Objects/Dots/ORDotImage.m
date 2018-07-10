//
//  ORDotImage.m
//  Orca
//
//  Created by Mark Howe on Fri Oct 22, 2004.
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

#import "ORDotImage.h"

@implementation ORDotImage

+ (ORDotImage *)dotWithColor:(NSColor *)aColor 
{
	return [[[self alloc] initWithColor:aColor 
							shadowImage:[NSImage imageNamed:@"dotshadow"] 
						 colorMaskImage:[NSImage imageNamed:@"dotcolormask"] 
					refractionMaskImage:[NSImage imageNamed:@"dottopmask"]] autorelease];
}

+ (ORDotImage *)bigDotWithColor:(NSColor *)aColor 
{
	return [[[self alloc] initWithColor:aColor 
							shadowImage:[NSImage imageNamed:@"bigdotshadow"] 
						 colorMaskImage:[NSImage imageNamed:@"bigdotcolormask"] 
					refractionMaskImage:[NSImage imageNamed:@"bigdottopmask"]] autorelease];
}

+ (ORDotImage *)vRectWithColor:(NSColor *)aColor 
{
	return [[[self alloc] initWithColor:aColor 
							shadowImage:[NSImage imageNamed:@"vrectshadow"] 
						 colorMaskImage:[NSImage imageNamed:@"vrectcolormask"] 
					refractionMaskImage:[NSImage imageNamed:@"vrecttopmask"]] autorelease];
}
+ (ORDotImage *)hRectWithColor:(NSColor *)aColor 
{
	return [[[self alloc] initWithColor:aColor 
							shadowImage:[NSImage imageNamed:@"hrectshadow"] 
						 colorMaskImage:[NSImage imageNamed:@"hrectcolormask"] 
					refractionMaskImage:[NSImage imageNamed:@"hrecttopmask"]] autorelease];
}

+ (ORDotImage *)smallDotWithColor:(NSColor *)aColor 
{
	return [[[self alloc] initWithColor:aColor 
							shadowImage:[NSImage imageNamed:@"smalldotshadow"] 
						 colorMaskImage:[NSImage imageNamed:@"smalldotcolormask"] 
					refractionMaskImage:[NSImage imageNamed:@"smalldottopmask"]] autorelease];
}


- (id) initWithColor:(NSColor *)aColor shadowImage:(NSImage*)aShadowImage colorMaskImage:(NSImage*)aColorMaskImage refractionMaskImage:(NSImage*)aRefractionMaskImage
{
    if (self = [super initWithSize:[aRefractionMaskImage size]]) {
        NSImage *newColorMaskImage = [aColorMaskImage copy];        
        NSRect colorMaskBounds = NSMakeRect(0, 0, [aColorMaskImage size].width, [aColorMaskImage size].height); 

		shadowImage			=    [aShadowImage retain];
		colorMaskImage		=    [aColorMaskImage retain];
		refractionMaskImage	=    [aRefractionMaskImage retain];
		
        //do a Shadow
        [self lockFocus];
        [shadowImage drawAtPoint:NSZeroPoint fromRect:[shadowImage imageRect] operation:NSCompositeCopy fraction:.7];
        [self unlockFocus];        
        
        //set up the color mask (tint it, then composite it)
        [newColorMaskImage lockFocus];
        [aColor set];
        NSRectFillUsingOperation(colorMaskBounds, NSCompositeSourceAtop);
        [newColorMaskImage unlockFocus];
        [self lockFocus];
        [newColorMaskImage drawAtPoint:NSZeroPoint fromRect:[newColorMaskImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
        
        // setup the refraction mask
        [refractionMaskImage drawAtPoint:NSZeroPoint fromRect:[refractionMaskImage imageRect] operation:NSCompositeSourceOver fraction:1.0];         
        [self unlockFocus];
        [newColorMaskImage release];
    }
     
    return self;
}

- (void) dealloc
{
	[shadowImage release];
	[colorMaskImage	release];
	[refractionMaskImage release];
	
	[super dealloc];
}
@end
