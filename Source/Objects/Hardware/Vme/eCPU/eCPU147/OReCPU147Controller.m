//
//  ORfileNameFieldController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 16 2002.
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


#import "OReCPU147Controller.h"
#import "OReCPU147Model.h"
#import "ORQueueView.h"
#import "OReCPU147Config.h"


@implementation OReCPU147Controller

-(id)init
{
    self = [super initWithWindowNibName:@"eCPU147"];
	
    return self;
}


- (void) awakeFromNib
{
	[hexView setFont:[NSFont fontWithName:@"Monaco" size:9]];
	[outputView setFont:[NSFont fontWithName:@"Monaco" size:10]];
	[errorView setFont:[NSFont fontWithName:@"Monaco" size:10]];
	[messageView setFont:[NSFont fontWithName:@"Monaco" size:9]];
	[super awakeFromNib];
}


#pragma mark ¥¥¥Accessors
- (NSTextField*) fileNameField
{
    return fileNameField;
}

- (NSButton*) setFileButton
{
	return setFileButton;
}

- (NSTextView*) hexView
{
	return hexView;
}

- (NSButton*) dumpCodeButton
{
	return dumpCodeButton;
}

- (NSButton*) verifyCodeButton
{
	return verifyCodeButton;
}

- (NSButton*) diagButton
{
	return diagButton;
}

- (NSButton*) outputButton
{
	return outputButton;
}

- (NSButton*) errorButton
{
	return errorButton;
}

- (NSButton*) messageButton
{
	return messageButton;
}


- (NSDrawer*) 	diagDrawer
{
	return diagDrawer;
}

- (NSDrawer*) 	outputDrawer
{
	return outputDrawer;	
}

- (NSDrawer*) 	messageDrawer
{
	return messageDrawer;	
}

- (NSDrawer*) 	errorDrawer
{
	return errorDrawer;	
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
					 selector : @selector(fileNameChanged:)
						 name : OReCPU147FileNameChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(updateIntervalChanged:)
                         name : OReCPU147UpdateIntervalChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stuctureUpdated:)
                         name : OReCPU147StructureUpdated
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(queChanged:)
                         name : OReCPU147QueChanged
						object: model];
	
	
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [self fileNameChanged:nil];
	[self updateIntervalChanged:nil];
	[self stuctureUpdated:nil];
	[self queChanged:nil];
}

- (void) fileNameChanged:(NSNotification*)aNotification
{
	[[self fileNameField] setObjectValue: [model fileName]];
}

- (void) updateIntervalChanged:(NSNotification*)aNotification
{
	if([updateButton indexOfSelectedItem]!=[model updateInterval]){
		[updateButton selectItemAtIndex:[updateButton indexOfItemWithTag:[model updateInterval]]];
    }
}

- (void) stuctureUpdated:(NSNotification*)aNotification
{
	if([outputDrawer state] == NSDrawerOpenState){
		eCPU_MAC_DualPortComm communicationBlock = [model communicationBlock];
		SCBHeader 			  cbHeader 			 = [model cbControlBlockHeader];
		eCPUDualPortControl   dualPortControl 	 = [model dualPortControl];
		
		NSMutableString* s1 =  [NSMutableString stringWithFormat:@"Heart beat     : %-12u   Status  : %-u\n",communicationBlock.heartbeat,communicationBlock.ecpu_status];
		[s1 appendFormat:@"CB Head        : %-10u     Debug   : %-u\n", (uint32_t)cbHeader.qHead,dualPortControl.ecpu_dbg_level];
		[s1 appendFormat:@"CB Tail        : %-10u     Errors  : %-u\n", (uint32_t)cbHeader.qTail,communicationBlock.tot_err_cnt];
		[s1 appendFormat:@"Bytes Written  : %-10d     DPM Full: %-u\n",cbHeader.bytesWritten,communicationBlock.CB_err_dpm_buf_full_cnt];
		[s1 appendFormat:@"Bytes Read     : %d\n",cbHeader.bytesRead];
		[s1 appendFormat:@"Blocks Written : %-10d     Rqt Flag: %-u\n",cbHeader.blocksWritten,dualPortControl.ro_control_rqst];
		[s1 appendFormat:@"Blocks Read    : %d\n",cbHeader.blocksRead];
		[s1 appendFormat:@"Write Sentinel : 0x%0x\n",cbHeader.writeSentinel];
		NSString* versionString = [[[NSString alloc] initWithBytes:&communicationBlock.version length:4 encoding:NSASCIIStringEncoding]autorelease];
		[s1 appendFormat:@"Read Sentinel  : 0x%-10x   Version : %@\n",cbHeader.readSentinel,versionString];
		
		int i;
		[s1 appendFormat:@"\nHardware counters\n"];
		for(i=0;i<HW_MAX_COUNT;i++){
			[s1 appendFormat:@"%2d Err: %-10u lp: %-10u tot: %-u\n",i,communicationBlock.rd_error_cnt[i],communicationBlock.loop_cnt[i],communicationBlock.total_rate_cnt[i]];
		}
		
		[outputView setString:s1];
		[outputView sizeToFit];
	}
	else if([messageDrawer state] == NSDrawerOpenState){
		eCPUDualPortControl   dualPortControl 	 = [model dualPortControl];
		int i;
		NSMutableString* aString = [NSMutableString stringWithCapacity:512];
		for(i=0;i<DPM_MON_BUF_SIZE;i++){
			[aString appendString:[model messageString:i]];
		}
		[messageView setString:aString];
		[debugLevelField setStringValue:[NSString stringWithFormat:@"Debug: %-u\n",dualPortControl.ecpu_dbg_level]];
	}
	else if([errorDrawer state] == NSDrawerOpenState){
		int i;
		NSMutableString* aString = [NSMutableString stringWithCapacity:512];
		
		for(i=0;i<DPM_MON_BUF_SIZE;i++){
			[aString appendString:[model errorString:i]];
		}
		[errorView setString:aString];
		
	}
	
}

- (void) queChanged:(NSNotification*)aNotification
{
	[queueView setNeedsDisplay:YES];
}


#pragma mark ¥¥¥Actions

- (IBAction) download:(id)sender
{
	@try {
		[model downloadUserCode];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception thrown trying to download user code.\n");
		ORRunAlertPanel([localException name], @"%@\nCould not download.", @"OK", nil, nil,
						localException);
	}
}

- (IBAction) start:(id)sender
{
	@try {
		[model startUserCodeWithRetries:0];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception thrown trying to start user code.\n");
		ORRunAlertPanel([localException name], @"%@\nCould not start user code.", @"OK", nil, nil,
						localException);
	}
}

- (IBAction) stop:(id)sender
{
	@try {
		[model stopUserCode];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception thrown trying to stop user code.\n");
		ORRunAlertPanel([localException name], @"%@\nCould not stop user code.", @"OK", nil, nil,
						localException);
	}
}

- (IBAction) setUpdateIntervalAction:(id)sender
{
    [model setUpdateInterval:(NSTimeInterval)[[sender selectedItem] tag]];
}

- (IBAction) updateNowAction:(id)sender
{
    [model update];
}

- (IBAction) incDebugLevelAction:(id)sender
{
    [model incDebugLevel];
    [model update];
}


- (IBAction) dump:(id)sender
{
    @try {
		uint32_t startAddress = 0;
		uint32_t numBytes = 0;
		NSData* buffer = nil;
		if(sender == [self dumpCodeButton]){
			startAddress = USER_CODE_ADDRESS;
			uint32_t len = [model codeLength];
			numBytes = (len==0?0x100:len);
			buffer = [model dumpCodeFrom:startAddress length:numBytes];
		}
		
		[hexView replaceCharactersInRange:NSMakeRange(0,[[hexView string] length]) withString:@""];
		
		int i;
		uint32_t offset = 0;
		const unsigned char* p = (const unsigned char*)[buffer bytes];
		while(1){
			NSMutableString* lineString = [[NSMutableString alloc] initWithCapacity:256];
			[lineString setString:[NSString stringWithFormat:@"%0x: ",startAddress+offset]];
			for(i=0;i<0x10;i++){
				[lineString appendFormat:@"%02x ",*(p+offset)];				
				offset++;
				if(offset >= numBytes)break;
			}
			[lineString appendFormat:@"\n"];
			[hexView replaceCharactersInRange:NSMakeRange([[hexView string] length], 0) withString:lineString];
			if(offset >= numBytes) break;
		}
	}
	@catch(NSException* localException) {
		NSLog(@"Could not dump memory from eCPU.\n");
		ORRunAlertPanel([localException name], @"%@\nCould not dump memory from eCPU.", @"OK", nil, nil,
						localException);
	}
}

- (IBAction) verifyCodeAction:(id)sender
{
    @try {
		[model verifyCode];
    }
	@catch(NSException* localException) {
		NSLog(@"Could not dump memory from eCPU.\n");
		ORRunAlertPanel([localException name], @"%@\nCould not dump memory from eCPU.", @"OK", nil, nil,
						localException);
    }
	
}

- (IBAction) selectFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Choose"];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSString* filename = [[[openPanel URL]path ]stringByAbbreviatingWithTildeInPath];
            [model setFileName:filename];
       }
    }];
}

#pragma mark ¥¥¥Queue DataSource

- (void) getQueMinValue:(uint32_t*)aMinValue maxValue:(uint32_t*)aMaxValue head:(uint32_t*)aHeadValue tail:(uint32_t*)aTailValue
{
	[model getQueMinValue:aMinValue maxValue:aMaxValue head:aHeadValue tail:aTailValue];
}

- (void)drawerWillOpen:(NSNotification *)notification
{
	if([notification object] == diagDrawer){
		[outputDrawer close];
		[messageDrawer close];
		[errorDrawer close];
	}
	else if([notification object] == messageDrawer){
		[outputDrawer close];
		[diagDrawer close];
		[errorDrawer close];
	}
	else if([notification object] == errorDrawer){
		[outputDrawer close];
		[diagDrawer close];
		[messageDrawer close];
	}
	else if([notification object] == outputDrawer){
		[diagDrawer close];
		[errorDrawer close];
		[messageDrawer close];
	}
}


- (void)drawerDidOpen:(NSNotification *)notification
{
	if([notification object] == diagDrawer){
		[[self diagButton] setTitle:@"Close Drawer"];		
	}
	else if([notification object] == errorDrawer){
		[[self errorButton] setTitle:@"Close Drawer"];		
	}
	else if([notification object] == messageDrawer){
		[[self messageButton] setTitle:@"Close Drawer"];		
	}
	
	else if([notification object] == outputDrawer){
		[[self outputButton] setTitle:@"Close Drawer"];		
	}
}

- (void)drawerDidClose:(NSNotification *)notification
{
	if([notification object] == diagDrawer){
		[[self diagButton] setTitle:@"Diagnostics..."];		
	}
	else if([notification object] == errorDrawer){
		[[self errorButton] setTitle:@"Errors..."];		
	}
	else if([notification object] == messageDrawer){
		[[self messageButton] setTitle:@"Messages..."];		
	}
	else if([notification object] == outputDrawer){
		[[self outputButton] setTitle:@"Output..."];	
	}
}
@end
