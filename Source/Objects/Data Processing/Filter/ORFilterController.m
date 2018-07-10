//
//  ORFilterController.m
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


#pragma mark •••Imported Files
#import "ORFilterController.h"
#import "ORFilterModel.h"
#import "ORTimedTextField.h"
#import "ORScriptView.h"
#import "ORScriptRunner.h"
#import "ORDataPacket.h"
#import "ORPlotView.h"
#import "ORCompositePlotView.h"
#import "OR1DHistoPlot.h"

@implementation ORFilterController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Filter"];
	return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[statusField setTimeOut:1.5];
	NSString*   path = [[NSBundle mainBundle] pathForResource: @"FilterScriptGuide" ofType: @"rtf"];
	[helpView readRTFDFromFile:path];
	[scriptView setSyntaxDefinitionFilename:@"FilterSyntaxDefinition"];
	[scriptView recolorCompleteFile:self];
	
	[timePlot setXLabel:@"Record Process Time (µS)"];
	OR1DHistoPlot* aPlot = [[OR1DHistoPlot alloc] initWithTag:0 andDataSource:self];
	[timePlot addPlot: aPlot];
	[aPlot release];
}


#pragma mark •••Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];

	[notifyCenter addObserver: self 
					 selector: @selector(scriptChanged:) 
						 name: ORFilterScriptChanged 
					   object: model];
	
 //   [notifyCenter addObserver : self
 //                    selector : @selector(nameChanged:)
 //                        name : ORFilterNameChanged
//						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(textDidChange:)
                         name : NSTextDidChangeNotification
						object: scriptView];	

    [notifyCenter addObserver : self
                     selector : @selector(lastFileChanged:)
                         name : ORFilterLastFileChangedChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORFilterLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
					   
   [notifyCenter addObserver : self
                     selector : @selector(displayValuesChanged:)
                         name : ORFilterDisplayValuesChanged
                       object : model];
					   
   [notifyCenter addObserver : self
                     selector : @selector(timerEnabledChanged:)
                         name : ORFilterTimerEnabledChanged
                       object : model];

   [notifyCenter addObserver : self
                     selector : @selector(updateTiming:)
                         name : ORFilterUpdateTiming
                       object : model];

   [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : inputVariablesTableView];

   [notifyCenter addObserver : self
                     selector : @selector(pluginPathChanged:)
                         name : ORFilterModelPluginPathChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pluginValidChanged:)
                         name : ORFilterModelPluginValidChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(usePluginChanged:)
                         name : ORFilterModelUsePluginChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(inputValuesChanged:)
                         name : ORFilterInputValuesChanged
						object: model];
	

}

- (void) updateWindow
{
    [super updateWindow];
	[self scriptChanged:nil];
	[self lastFileChanged:nil];
	[self timerEnabledChanged:nil];
	[self pluginPathChanged:nil];
	[self pluginValidChanged:nil];
	[self usePluginChanged:nil];
	[self inputValuesChanged:nil];
	[codeHelperPU selectItemAtIndex:0];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self checkGlobalSecurity];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORFilterLock to:secure];
    [lockButton setEnabled:secure];
	[removeInputButton setEnabled:[[inputVariablesTableView selectedRowIndexes] count] >0];
}


#pragma mark •••Interface Management

- (void) usePluginChanged:(NSNotification*)aNote
{
	[usePluginMatrix selectCellWithTag: [model usePlugin]];
	[self setLabelFields];
}

- (void) setLabelFields
{
	if([model usePlugin]){
		[typeField setStringValue:@"Plugin:"];
		[lastFileField setStringValue:[[[model pluginPath] lastPathComponent] stringByDeletingPathExtension]];
	}
	else {
		[typeField setStringValue:@"Script:"];
		[lastFileField setStringValue:[[model lastFile] stringByAbbreviatingWithTildeInPath]];
	}

}

- (void) pluginValidChanged:(NSNotification*)aNote
{
	[pluginValidField setStringValue: [model pluginValid]?@"YES":@"NO"];
	[pluginValidField setTextColor:[model pluginValid] ? 
												[NSColor colorWithCalibratedRed:0 green:.5 blue:0 alpha:1] :
												[NSColor colorWithCalibratedRed:.5 green:0 blue:0 alpha:1]];
}

- (void) pluginPathChanged:(NSNotification*)aNote
{
	[pluginPathField setStringValue: [[[model pluginPath] stringByAbbreviatingWithTildeInPath] stringByDeletingLastPathComponent]];
	[pluginNameField setStringValue: [[[model pluginPath] lastPathComponent] stringByDeletingPathExtension]];
	[self setLabelFields];
}


- (void) lockChanged:(NSNotification*)aNotification
{
	BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:ORFilterLock];
    [lockButton setState: locked];
	[parseButton setEnabled:!locked && !runInProgress];
	if(runInProgress){
		[codeHelperPU setEnabled:NO];
		[insertCodeButton setEnabled:NO];
	}
	else {
		[codeHelperPU setEnabled:YES];
		[insertCodeButton setEnabled:YES];
	}
}

- (void) updateTiming:(NSNotification*)aNote
{
	[timePlot setNeedsDisplay:YES];
}

- (void) lastFileChanged:(NSNotification*)aNote
{
	[self setLabelFields];
}

- (void) textDidChange:(NSNotification*)aNote
{
	[model setScriptNoNote:[scriptView string]];
}

- (void) timerEnabledChanged:(NSNotification*)aNote
{
	[timerEnabledCB setState:[model timerEnabled]];
	[timePlot setNeedsDisplay:YES];
}

- (void) scriptChanged:(NSNotification*)aNote
{
	[scriptView setString:[model script]];
}

- (void) displayValuesChanged:(NSNotification*)aNote
{
	[outputVariablesTableView reloadData];
}

- (void) inputValuesChanged:(NSNotification*)aNote
{
	[inputVariablesTableView reloadData];
}

#pragma mark •••Actions

- (IBAction) insertCode:(id) sender
{
	NSString* stringToInsert = @"";
	switch ([codeHelperPU indexOfSelectedItem]) {
		case 0: stringToInsert = @"start {\n}\nfilter {\n}\nfinish {\n}";	break;
		case 1: stringToInsert = @"for(<var> = <start> ; <var> < <end> ; <var>++) {\n}";	break;
		case 2: stringToInsert = @"while (<condition>) {\n}";	break;
		case 3: stringToInsert = @"do {\n}while(<condition>);";	break;
		case 4: stringToInsert = @"if (<condition>) {\n}";	break;
		case 5: stringToInsert = @"if (<condition>) {\n}\nelse {\n}";	break;
		case 6: stringToInsert = @"switch (<condition>) {\n\t case <item>:\n\t\t<statement>\n\tbreak;\n\tdefault:\n\t\t<statement>\n\tbreak;\n}";	break;
		case 7: stringToInsert = @"case <item>:\n\t\t<statement>\n\tbreak;";	break;
		default:break;
	}
	if([stringToInsert length]){
        NSRange insertRange = [scriptView selectedRange];
        if(insertRange.location != NSNotFound) [scriptView insertText:stringToInsert replacementRange:insertRange];
	}
}

- (IBAction) listDecoders:(id)sender
{
    NSArray* objectList = [NSArray arrayWithArray:[[model document]collectObjectsRespondingTo:@selector(dataRecordDescription)]];
    NSEnumerator* e = [objectList objectEnumerator];
	NSMutableArray* decoderList = [NSMutableArray array];
    id obj;
    while(obj = [e nextObject]){
        NSDictionary* decoderDictionary = [obj dataRecordDescription];
		NSEnumerator* e1 = [decoderDictionary keyEnumerator];
		id aKey;
		while(aKey = [e1 nextObject]){
			NSDictionary* entry = [decoderDictionary objectForKey:aKey];
			NSString* decoderName = [entry objectForKey:@"decoder"];
			if(decoderName){
				if(![decoderList containsObject:decoderName]){
					[decoderList addObject:decoderName];
				}
			}
		}
    }
	if([decoderList count]){
		NSLog(@"\n");
		NSLog(@"Record IDs in the FilterScript Symbol Table:\n");
		NSLog(@"%@\n",[decoderList sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]);
	}
}

- (IBAction) usePluginAction:(id)sender
{
	[model setUsePlugin:[[sender selectedCell] tag]];	
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORFilterLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) addInput:(id)sender
{
	[model addInputValue];
	[inputVariablesTableView reloadData];
}

- (IBAction) removeInput:(id)sender
{
	NSIndexSet* indexSet = [inputVariablesTableView selectedRowIndexes];
	NSUInteger i;
	NSUInteger last = [indexSet lastIndex];
	for(i=last;i!=NSNotFound;i = [indexSet indexLessThanIndex:i]){
		[model removeInputValue:i];
	}
	[inputVariablesTableView reloadData];
}

- (IBAction) selectPluginPath:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[model pluginPath] stringByExpandingTildeInPath];
    if(fullPath) startingDir = [fullPath stringByDeletingLastPathComponent];
    else		 startingDir = NSHomeDirectory();

    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setPluginPath:[[[openPanel URL] path] stringByAbbreviatingWithTildeInPath]];
            [model loadPlugin]; 
        }
    }];
}

- (IBAction) enableTimer:(id)sender
{
	[model setTimerEnabled:[sender state]];
}

- (IBAction) listMethodsAction:(id) sender
{
	NSString* theClassName = [classNameField stringValue];
	if([theClassName length]){
		NSLog(@"\n%@\n",listMethods(NSClassFromString(theClassName)));
	}
}

- (IBAction) cancelLoadSaveAction:(id)sender
{
	[loadSaveView orderOut:self];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    [[[NSApplication sharedApplication]keyWindow]  endSheet:loadSaveView];
#else
    [[NSApplication sharedApplication]  endSheet:loadSaveView];
#endif
}

- (IBAction) parseScript:(id) sender
{
	[statusField setStringValue:@""];	
	[self endEditing];
	[model setScript:[scriptView string]];
	[model parseScript];
	if([model parsedOK])[statusField setStringValue:@"Parsed OK"];
	else [statusField setStringValue:@"ERRORS"];
}
	
- (IBAction) nameAction:(id) sender
{
	[model setScriptName:[sender stringValue]];
	[[self window] setTitle:[NSString stringWithFormat:@"Script: %@",[sender stringValue]]];
}

- (IBAction) loadSaveAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    [[self window] beginSheet:loadSaveView completionHandler:nil];
#else
    [[NSApplication sharedApplication] beginSheet:loadSaveView
                                   modalForWindow:[self window]
                                    modalDelegate:self
                                   didEndSelector:NULL
                                      contextInfo:NULL];
#endif
	[self setLabelFields];
}


- (IBAction) loadFileAction:(id) sender
{
	[loadSaveView orderOut:self];
    
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    [[[NSApplication sharedApplication]keyWindow]  endSheet:loadSaveView];
#else
    [[NSApplication sharedApplication]  endSheet:loadSaveView];
#endif
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[model lastFile] stringByExpandingTildeInPath];
    if(fullPath) startingDir = [fullPath stringByDeletingLastPathComponent];
    else		 startingDir = NSHomeDirectory();

    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model loadScriptFromFile:[[[openPanel URL]path]stringByAbbreviatingWithTildeInPath]];
        }
    }];
}
- (IBAction) saveAsFileAction:(id) sender
{
	[loadSaveView orderOut:self];
    
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    [[[NSApplication sharedApplication]keyWindow]  endSheet:loadSaveView];
#else
	[[NSApplication sharedApplication] endSheet:loadSaveView];
#endif
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model lastFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"Untitled.ofs";
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* path = [[[savePanel URL]path] stringByDeletingPathExtension];
            path = [path stringByAppendingPathExtension:@"ofs"];
            [model saveScriptToFile:path];
        }
    }];

}

- (IBAction) saveFileAction:(id) sender
{
	[loadSaveView orderOut:self];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    [[[NSApplication sharedApplication]keyWindow]  endSheet:loadSaveView];
#else
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
#endif
	if(![model lastFile]){
		[self saveAsFileAction:nil];
	}
	else [model saveFile];
}

- (int) numberPointsInPlot:(id)aPlotter;
{
    return kFilterTimeHistoSize;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	*yValue = [model processingTimeHist:i];
	*xValue = i;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTable
{
	if(aTable == inputVariablesTableView) return ([[model inputValues] count]);
	else  return ([[model outputValues] count]);
}

- (id) tableView:(NSTableView *)aTable objectValueForTableColumn:(NSTableColumn *)aCol row:(NSInteger)aRow
{
	id anArray;
    id ident = [aCol identifier];
    if([ident isEqualToString:@"value"])ident = @"iValue"; //fixes an XCode 4 warning
    else if([ident isEqualToString:@"valueHex"])ident = @"iValue"; //fixes an XCode 4 warning
	if(aTable == inputVariablesTableView) anArray= [model inputValues];
	else								  anArray= [model outputValues];
	return [[anArray objectAtIndex:aRow] objectForKey:ident];
}

- (void) tableView:(NSTableView*)aTable setObjectValue:(id)aData forTableColumn:(NSTableColumn*)aCol row:(NSInteger)aRow
{
	if(aTable == inputVariablesTableView) {
		id ident = [aCol identifier];
		if([ident isEqualToString:@"value"])ident = @"iValue"; //fixes an XCode 4 warning
		else if([ident isEqualToString:@"valueHex"])ident = @"iValue"; //fixes an XCode 4 warning
		[[[model inputValues] objectAtIndex:aRow] setObject: aData forKey:ident];	
	}
}

@end
