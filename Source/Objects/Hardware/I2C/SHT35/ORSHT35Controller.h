//
//  ORSHT35Controller.h
//  Orca
//
//  Created by Mark Howe on 08/1/2024.
//  Copyright 2024 University of North Carolina. All rights reserved.
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
@class ORCompositeTimeLineView;

@interface ORSHT35Controller : OrcaObjectController
{
    IBOutlet NSTextField*   i2cAddressField;
    IBOutlet NSTextField*   temperatureField;
    IBOutlet NSTextField*   humidityField;
    IBOutlet NSPopUpButton* updateIntervalPU;
	IBOutlet NSButton*		lockButton;
    IBOutlet NSButton*      pollNowButton;
    IBOutlet NSButton*      startStopButton;
    IBOutlet ORCompositeTimeLineView*   temperaturePlot;
    IBOutlet ORCompositeTimeLineView*   humidityPlot;

}

#pragma mark •••Notifications
- (void) i2cAddressChanged:(NSNotification*)aNote;
- (void) temperatureChanged:(NSNotification*)aNote;
- (void) humidityChanged:(NSNotification*)aNote;
- (void) runningChanged:(NSNotification*)aNote;
- (void) updatePlots:(NSNotification*)aNote;
- (void) setWindowTitle;

- (void) lockChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) startStopAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;
- (IBAction) updateIntervalPUAction:(id)sender;
- (IBAction) addressAction:(id)sender;
- (IBAction) lockAction:(id)sender;

@end

