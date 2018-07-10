//
//  ORProcessInput.m
//  Orca
//
//  Created by Mark Howe on 1/11/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORProcessInConnector.h"
#import "ORProcessElementModel.h"
#import "ORDotImage.h"

@implementation ORProcessInConnector

- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency
{
	if(![objectLink partOfRun])[super drawSelf:aRect withTransparency:aTransparency];
	else {
		if(!stateOnImage){
			[self setStateOnImage:[ORDotImage dotWithColor:kProcessOnColor]];
			[self setStateOffImage:[ORDotImage dotWithColor:kProcessOffColor]];
		}
		NSRect guardianRect		 = [guardian frame];
		NSRect convertedDrawRect = NSOffsetRect([self localFrame],guardianRect.origin.x,guardianRect.origin.y);
		
		if(!NSIntersectsRect(aRect,convertedDrawRect))return;
		
		NSImage *imageToDraw;
		NSRect frame = convertedDrawRect;
		if([objectLink highlighted]){
			if(![[connector objectLink] evaluatedState])	imageToDraw = stateOffImage_Highlighted;
			else											imageToDraw = stateOnImage_Highlighted;
		}
		else {
			if(![[connector objectLink] evaluatedState])		imageToDraw = stateOffImage;
			else											imageToDraw = stateOnImage;
		}
		if(imageToDraw){
			NSRect sourceRect = NSMakeRect(0,0,[imageToDraw size].width,[imageToDraw size].height);
			[imageToDraw drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositeSourceOver fraction:aTransparency];
		}
	}
}


- (void) drawConnection:(NSRect)aRect
{
	if(![objectLink partOfRun])[super drawConnection:aRect];
}

@end
