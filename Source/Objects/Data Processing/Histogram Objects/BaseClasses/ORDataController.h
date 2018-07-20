//
//  ORDataController.h
//  Orca
//
//  Created by Mark Howe on Tue Dec 09 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


@interface ORDataController : OrcaObjectController {
	    
    IBOutlet NSDrawer*		analysisDrawer;

    IBOutlet NSTextField*   positionField;
    IBOutlet NSButton*		hideShowButton;
    IBOutlet NSView*        containingView;
    IBOutlet NSTextField*   pausedField;
    IBOutlet NSTableView*   rawDataTable;
    IBOutlet NSTabView*		rawDataTabView;
    IBOutlet NSPopUpButton*	refreshModePU;
	IBOutlet NSButton*		pauseButton;
    IBOutlet NSButton*		refreshButton;
	IBOutlet id             plotView;
    
	NSRect preTiledSize;
    NSRect tooBigFrame;
    BOOL   restoreTooBigFrame;
}

#pragma mark •••Accessors
- (id) plotView;
- (id) analysisDrawer;

#pragma mark •••Interface Management
- (void) registerNotificationObservers;
- (void) dataSetRemoved:(NSNotification*)aNote;
- (void) updateWindow;

- (void) dataSetChanged:(NSNotification*)aNote;
- (void) calibrationChanged:(NSNotification*)aNote;
- (void) drawerDidOpen:(NSNotification*)aNote;
- (void) drawerDidClose:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) refreshModeChanged:(NSNotification*)aNote;
- (void) pausedChanged:(NSNotification*)aNote;
- (void) serviceResponse:(NSNotification*)aNote;
- (void) runStatusChanged:(NSNotification*)aNote;

- (void) openAnalysisDrawer;
- (void) closeAnalysisDrawer;
- (BOOL) analysisDrawerIsOpen;
- (void) refreshX;

- (IBAction) doAnalysis:(NSToolbarItem*)item;
- (IBAction) logLin:(NSToolbarItem*)item;
- (IBAction) toggleRaw:(NSToolbarItem*)item;
- (IBAction) clear:(NSToolbarItem*)item;
- (IBAction) hideShowControls:(id)sender;
- (IBAction) refreshModeAction:(id)sender;
- (IBAction) pauseAction:(id)sender;
- (IBAction) tileWindows:(id)sender;
- (IBAction) unTileWindows:(id)sender;
- (IBAction) autoScale:(NSToolbarItem*)sender;	 
//scripting helper
- (void) savePlotToFile:(NSString*)aFile;
- (id) curve:(int)c gate:(int)g; //for backward compatiblity with scripts

@property (assign) NSRect preTiledSize;

@end

@interface NSObject (ORDataController_Cat)
- (uint32_t)  numberBins;
- (int32_t) value:(uint32_t)aChan;
@end
 

