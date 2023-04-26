//  Orca
//  ORL200Controller.h
//
//  Created by Tom Caldwell on Monday Mar 21, 2022
//  Copyright (c) 2022 University of North Carolina. All rights reserved.
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

#import "ORExperimentController.h"
#import "ORL200DetectorView.h"

@class ORColorScale;
@class ORSegmentGroup;
@class ORRunModel;

@interface ORL200Controller : ORExperimentController {
    ORRunModel* rc;
    IBOutlet NSPopUpButton* viewTypePopup;
    
    IBOutlet NSTableView*   sipmTableView;
    IBOutlet NSTextField*   sipmMapFileTextField;
    IBOutlet NSPopUpButton* sipmAdcClassNamePopup;
    IBOutlet NSButton*      sipmReadMapFileButton;
    IBOutlet NSButton*      sipmSaveMapFileButton;
    IBOutlet ORColorScale*  sipmColorScale;
    IBOutlet NSButton*      sipmColorAxisLogCB;
    IBOutlet NSTextField*   sipmRateField;
    
    IBOutlet NSTableView*   pmtTableView;
    IBOutlet NSTextField*   pmtMapFileTextField;
    IBOutlet NSPopUpButton* pmtAdcClassNamePopup;
    IBOutlet NSButton*      pmtReadMapFileButton;
    IBOutlet NSButton*      pmtSaveMapFileButton;
    IBOutlet ORColorScale*  pmtColorScale;
    IBOutlet NSButton*      pmtColorAxisLogCB;
    IBOutlet NSTextField*   pmtRateField;

    IBOutlet NSTableView*   cc4TableView;
    IBOutlet NSButton*      cc4ReadMapFileButton;
    IBOutlet NSButton*      cc4SaveMapFileButton;
    IBOutlet NSTextField*   cc4ChanMapFileTextField;
    IBOutlet NSPopUpButton* cc4AdcClassNamePopup;

    IBOutlet NSTableView*   auxChanTableView;
    IBOutlet NSTextField*   auxChanMapFileTextField;
    IBOutlet NSPopUpButton* auxChanAdcClassNamePopup;
    IBOutlet NSButton*      auxChanReadMapFileButton;
    IBOutlet NSButton*      auxChanSaveMapFileButton;
    IBOutlet ORColorScale*  auxChanColorScale;
    IBOutlet NSButton*      auxChanColorAxisLogCB;
    IBOutlet NSTextField*   auxChanRateField;
    
    IBOutlet NSTableView* adcSerialTableView;
    IBOutlet NSTextField* adcSerialFileTextView;
    IBOutlet NSButton*    adcSerialReadMapFileButton;
    IBOutlet NSButton*    adcSerialSaveMapFileButton;
    
    IBOutlet NSTextField* dataCycleField;
    IBOutlet NSTextField* dataPeriodField;
    IBOutlet NSTextField* customTypeLabel;
    IBOutlet NSTextField* customTypeField;
    IBOutlet NSPopUpButton* dataTypePopup;
    IBOutlet NSTextField*   l200FileNameField;
    IBOutlet NSStepper*   cycleStepper;
    IBOutlet NSStepper*   periodStepper;
}

#pragma mark •••Initialization
- (NSString*) defaultSiPMMapFilePath;
- (NSString*) defaultPMTMapFilePath;
- (NSString*) defaultAuxChanMapFilePath;
- (NSString*) defaultCC4MapFilePath;
- (NSString*) defaultADCSerialMapFilePath;

#pragma mark •••Notifications
- (void) updateWindow;
- (void) groupChanged:(NSNotification*)note;
- (void) viewTypeChanged:(NSNotification*)note;

- (void) colorScaleTypeChanged:(NSNotification*)note;
- (void) customColor1Changed:(NSNotification*)note;
- (void) customColor2Changed:(NSNotification*)note;

- (void) sipmColorAxisAttributesChanged:(NSNotification*)note;
- (void) sipmAdcClassNameChanged:(NSNotification*)note;
- (void) sipmMapFileChanged:(NSNotification*)note;

- (void) pmtColorAxisAttributesChanged:(NSNotification*)note;
- (void) pmtAdcClassNameChanged:(NSNotification*)note;
- (void) pmtMapFileChanged:(NSNotification*)note;

- (void) auxChanColorAxisAttributesChanged:(NSNotification*)note;
- (void) auxChanAdcClassNameChanged:(NSNotification*)note;
- (void) auxChanMapFileChanged:(NSNotification*)note;

- (void) cc4ChanMapFileChanged:(NSNotification*)note;
- (void) cc4ChanAdcClassNameChanged:(NSNotification*)note;
- (NSString*) getCC4Name:(int)aPosition slot:(int)aSlot;

- (void) adcSerialMapFileChanged:(NSNotification*)note;

- (void) dataCycleChanged:(NSNotification*) aNote;
- (void) dataPeriodChanged:(NSNotification*) aNote;
- (void) dataTypeChanged:(NSNotification*) aNote;
- (void) customTypeChanged:(NSNotification*) aNote;
- (void) l200FileNameChanged:(NSNotification*) aNote;

#pragma mark •••Actions
- (IBAction) viewTypeAction:(id)sender;
- (IBAction) sipmAdcClassNameAction:(id)sender;
- (IBAction) saveSIPMMapFileAction:(id)sender;
- (IBAction) readSIPMMapFileAction:(id)sender;
- (IBAction) autoscaleSIPMColorScale:(id)sender;

- (IBAction) pmtAdcClassNameAction:(id)sender;
- (IBAction) savePMTMapFileAction:(id)sender;
- (IBAction) readPMTMapFileAction:(id)sender;
- (IBAction) autoscalePMTColorScale:(id)sender;

- (IBAction) auxChanAdcClassNameAction:(id)sender;
- (IBAction) saveAuxChanMapFileAction:(id)sender;
- (IBAction) readAuxChanMapFileAction:(id)sender;
- (IBAction) autoscaleAuxChanColorScale:(id)sender;

- (IBAction) saveCC4ChanMapFileAction:(id)sender;
- (IBAction) readCC4ChanMapFileAction:(id)sender;
- (IBAction) cc4AdcClassNameAction:(id)sender;

- (IBAction) saveADCSerialMapFileAction:(id)sender;
- (IBAction) readADCSerialMapFileAction:(id)sender;

- (IBAction) dataCycleAction:(id)sender;
- (IBAction) dataPeriodAction:(id)sender;
- (IBAction) dataTypePopupAction:(id)sender;
- (IBAction) customTypeAction:(id)sender;
- (IBAction) bumpDataPeriod:(id)sender;
- (IBAction) bumpDataCycle:(id)sender;


#pragma mark •••Interface Management
- (int) segmentTypeFromTableView:(NSTableView*)view;

@end
