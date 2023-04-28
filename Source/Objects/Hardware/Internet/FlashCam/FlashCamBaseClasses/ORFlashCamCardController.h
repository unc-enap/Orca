//  Orca
//  ORFlashCamCardController.h
//
//  Created by Tom Caldwell on Wednesday, Sep 15,2021
//  Copyright (c) 2021 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "OrcaObjectController.h"

@class ORCompositeTimeLineView;

@interface ORFlashCamCardController : OrcaObjectController
{
    IBOutlet NSTextField* cardAddressTextField;
    IBOutlet NSPopUpButton* promSlotPUButton;
    IBOutlet NSButton* rebootCardButton;
    IBOutlet NSTextField* firmwareVerTextField;
    IBOutlet NSButton* getFirmwareVerButton;
    IBOutlet NSButton* printFlagsButton;
    IBOutlet NSTextField* fcioIDTextField;
    IBOutlet NSTextField* statusEventTextField;
    IBOutlet NSTextField* statusPPSTextField;
    IBOutlet NSTextField* statusTicksTextField;
    IBOutlet NSTextField* totalErrorsTextField;
    IBOutlet NSTextField* envErrorsTextField;
    IBOutlet NSTextField* ctiErrorsTextField;
    IBOutlet NSTextField* linkErrorsTextField;
    IBOutlet ORCompositeTimeLineView* tempView;
    IBOutlet ORCompositeTimeLineView* voltageView;
    IBOutlet ORCompositeTimeLineView* currentView;
    IBOutlet ORCompositeTimeLineView* humidityView;
    IBOutlet NSButton* settingsLockButton;
    BOOL     scheduledToUpdatePlot;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) populatePromSlotPopup;
- (void) updateWindow;

#pragma mark •••Interface management
- (void) cardAddressChanged:(NSNotification*)note;
- (void) promSlotChanged:(NSNotification*)note;
- (void) firmwareVerRequest:(NSNotification*)note;
- (void) firmwareVerChanged:(NSNotification*)note;
- (void) cardSlotChanged:(NSNotification*)note;
- (void) statusChanged:(NSNotification*)note;
- (void) scaleAction:(NSNotification*)note;
- (void) miscAttributesChanged:(NSNotification*)note;
- (void) setPlot:(id)aPlotter xAttributes:(id)attrib;
- (void) setPlot:(id)aPlotter yAttributes:(id)attrib;
- (void) updateTimePlot:(NSNotification*)note;
- (void) deferredPlotUpdate;
- (void) checkGlobalSecurity;
- (void) settingsLock:(bool)lock;

#pragma mark •••Actions
- (IBAction) cardAddressAction:(id)sender;
- (IBAction) promSlotAction:(id)sender;
- (IBAction) rebootCardAction:(id)sender;
- (IBAction) firmwareVerAction:(id)sender;
- (IBAction) printFlagsAction:(id)sender;
- (IBAction) settingsLockAction:(id)sender;

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
