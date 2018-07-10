//
//  ORFifoController.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORFifoController.h"
#import "ORFifoModel.h"

#import "ThreadWorker.h"

#pragma mark ¥¥¥Definitions
#define FIFO_INTERRUPT_VECTOR_REGISTER	0
#define FIFO_CSR_REGISTER				1
#define FIFO_DATA_REGISTER				2
#define FIFO_RESET_REGISTER				3

@implementation ORFifoController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Fifo"];
	
	return self;
}

- (void) dealloc
{
	
	[readWriteTestThread markAsCancelled];
	[readWriteTestThread release];
	readWriteTestThread = nil;
	
	[super dealloc];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORVmeCardSlotChangedNotification
                       object : model];
}

- (void) updateWindow
{
    [super updateWindow];
	[self slotChanged:nil];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"IPFIFO (%@)",[(ORFifoModel*)model identifier]]];
}

#pragma mark ¥¥¥Actions

-(IBAction)reset:(id)sender
{
	@try {
		[self endEditing];
		[model resetFifo];
	}
	@catch(NSException* localException) {
		ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
						localException);
	}
	
}


-(IBAction)status:(id)sender
{
    unsigned short sdata;
	@try {
		[self endEditing];
		[model readFifo:FIFO_CSR_REGISTER atPtr:&sdata];
	}
	@catch(NSException* localException) {
		ORRunAlertPanel([localException name], @"%@\nStatus Reg: %d", @"OK", nil, nil,
						localException,sdata);
	}
	NSLog(@"Fifo Status: %d\n",sdata);
	
}

-(IBAction)loadUnloadTest:(id)sender
{
    // run FIFO block load/unload test
	@try {
		[self endEditing];
		[model blockLoadUnloadTest];
	}
	@catch(NSException* localException) {
		ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
						localException);
		NSLog(@"*** FIFO Block Load/Unload Test Failed ***\n");
	}
}

-(IBAction)readWriteTest:(id)sender
{
	@try {
		[self endEditing];
		
		if(!readWriteTestThread){
			[blockLoadTestControl setEnabled:NO];
			[readWriteTestControl setEnabled:NO];
			[readWriteTestControl setTitle:@"Stop Test"];
			NSMutableDictionary *params = [NSMutableDictionary dictionary];
			[params setObject:progressView forKey:@"Progress"];
			[params setObject:model forKey:@"Model"];
			
			readWriteTestThread = [[ThreadWorker workOn:self
										   withSelector:@selector(runWriteReadTest:thread:)
										     withObject:params
										 didEndSelector:@selector(writeReadTestFinished:)] retain];
			
			NSLog(@"*** FIFO Block Read/Write Test Started ***\n");
		}
		else {
			[readWriteTestThread markAsCancelled];
			[readWriteTestControl setTitle:@"Read/Write"];
			NSLog(@"*** FIFO Block Read/Write Test Stopped ***\n");
		}
		
		[readWriteTestControl setEnabled:YES];
		
		
	}
	@catch(NSException* localException) {
		ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
						localException);
		NSLog(@"*** FIFO Block Read/Write Test Failed ***\n");
	}
}

#pragma mark ¥¥¥Thread Worker Methods
- (id) runWriteReadTest:(NSDictionary*)userInfo thread:tw
{
	
	unsigned short j;
	NSDictionary* params = userInfo;
	NSProgressIndicator* progress = [params objectForKey:@"Progress"];
	id theModel = [params objectForKey:@"Model"];
	[progress setDoubleValue:0.];
	
	@try {
		
		[theModel setupTestMode];
		
		for(j=1;j<=4096;j++){
			if([tw cancelled])break;
			[theModel writeLocationTest: j];
			[progress setDoubleValue:50*j/4095.];
		}	
		
		for(j=1;j<=4096;j++){
			if([tw cancelled])break;
			[theModel readLocationTest: j];
			[progress setDoubleValue:50 + 50*j/4095.];
		}
		
		
	}
	@catch(NSException* localException) {
		ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
						localException);
		NSLog(@"*** FIFO Block Read/Write Test Failed ***\n");
	}
	
	
	[progress setDoubleValue:100.];
	return @"done";
}


- (void) writeReadTestFinished:(NSDictionary*)userInfo
{
	if(![readWriteTestThread cancelled]){
		NSLog(@"*** FIFO Block Read/Write Test Finished ***\n");
	}
	[blockLoadTestControl setEnabled:YES];
	[readWriteTestThread release];
	readWriteTestThread = nil;
	[readWriteTestControl setTitle:@"Read/Write"];
}
@end
