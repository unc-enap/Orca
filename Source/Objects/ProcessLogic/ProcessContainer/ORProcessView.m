//
//  ORProcessView.m
//  Orca
//
//  Created by Mark Howe on Sat Dec 12, 2009.
//  Copyright  © 2009 University of North Carolina. All rights reserved.
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
#import "ORProcessView.h"
#import "ORProcessModel.h"

@implementation ORProcessView

- (void)drawRect:(NSRect)rect
{
	if([group useAltView]){
		[backgroundImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
	[self drawContents:rect];
    [mouseTask drawRect:rect];
}

- (void) doControlClick:(id)sender
{
	if([group useAltView])[super doControlClick:sender];
}

@end

