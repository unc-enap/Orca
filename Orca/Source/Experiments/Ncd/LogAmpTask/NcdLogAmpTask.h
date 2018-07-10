//
//  NcdLogAmpTask.
//  Orca
//
//  Created by Mark Howe on July 1, 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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



#import "ORTask.h"

@interface NcdLogAmpTask : ORTask
{

    IBOutlet NSTextField* timeField;
    IBOutlet NSStepper* timeStepper;

    id stepTask;
    id thePDSModel;
    id thePulserModel;
    BOOL startedStepTask;
    int timeOnOneChannel;
    NSData* stepTaskMemento;
    NSData* pulserMemento;
    NSData* pdsMemento;
    NSArray* ncdLogAmpTaskObjects;
}

- (int)timeOnOneChannel;
- (void)setTimeOnOneChannel:(int)aTimeOnOneChannel;

#pragma mark ¥¥¥Actions
- (IBAction) timeAction:(id)sender;

#pragma mark ¥¥¥Task Methods
- (void) prepare;
- (BOOL)   doWork;
- (void) finishUp;
@end

