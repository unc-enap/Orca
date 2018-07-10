//
//  nTPCModel.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 15 2007.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORExperimentModel.h"

@interface nTPCModel :  ORExperimentModel
{
    unsigned short planeMask;
}

#pragma mark ***Accessors
- (unsigned short) planeMask;
- (void) setPlaneMask:(unsigned short)aPlaneMask;

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups;

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock;
- (NSString*) experimentDetectorLock;
- (NSString*) experimentDetailsLock;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* nTPCModelPlaneMaskChanged;

