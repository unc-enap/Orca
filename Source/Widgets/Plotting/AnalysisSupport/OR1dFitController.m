//
//  OR1dFitController.m
//  
//
//  Created by Mark Howe on Tue May 18 2004.
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


#import "OR1dFitController.h"
#import "OR1dFit.h"
#import "OR1DHistoPlot.h"
#import "ORCARootServiceDefs.h"
#import "ORCARootService.h"

@interface OR1dFitController (private)
- (void) populateFitServicePopup;
@end

@implementation OR1dFitController

+ (id) panel
{
    return [[[OR1dFitController alloc] init]autorelease];
}

-(id)	init
{
    self = [super init];
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"1dFit" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"1dFit" owner:self topLevelObjects:&topLevelObjects];
#endif
    
    [topLevelObjects retain];

	RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h
    
    return self;
}


- (void)awakeFromNib
{	
	[self populateFitServicePopup];
	[self updateWindow];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [topLevelObjects release];
    [super dealloc];
}

- (NSView*) view
{
    return fitView;
}

- (void) setModel:(id)aModel 
{
	model= aModel; 
    if(model){
		[self registerNotificationObservers];
	}
	else {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[self updateWindow];
	}
}

- (id) model { return model; }

- (void) registerNotificationObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if(!model)return;
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
        
    [notifyCenter addObserver: self
                     selector: @selector(orcaRootServiceConnectionChanged:)
                         name: ORCARootServiceConnectionChanged
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(orcaRootServiceFitChanged:)
                         name: OR1dFitChanged
                       object: model];
	
    [notifyCenter addObserver: self
                     selector: @selector(fitTypeChanged:)
                         name: OR1dFitTypeChanged
                       object: model];
	
    [notifyCenter addObserver: self
                     selector: @selector(fitFunctionChanged:)
                         name: OR1dFitFunctionChanged
                       object: model];

	[notifyCenter addObserver: self
                     selector: @selector(fitOrderChanged:)
                         name: OR1dFitOrderChanged
                       object: model];
	
	[self updateWindow];
}

- (void) updateWindow
{
    [self fitFunctionChanged:nil];
    [self fitOrderChanged:nil];
    [self fitFunctionChanged:nil];
    [self fitTypeChanged:nil];
	[self orcaRootServiceConnectionChanged:nil];
}

- (void) fitFunctionChanged:(NSNotification*)aNote
{
	NSString* s = [model fitFunction];
	if(s) [fitFunctionField setObjectValue:s];
	else [fitFunctionField setObjectValue:@""];
}

- (void) fitOrderChanged:(NSNotification*)aNote
{
	[polyOrderField setIntValue:[model fitOrder]];	
}

- (void) fitTypeChanged:(NSNotification*)aNote
{
    int fitType = [model fitType];
    [fitTypePopup selectItemAtIndex:[model fitType]];	
    [polyOrderField setEnabled: fitType == 2];
    [fitFunctionField setEnabled: fitType == 4];
    if(fitType == 4) {
        NSString* s = [model fitFunction];
        if(s) [fitFunctionField setObjectValue:s];
        else [fitFunctionField setObjectValue:@""];
    }
}


- (void) orcaRootServiceConnectionChanged:(NSNotification*)aNote
{
	BOOL fitServiceConnected = [[ORCARootService sharedORCARootService] isConnected];
	int fitType = [model fitType];
	[fitButton setEnabled:			fitServiceConnected];
	[deleteButton setEnabled:		[model fitExists]];
	[fitTypePopup setEnabled:		fitServiceConnected];
	[polyOrderField setEnabled:		fitServiceConnected && fitType == 2];
	[fitFunctionField setEnabled:	fitServiceConnected && fitType == 4];
	
	if(fitServiceConnected) {
		[serviceStatusField setTextColor:[NSColor blackColor]];
		[serviceStatusField setStringValue:@"OrcaRoot fit service running"];
	}
	else {
		[serviceStatusField setTextColor:[NSColor redColor]];
		[serviceStatusField setStringValue:@"OrcaRoot fit server NOT running"];
	}
}

- (void) orcaRootServiceFitChanged:(NSNotification*)aNote
{
	[deleteButton setEnabled: [model fitExists]];
}

- (void) endEditing
{
	//commit all text editing... subclasses should call before doing their work.
	if(![[[self view] window] endEditing]){
		[[[self view]  window] forceEndEditing];
	}
}

#pragma mark ***Actions
- (IBAction) doFitAction:(id)sender		 { [self endEditing]; [model doFit]; }
- (IBAction) deleteFitAction:(id)sender  { [model removeFit]; }
- (IBAction) fitTypeAction:(id)sender	 { [model setFitType:(int)[sender indexOfSelectedItem]]; }
- (IBAction) fitOrderAction:(id)sender   { [model setFitOrder:[sender intValue]]; }
- (IBAction) fitFunctionAction:(id)sender{ [model setFitFunction:[sender stringValue]]; }

@end

@implementation OR1dFitController (private)
- (void) populateFitServicePopup
{
    [fitTypePopup removeAllItems];
    int i;
    for(i=0;i<kNumORCARootFitTypes;i++){
        [fitTypePopup insertItemWithTitle:kORCARootFitNames[i] atIndex:i];
    }
}

@end
