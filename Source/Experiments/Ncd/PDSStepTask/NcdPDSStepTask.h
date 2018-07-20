//
//  NcdPDSStepTask.h
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

@interface NcdPDSStepTask : ORTask
{
    IBOutlet NSMatrix* patternMatrix0;
    IBOutlet NSMatrix* patternMatrix1;
    IBOutlet NSMatrix* patternMatrix2;
    IBOutlet NSMatrix* patternMatrix3;
    IBOutlet NSButton* reloadPDSButton;
    IBOutlet NSButton* ignorePDSButton;
    IBOutlet NSButton* setAllButton;
    IBOutlet NSButton* clrAllButton;
    IBOutlet NSTextField* timeField;
    IBOutlet NSStepper* timeStepper;
    NSMutableArray*     patternArray;
    NSArray*            stepTaskObjects;
    id thePDSModel;
    BOOL reloadPDS;
    BOOL ignorePDS;
    int timeOnOneChannel;
    int     workingChannelIndex;
    int     totalChannels;
    NSDate* lastTime;
    int     pdsBoard;
    int     pdsChannel;
    NSArray* pdsStepTaskObjects;
}

- (id) init;

#pragma mark ¥¥¥Accessors
- (NSMutableArray*) patternArray;
- (uint32_t)patternMaskForArray:(int)arrayIndex;
- (void) setPatternArray:(NSMutableArray*)aPatternArray;
- (uint32_t)patternMaskForArray:(int)arrayIndex;
- (void) setPatternMaskForArray:(int)arrayIndex to:(uint32_t)aValue;
- (int) numberEnabledChannels;
- (void) loadMaskForChannelIndex:(int) index;
- (NSArray*) patternMatrixArray;
- (BOOL) okToRun;
- (void) enableGUI:(BOOL)state;
- (void) setEnabledStates;
- (BOOL)reloadPDS;
- (void)setReloadPDS:(BOOL)flag;
- (BOOL)ignorePDS;
- (void)setIgnorePDS:(BOOL)flag;
- (int)timeOnOneChannel;
- (void)setTimeOnOneChannel:(int)aTimeOnOneChannel;
- (void) setAllEnabled:(NSMatrix*)sender to:(BOOL)state;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) updateView;
- (void) patternChanged:(NSNotification*)aNotification;
- (void) setEnabledinMatrix:(NSMatrix*)aMatrix usingMask:(uint32_t)aMask;
- (void) distributionPatternChanged:(NSNotification*)aNotification;
- (void) tubeMapChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) patternAction:(id)sender;
- (IBAction) reloadPDS:(id)sender;
- (IBAction) ignorePDS:(id)sender;
- (IBAction) timeAction:(id)sender;
- (IBAction) setAllAction:(id)sender;
- (IBAction) clrAllAction:(id)sender;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (void)loadMemento:(NSCoder*)decoder;
- (void)saveMemento:(NSCoder*)encoder;

#pragma mark ¥¥¥Task Methods
- (void) prepare;
- (BOOL) doWork;
- (void) cleanUp;


@end

