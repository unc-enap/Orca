//
//  ORHPCB37Controller.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 11,2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORCB37Model.h"

#define kCB37NumAdcs 24

@interface ORCB37Controller : OrcaObjectController 
{
	IBOutlet NSTabView*		tabView;	
	IBOutlet NSView*		totalView;
	IBOutlet NSButton*		lockButton;
	IBOutlet NSMatrix*		nameMatrix;
	IBOutlet NSMatrix*		name1Matrix;
	IBOutlet NSMatrix*		unitMatrix;
	IBOutlet NSMatrix*		adcMatrix;
	IBOutlet NSMatrix*		lowLimitMatrix;
	IBOutlet NSMatrix*		hiLimitMatrix;
	IBOutlet NSMatrix*		slopeMatrix;
	IBOutlet NSMatrix*		interceptMatrix;
	IBOutlet NSMatrix*		minValueMatrix;
	IBOutlet NSMatrix*		maxValueMatrix;
	IBOutlet NSTextField*	slotField;
	IBOutlet NSMatrix*		adcEnabledMatrix;

	NSSize					ioSize;
	NSSize					setupSize;
	NSView*					blankView;

	//arggggg-- why oh why can't NSPopUpButtons live in NSMatrixes
	IBOutlet NSPopUpButton*		gainPU0;
	IBOutlet NSPopUpButton*		gainPU1;
	IBOutlet NSPopUpButton*		gainPU2;
	IBOutlet NSPopUpButton*		gainPU3;
	IBOutlet NSPopUpButton*		gainPU4;
	IBOutlet NSPopUpButton*		gainPU5;
	IBOutlet NSPopUpButton*		gainPU6;
	IBOutlet NSPopUpButton*		gainPU7;
	IBOutlet NSPopUpButton*		gainPU8;
	IBOutlet NSPopUpButton*		gainPU9;
	IBOutlet NSPopUpButton*		gainPU10;
	IBOutlet NSPopUpButton*		gainPU11;
	IBOutlet NSPopUpButton*		gainPU12;
	IBOutlet NSPopUpButton*		gainPU13;
	IBOutlet NSPopUpButton*		gainPU14;
	IBOutlet NSPopUpButton*		gainPU15;
	IBOutlet NSPopUpButton*		gainPU16;
	IBOutlet NSPopUpButton*		gainPU17;
	IBOutlet NSPopUpButton*		gainPU18;
	IBOutlet NSPopUpButton*		gainPU19;
	IBOutlet NSPopUpButton*		gainPU20;
	IBOutlet NSPopUpButton*		gainPU21;
	IBOutlet NSPopUpButton*		gainPU22;
	IBOutlet NSPopUpButton*		gainPU23;
	
	IBOutlet NSPopUpButton*		bipolarPU0;
	IBOutlet NSPopUpButton*		bipolarPU1;
	IBOutlet NSPopUpButton*		bipolarPU2;
	IBOutlet NSPopUpButton*		bipolarPU3;
	IBOutlet NSPopUpButton*		bipolarPU4;
	IBOutlet NSPopUpButton*		bipolarPU5;
	IBOutlet NSPopUpButton*		bipolarPU6;
	IBOutlet NSPopUpButton*		bipolarPU7;
	IBOutlet NSPopUpButton*		bipolarPU8;
	IBOutlet NSPopUpButton*		bipolarPU9;
	IBOutlet NSPopUpButton*		bipolarPU10;
	IBOutlet NSPopUpButton*		bipolarPU11;
	IBOutlet NSPopUpButton*		bipolarPU12;
	IBOutlet NSPopUpButton*		bipolarPU13;
	IBOutlet NSPopUpButton*		bipolarPU14;
	IBOutlet NSPopUpButton*		bipolarPU15;
	IBOutlet NSPopUpButton*		bipolarPU16;
	IBOutlet NSPopUpButton*		bipolarPU17;
	IBOutlet NSPopUpButton*		bipolarPU18;
	IBOutlet NSPopUpButton*		bipolarPU19;
	IBOutlet NSPopUpButton*		bipolarPU20;
	IBOutlet NSPopUpButton*		bipolarPU21;
	IBOutlet NSPopUpButton*		bipolarPU22;
	IBOutlet NSPopUpButton*		bipolarPU23;
	
	NSPopUpButton* gainPU[kCB37NumAdcs];
	NSPopUpButton* bipolarPU[kCB37NumAdcs];
	
}

#pragma mark •••Notifications
- (void) lockChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (BOOL) legalAdcRange:(int)adcChan;
- (int)  displayChanFromAdcChan:(int)adcChan;
- (int) startChannel;
- (int) tagToAdcIndex:(int)aTag;

#pragma mark ***Interface Management
- (void) slotChanged:(NSNotification*)aNote;
- (void) adcEnabledChanged:(NSNotification*)aNote;
- (void) lowLimitChanged:(NSNotification*)aNote;
- (void) hiLimitChanged:(NSNotification*)aNote;
- (void) channelNameChanged:(NSNotification*)aNote;
- (void) channelUnitChanged:(NSNotification*)aNote;
- (void) adcChanged:(NSNotification*)aNote;
- (void) slopeChanged:(NSNotification*)aNote;
- (void) interceptChanged:(NSNotification*)aNote;
- (void) minValueChanged:(NSNotification*)aNote;
- (void) maxValueChanged:(NSNotification*)aNote;
- (void) gainChanged:(NSNotification*)aNote;
- (void) bipolarChanged:(NSNotification*)aNote;
- (void) tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

#pragma mark •••Actions
- (IBAction) adcEnabledAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) channelNameAction:(id)sender;
- (IBAction) channelUnitAction:(id)sender;
- (IBAction) minValueAction:(id)sender;
- (IBAction) maxValueAction:(id)sender;
- (IBAction) lowLimitAction:(id)sender;
- (IBAction) hiLimitAction:(id)sender;
- (IBAction) slopeAction:(id)sender;
- (IBAction) interceptAction:(id)sender;
- (IBAction) showLabJackUE9:(id)sender;
- (IBAction) bipolarAction:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) printChannelLocations:(id)sender;

@end

