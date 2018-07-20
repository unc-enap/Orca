//
//  ORFFTController.m
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


#import "ORFFTController.h"
#import "ORFFT.h"
#import "OR1DHistoPlot.h"
#import "ORCARootServiceDefs.h"
#import "ORCARootService.h"

@interface ORFFTController (private)
- (void) populateFFTServicePopup;
- (void) populateFFTWindowPopup;
@end

@implementation ORFFTController

+ (id) panel
{
    return [[[ORFFTController alloc] init]autorelease];
}

-(id)	init
{
    self = [super init];
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"FFT" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"FFT" owner:self topLevelObjects:&topLevelObjects];
#endif
    
    [topLevelObjects retain];

	RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h
    
    return self;
}


- (void)awakeFromNib
{	
	[self populateFFTServicePopup];
	[self populateFFTWindowPopup];
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
    return fftView;
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
                     selector: @selector(fftOptionChanged:)
                         name: ORFFTOptionChanged
                       object: model];
	
	[notifyCenter addObserver: self
                     selector: @selector(fftWindowChanged:)
                         name: ORFFTWindowChanged
                       object: model];
	
	[self updateWindow];
}

- (void) updateWindow
{
    [self fftOptionChanged:nil];
    [self fftWindowChanged:nil];
	[self orcaRootServiceConnectionChanged:nil];
}

- (void) fftOptionChanged:(NSNotification*)aNote
{
	[fftOptionPopup selectItemAtIndex:[model fftOption]];	
}

- (void) fftWindowChanged:(NSNotification*)aNote
{
	[fftWindowPopup selectItemAtIndex:[model fftWindow]];	
}

- (void) orcaRootServiceConnectionChanged:(NSNotification*)aNote
{
	BOOL fitServiceConnected = [[ORCARootService sharedORCARootService] isConnected];
	[fftButton setEnabled:			fitServiceConnected];
	[fftWindowPopup setEnabled:		fitServiceConnected];
	[fftOptionPopup setEnabled:		fitServiceConnected];
	
	if(fitServiceConnected) {
		[serviceStatusField setTextColor:[NSColor blackColor]];
		[serviceStatusField setStringValue:@"OrcaRoot fit service running"];
	}
	else {
		[serviceStatusField setTextColor:[NSColor redColor]];
		[serviceStatusField setStringValue:@"OrcaRoot fit server NOT running"];
	}
}


#pragma mark ***Actions
- (IBAction) doFFTAction:(id)sender		 { [model doFFT]; }
- (IBAction) fftOptionAction:(id)sender  { [model setFftOption:(uint32_t)[sender indexOfSelectedItem]]; }
- (IBAction) fftWindowAction:(id)sender  { [model setFftWindow:(uint32_t)[sender indexOfSelectedItem]]; }

@end

@implementation ORFFTController (private)
- (void) populateFFTServicePopup
{
    [fftOptionPopup removeAllItems];
    int i;
    for(i=0;i<kNumORCARootFFTOptions;i++){
        [fftOptionPopup insertItemWithTitle:kORCARootFFTNames[i] atIndex:i];
    }
}

- (void) populateFFTWindowPopup
{
    [fftWindowPopup removeAllItems];
    int i;
    for(i=0;i<kNumORCARootFFTWindows;i++){
        [fftWindowPopup insertItemWithTitle:kORCARootFFTWindowNames[i] atIndex:i];
    }
}

@end
