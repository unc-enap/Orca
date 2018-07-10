//
//  ORAdcInfoProviding.h
//  Orca
//
//  Created by Mark Howe on Wed Dec 6 2006.
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


//------------------------------------------------------------
// a formal protocol for objects that participate in sharing
// thresholds, gains, rates for display in 'meta' objects that
// collect info from lots of individual objects. Example objects
// would be the ORShaperModel adc cord.
//------------------------------------------------------------

@protocol ORAdcInfoProviding

- (unsigned long) thresholdForDisplay:(unsigned short) aChan;
- (unsigned short) gainForDisplay:(unsigned short) aChan;
- (BOOL) onlineMaskBit:(int)bit;
- (void) makeMainController;
- (void) initBoard;
- (void) postAdcInfoProvidingValueChanged;
- (BOOL) partOfEvent:(unsigned short) aChan;
- (unsigned long) eventCount:(int)channel;
- (void) clearEventCounts;
@end

extern NSString* ORAdcInfoProvidingValueChanged;