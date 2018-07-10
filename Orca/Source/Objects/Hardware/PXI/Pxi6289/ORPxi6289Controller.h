//-------------------------------------------------------------------------
//  ORPxi6289Controller.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORPxi6289Model.h"
@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORPxi6289Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
    //basic ops page
	IBOutlet NSMatrix*		enabled01Matrix;
	IBOutlet NSMatrix*		threshold01Matrix;
	IBOutlet NSMatrix*		enabled02Matrix;
	IBOutlet NSMatrix*		threshold02Matrix;

    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;

    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
 
    //rate page
	//fist one in the 0-15 group
    IBOutlet NSMatrix*      rate1TextFields;
    IBOutlet NSMatrix*      enabled1Matrix;	
    IBOutlet ORValueBarGroupView*    rate1;
    IBOutlet NSButton*      rate1LogCB;

	//fist one in the 16-31 group
	IBOutlet NSMatrix*      rate2TextFields;	
    IBOutlet ORValueBarGroupView*    rate2;				
    IBOutlet NSMatrix*      enabled2Matrix;	
    IBOutlet NSButton*      rate2LogCB;
	
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;

    IBOutlet ORValueBarGroupView*    totalRate;
    IBOutlet NSButton*      totalRateLogCB;
    IBOutlet ORCompositeTimeLineView*    timeRatePlot;
    IBOutlet NSButton*      timeRateLogCB;

    NSView *blankView;
    NSSize settingSize;
    NSSize rateSize;

}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) enabledChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) integrationAction:(id)sender;

- (IBAction) enabledAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;

#pragma mark •••Data Source
- (double)  getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;


@end
