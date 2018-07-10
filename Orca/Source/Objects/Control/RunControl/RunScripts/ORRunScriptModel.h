//-------------------------------------------------------------------------
//  ORRunScriptModel.m
//
//  Created by Mark A. Howe on Tuesday 12/26/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORScriptIDEModel.h"

@interface ORRunScriptModel : ORScriptIDEModel
{	
	SEL	selectorOK;
	SEL	selectorBAD;
	id	anArg;
	id	target;
    int slot;
    int selectionIndex;
}

- (void) registerNotificationObservers;
- (void) runningChanged:(NSNotification*)aNote;
- (NSComparisonResult)compare:(ORRunScriptModel *)otherObject;
- (int)slot;
- (void) setSlot:(int)aSlot;
- (int)selectionIndex;
- (void) setSelectionIndex:(int)anIndex;

#pragma mark ***Scripting
- (void) runOKSelectorNow;
- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue;
- (void) setSelectorOK:(SEL)aSelectorOK bad:(SEL)aSelectorBAD withObject:(id)anObject target:(id)aTarget;

@end

extern NSString* ORRunScriptSlotChangedNotification;


