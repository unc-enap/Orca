//
//  ORReplayFileController.m
//  Orca
//
//  Created by Rielage on Thu Oct 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#pragma mark •••Imported Files
#import "ORReplayFileController.h"
#import "ORReplayFileModel.h"

@implementation ORReplayFileController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"DataFile"];
    return self;
}


#pragma mark •••Accessors
- (NSButton*) chooseDirButton
{
	return chooseDirButton;
}

- (NSTextField*) dirTextField
{
	return dirTextField;
}

- (NSTextField*) fileTextField
{
	return fileTextField;	
}

- (NSTextField*) statusTextField
{
	return statusTextField;	
}

- (NSTextField*) sizeTextField
{
	return sizeTextField;
}

- (NSTextField*) remotePathField
{
	return remotePathField;
}

- (NSTextField*) remoteHostField
{
	return remoteHostField;
}

- (NSTextField*) userNameField
{
	return userNameField;
}

- (NSSecureTextField*) passWordField
{
	return passWordField;
}

- (NSTextField*) copyStateField
{
	return copyStateField;
}

- (NSTextField*) deleteStateField
{
	return deleteStateField;
}

- (NSTextField*) copyStatusField
{
	return copyStatusField;
}

- (NSTextField*) deleteStatusField
{
	return deleteStatusField;
}


- (NSMatrix*) transferTypeMatrix
{
	return transferTypeMatrix;
}

- (NSButton*) verboseButton
{
	return verboseButton;
}


#pragma  mark •••Actions
- (IBAction) chooseDir:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Choose"];
	[openPanel beginSheetForDirectory:NSHomeDirectory()
							  file:nil
							 types:nil
					modalForWindow:[self window]
					 modalDelegate:self
					didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
					   contextInfo:NULL];

}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if(returnCode){
		NSString* directoryName = [[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath];
		[[self model] setDirectoryName:directoryName];
	}
}

- (IBAction) copyEnableAction:(id)sender
{
	if([sender intValue] != [[self model] copyEnabled]){
		[[self undoManager] setActionName: @"Set Copy Enabled"];
		[[self model] setCopyEnabled:[sender intValue]];		
	}

}

- (IBAction) deleteWhenDoneAction:(id)sender
{
	if([sender intValue] != [[self model] deleteWhenCopied]){
		[[self undoManager] setActionName: @"Set Delete When Copied"];
		[[self model] setDeleteWhenCopied:[sender intValue]];		
	}
}

- (IBAction) copyStatusEnableAction:(id)sender
{
	if([sender intValue] != [[self model] copyStatusEnabled]){
		[[self undoManager] setActionName: @"Set Copy Status Enabled"];
		[[self model] setCopyStatusEnabled:[sender intValue]];		
	}

}

- (IBAction) deleteStatusWhenDoneAction:(id)sender
{
	if([sender intValue] != [[self model] deleteStatusWhenCopied]){
		[[self undoManager] setActionName: @"Set Delete Status When Copied"];
		[[self model] setDeleteStatusWhenCopied:[sender intValue]];		
	}
}


- (IBAction) userNameAction:(id)sender
{
	if([sender stringValue] != [[self model] remoteUserName]){
		[[self undoManager] setActionName: @"Set User Name"];
		[[self model] setRemoteUserName:[sender stringValue]];		
	}
}

- (IBAction) remotePathAction:(id)sender
{
	if([sender stringValue] != [[self model] remotePath]){
		[[self undoManager] setActionName: @"Set Remote Path"];
		[[self model] setRemotePath:[sender stringValue]];		
	}
}

- (IBAction) remoteHostAction:(id)sender
{
	if([sender stringValue] != [[self model] remoteHost]){
		[[self undoManager] setActionName: @"Set Remote Host"];
		[[self model] setRemoteHost:[sender stringValue]];		
	}
}

- (IBAction) passWordAction:(id)sender
{
	if([sender stringValue] != [[self model] passWord]){
		[[self undoManager] setActionName: @"Set Password"];
		[[self model] setPassWord:[sender stringValue]];		
	}
}

- (IBAction) transferTypeAction:(id)sender
{
	int tag = [[[self transferTypeMatrix] selectedCell] tag];
	if(tag != [[self model] transferType]){
		[[self undoManager] setActionName: @"Set File Transfer Mode"];
		[[self model] setTransferType:tag];
	}
}

- (IBAction) verboseAction:(id)sender
{
	if([sender state] != [[self model] verbose]){
		[[self undoManager] setActionName: @"Set File Transfer Verbose Mode"];
		
		[[self model] setVerbose:[sender state]];
	}
}

- (IBAction) sendAllAction:(id)sender
{
	int choice = NSRunAlertPanel(@"Send All Unsent Files?",@"Clicking 'Send' will send all files.",@"Cancel",@"Send",nil);
	if(choice == NSAlertAlternateReturn){
		[[self model] sendAll];
	}
}

- (IBAction) deleteAllAction:(id)sender
{
	int choice = NSRunAlertPanel(@"Delete All Sent Files?",@"Clicking 'Delete' will delete all files in the Sent folder",@"Cancel",@"Delete",nil);
	if(choice == NSAlertAlternateReturn){
		[[self model] deleteAll];
	}
}


#pragma mark •••Interface Management
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(dirChanged:)
                         name : ORReplayDirChangedNotification
                       object: [self model]];

    [notifyCenter addObserver : self
                     selector : @selector(fileChanged:)
                         name : ORReplayFileChangedNotification
                       object: [self model]];

    [notifyCenter addObserver : self
                     selector : @selector(fileStatusChanged:)
                         name : ORReplayFileStatusChangedNotification
                       object: [self model]];

	[notifyCenter addObserver : self
				  selector : @selector(fileSizeChanged:)
					  name : ORReplayFileSizeChangedNotification
					object: [self model]];


	[notifyCenter addObserver : self
				  selector : @selector(copyEnabledChanged:)
					  name : ORReplayFileCopyEnabledChangedNotification
					object: [self model]];

	[notifyCenter addObserver : self
				  selector : @selector(deleteWhenCopiedChanged:)
					  name : ORReplayFileDeleteWhenCopiedChangedNotification
					object: [self model]];

	[notifyCenter addObserver : self
				  selector : @selector(copyStatusEnabledChanged:)
					  name : ORReplayFileCopyStatusEnabledChangedNotification
					object: [self model]];

	[notifyCenter addObserver : self
				  selector : @selector(deleteStatusWhenCopiedChanged:)
					  name : ORReplayFileDeleteStatusWhenCopiedChangedNotification
					object: [self model]];


	[notifyCenter addObserver : self
				  selector : @selector(remotePathChanged:)
					  name : ORReplayFileRemotePathChangedNotification
					object: [self model]];


	[notifyCenter addObserver : self
				  selector : @selector(remoteHostChanged:)
					  name : ORReplayFileRemoteHostChangedNotification
					object: [self model]];

	[notifyCenter addObserver : self
				  selector : @selector(passWordChanged:)
					  name : ORReplayFilePassWordChangedNotification
					object: [self model]];

	[notifyCenter addObserver : self
				  selector : @selector(userNameChanged:)
					  name : ORReplayFileUserNameChangedNotification
					object: [self model]];


	[notifyCenter addObserver : self
				  selector : @selector(transferTypeChanged:)
					  name : ORReplayFileTransferTypeChangedNotification
					object: [self model]];

	[notifyCenter addObserver : self
				  selector : @selector(verboseChanged:)
					  name : ORReplayFileVerboseChangedNotification
					object: [self model]];


}

- (void) updateWindow
{
	[self dirChanged:nil];
	[self fileChanged:nil];
	[self fileStatusChanged:nil];

	[self copyEnabledChanged:nil];
	[self deleteWhenCopiedChanged:nil];
	[self copyStatusEnabledChanged:nil];
	[self deleteStatusWhenCopiedChanged:nil];
	[self remotePathChanged:nil];
	[self remoteHostChanged:nil];
	[self passWordChanged:nil];
	[self transferTypeChanged:nil];
	[self verboseChanged:nil];
	[self userNameChanged:nil];
}


#pragma mark •••Interface Management
- (void) dirChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		if([[self model] directoryName]!=nil)[[self dirTextField] setStringValue: [[self model] directoryName]];
		[self fileStatusChanged:nil];
	}
}

- (void) fileChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		if([[self model] fileName]!=nil)[[self fileTextField] setStringValue: [[self model] fileName]];
		[self fileStatusChanged:nil];
	}
	
	[self fileStatusChanged:nil];
	
}

- (void) fileStatusChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		if([[self model]filePointer]){
			[[self statusTextField] setStringValue: @"Running / File Is Open"];			
		}
		else {
			[[self statusTextField] setStringValue: @"Not Running"];			
		}
	}	
}

- (void) fileSizeChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		[[self sizeTextField] setStringValue: [NSString stringWithFormat:@"%.2f KB",[[self model] dataFileSize]/1000.]];
	}
}

- (void) copyEnabledChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		[copyButton setState:[[self model]copyEnabled]];
		if([[self model]copyEnabled]){
			[[self copyStateField] setStringValue: @"YES"];
		}
		else {
			[[self copyStateField] setStringValue: @"NO"];			
		}
		
		BOOL enable = [[self model]copyEnabled] || [[self model]copyStatusEnabled];
		[deleteButton setEnabled:[[self model]copyEnabled]];
		[deleteStatusButton setEnabled:[[self model]copyStatusEnabled]];
		[remoteHostField setEnabled:enable];
		[remotePathField setEnabled:enable];
		[userNameField setEnabled:enable];
		[passWordField setEnabled:enable];
		
		[transferTypeMatrix setEnabled:enable];
		[verboseButton setEnabled:enable];
		
	}
}

- (void) deleteWhenCopiedChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		[deleteButton setState:[[self model]deleteWhenCopied]];
		if([[self model]deleteWhenCopied]){
			[[self deleteStateField] setStringValue: @"YES"];			
		}
		else {
			[[self deleteStateField] setStringValue: @"NO"];			
		}
	}
}

- (void) copyStatusEnabledChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		[copyStatusButton setState:[[self model]copyStatusEnabled]];
		if([[self model]copyStatusEnabled]){
			[[self copyStatusField] setStringValue: @"YES"];
		}
		else {
			[[self copyStatusField] setStringValue: @"NO"];			
		}
		
		BOOL enable = [[self model]copyEnabled] || [[self model]copyStatusEnabled];
		[deleteButton setEnabled:[[self model]copyEnabled]];
		[deleteStatusButton setEnabled:[[self model]copyStatusEnabled]];
		[remoteHostField setEnabled:enable];
		[remotePathField setEnabled:enable];
		[userNameField setEnabled:enable];
		[passWordField setEnabled:enable];
		
		[transferTypeMatrix setEnabled:enable];
		[verboseButton setEnabled:enable];
		
	}
}

- (void) deleteStatusWhenCopiedChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		[deleteStatusButton setState:[[self model]deleteStatusWhenCopied]];
		if([[self model]deleteStatusWhenCopied]){
			[[self deleteStatusField] setStringValue: @"YES"];			
		}
		else {
			[[self deleteStatusField] setStringValue: @"NO"];			
		}
	}
}



- (void) remotePathChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		[remotePathField setObjectValue:[[self model] remotePath]];
	}
}

- (void) remoteHostChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		[remoteHostField setObjectValue:[[self model] remoteHost]];
	}
}

- (void) passWordChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		[passWordField setObjectValue:[[self model] passWord]];
	}
}

- (void) transferTypeChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		[[self transferTypeMatrix] selectCellWithTag: [[self model] transferType] ];
	}
}

- (void) verboseChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		[[self verboseButton] setState: [[self model] verbose] ];
	}
}


- (void) userNameChanged:(NSNotification*)note
{
	if([self notificationForUs:note]){
		[userNameField setObjectValue:[[self model] remoteUserName]];
	}
}

@end

