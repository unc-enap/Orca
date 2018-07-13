
//
//  ORPlotLinkController.m
//  Orca
//
//  Created by Mark Howe on Wed 23 23 2009.
//  Copyright © 2009 University of North Carolina. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORPlotLinkController.h"
#import "ORPlotLinkModel.h"

@implementation ORPlotLinkController

#pragma mark •••Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"PlotLink"];
    return self;
}

#pragma mark •••Interface Management
- (void) iconTypeChanged:(NSNotification*)aNote
{
	[iconTypeMatrix selectCellWithTag: [model iconType]];	
}

- (void) plotNameChanged:(NSNotification*)aNote
{
	[plotNameField setStringValue: [model plotName]];
}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
	
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    
    [notifyCenter addObserver: self
                     selector: @selector(plotLinkLockChanged:)
                         name: ORPlotLinkLock
                       object: model];
			
    [notifyCenter addObserver : self
                     selector : @selector(plotNameChanged:)
                         name : ORPlotLinkModelPlotNameChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(populatePopup:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(populatePopup:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataCatalogNameChanged:)
                         name : ORPlotLinkModelDataCatalogNameChanged
                       object : nil];	
	
    [notifyCenter addObserver : self
                     selector : @selector(iconTypeChanged:)
                         name : ORPlotLinkModelIconTypeChanged
						object: model];

}

- (void) awakeFromNib
{
	[self populatePopup:nil];
	[self dataCatalogNameChanged:nil];
	[super awakeFromNib];
}

- (void) updateWindow
{
	[super updateWindow];
    [self plotLinkLockChanged:nil];
	[self plotNameChanged:nil];
	[self iconTypeChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORPlotLinkLock to:secure];
    [plotLinkLockButton setEnabled:secure];
}

- (void) dataCatalogNameChanged:(NSNotification*)aNotification
{
	int index = (int)[dataCatalogPU indexOfItemWithTitle:[model dataCatalogName]];
	if(index == NSNotFound)	[dataCatalogPU selectItemAtIndex:0];
	else					[dataCatalogPU selectItemAtIndex:index];
}

- (void) plotLinkLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORPlotLinkLock];
    [plotLinkLockButton setState: locked];
    [plotNameField setEnabled: !locked];
}

- (void) populatePopup:(NSNotification*)aNote
{
	//to make things simple, just clear the popup and add all existing data catalogs
	//then reselect if possible
	NSArray* allDataCatalogs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORHistoModel")];
	[dataCatalogPU removeAllItems];
	[dataCatalogPU addItemWithTitle:@"No Selection"];
	for(id anObject in allDataCatalogs){
		[dataCatalogPU addItemWithTitle:[anObject fullID]];
	}
	//make the selection
	int index = (int)[dataCatalogPU indexOfItemWithTitle:[model dataCatalogName]];
	if(index == NSNotFound)	[dataCatalogPU selectItemAtIndex:0];
	else					[dataCatalogPU selectItemAtIndex:index];
}

#pragma mark •••Actions

- (void) iconTypeAction:(id)sender
{
	[model setIconType:(int)[[sender selectedCell]tag]];	
}

- (IBAction) openAltDialogAction:(id)sender
{
	[self  endEditing];	
	[model doDoubleClick:self];
}

- (IBAction) applyAction:(id)sender
{
	[self  endEditing];	
}

- (IBAction) plotNameAction:(id)sender
{
	[model setPlotName:[sender stringValue]];	
}

- (IBAction) plotLinkLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORPlotLinkLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) dataCatalogNameAction:(id)sender
{
	[model setDataCatalogName:[dataCatalogPU titleOfSelectedItem]];
}

@end
