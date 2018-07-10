//
//  ORProcessConnector.h
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


#define kProcessOnColor  [NSColor colorWithCalibratedRed:0 green:.75 blue:0 alpha:1.0]
#define kProcessOffColor [NSColor darkGrayColor]


@interface ORProcessConnector : ORConnector {
	NSImage*  	 stateOnImage;
	NSImage*  	 stateOffImage;

	NSImage*  	 stateOnImage_Highlighted;
	NSImage*  	 stateOffImage_Highlighted;
}

- (void) dealloc;
- (NSImage*) stateOnImage;
- (void) setStateOnImage:(NSImage *)anImage;
- (NSImage*) stateOffImage;
- (void) setStateOffImage:(NSImage *)anImage;

@end

@interface NSObject (ORProcessConnector)
- (float) evalAndReturnAnalogValue;
@end