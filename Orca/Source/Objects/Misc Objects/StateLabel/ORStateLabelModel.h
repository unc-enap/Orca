//
//  ORLabelModel.h
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
#import "ORLabelModel.h"

@interface ORStateLabelModel : ORLabelModel  
{
	int boolType;
	NSColor* trueColor;
	NSColor* falseColor;
}

#pragma mark •••Initialization
- (id) init;
- (void) makeMainController;
- (void) setUpImage;

#pragma mark •••Accessor
- (int) boolType;
- (void) setBoolType:(int)aType;
- (NSColor*) trueColor;
- (void) setTrueColor:(NSColor*)aColor;
- (NSColor*) falseColor;
- (void) setFalseColor:(NSColor*)aColor;
- (NSString*) boolString:(BOOL)aValue;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORLabelModelBoolTypeChanged;
extern NSString* ORLabelModelTrueColorChanged;
extern NSString* ORLabelModelFalseColorChanged;
