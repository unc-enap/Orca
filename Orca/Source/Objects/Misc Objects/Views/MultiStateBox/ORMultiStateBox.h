//
//  MultiStateBox.h
//  Orca
//
//  Created by Benjamin Land on 1/18/16.
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#ifndef Orca_MultiStateBox_h
#define Orca_MultiStateBox_h

// Allows for programatic creation of multi-state buttons of arbitrary color
@interface ORMultiStateBox : NSObject
{
    NSMutableDictionary* imageDictionary;
}

// Makes an NSImage of the given size with the specified colors in the
// upper left and bottom right
+ (NSImage*) splitBox:(int)sz pad:(int)bd bevel:(int)bev upLeft:(NSColor*)ul botRight:(NSColor*)ur;

// Create an ORMultiStateBox object with the states of given NSColors specified
// in the dictionary
- (ORMultiStateBox*) initWithStates:(NSDictionary*)stateDictionary size:(int)sz pad:(int)pad bevel:(int)bev;

// Clean up
- (void) dealloc;

// Returns the image for the given two states
- (NSImage*) upLeft:(id)ul botRight:(id)br;
@end

#endif
