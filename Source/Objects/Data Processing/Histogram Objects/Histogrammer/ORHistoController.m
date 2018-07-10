//
//  ORHistoController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 23 2002.
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
#import "ORHistoController.h"
#import "ORHistoModel.h"
#import "OR1DHistoController.h"
#import "ORMultiPlot.h"
#import "ORDataSet.h"


@implementation ORHistoController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Histo"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [outlineView setDoubleAction:@selector(doubleClick:)];
    [multiPlotView setDoubleAction:@selector(doubleClickMultiPlot:)];
	[splitView loadLayoutWithName:[NSString stringWithFormat:@"Data Monitor-%lu",[model uniqueIdNumber]]];
    
    [self updateWindow];
    [plotGroupButton setEnabled:NO];    
	scheduledToUpdate = NO;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}


#pragma mark ¥¥¥Accessors

- (void) setModel:(id)aModel
{    
    [super setModel:aModel];
    [outlineView setDoubleAction:@selector(doubleClick:)];
    [multiPlotView setDoubleAction:@selector(doubleClickMultiPlot:)];
    [[self window] setTitle:[NSString stringWithFormat:@"Data Monitor-%lu",[model uniqueIdNumber]]];
    [outlineView setDataSource:aModel];
    [self updateWindow];
}



#pragma mark ¥¥¥Interface Management

- (void) accumulateChanged:(NSNotification*)aNote
{
	[accumulateCB setIntValue: [model accumulate]];
}

- (void) shipFinalHistogramsChanged:(NSNotification*)aNote
{
	[shipFinalHistogramsButton setIntValue: [model shipFinalHistograms]];
}
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(dirChanged:)
                         name : ORHistoModelDirChangedNotification
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fileChanged:)
                         name : ORHistoModelFileChangedNotification
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(writeFileChanged:)
                         name : ORHistoModelWriteFileChangedNotification
                       object : model];
    
        
    [notifyCenter addObserver : self
                     selector : @selector(dataChanged:)
                         name : ORDataSetDataChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(multiPlotsChanged:)
                         name : ORHistoModelMultiPlotsChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(multiPlotsChanged:)
                         name : ORMultiPlotDataSetItemsChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(multiPlotsChanged:)
                         name : ORMultiPlotNameChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(outlineViewSelectionDidChange:)
                         name : NSOutlineViewSelectionDidChangeNotification
                       object : outlineView];

    [notifyCenter addObserver : self
                     selector : @selector(shipFinalHistogramsChanged:)
                         name : ORHistoModelShipFinalHistogramsChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(involvedInCurrentRunChanged:)
                         name : ORDataChainObjectInvolvedInCurrentRun
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(accumulateChanged:)
                         name : ORHistoModelAccumulateChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(decodingDisabledChanged:)
                         name : ORHistoModelDecodingDisabledChanged
                        object: model];

}

- (void) updateWindow
{
	[super updateWindow];
    [self modelChanged:nil];
    [self decodingDisabledChanged:nil];
    [self dataChanged:nil];
    [self dirChanged:nil];
    [self fileChanged:nil];
    [self writeFileChanged:nil];
	[self shipFinalHistogramsChanged:nil];
	[self involvedInCurrentRunChanged:nil];
    [self accumulateChanged:nil];
}



#pragma  mark ¥¥¥Interface Management
- (void) decodingDisabledChanged:(NSNotification *)notification
{
    [decodingDisabledField setStringValue:[model decodingDisabled]?@"Decoding Disabled":@""];
    [disableDecodingButton setTitle:[model decodingDisabled]?@"Enable Decoding":@"Disable Decoding"];
}

- (void)involvedInCurrentRunChanged:(NSNotification *)notification
{
	[involvedInRunField setStringValue:[model involvedInCurrentRun]?@"Running -- Deletions not Allowed":@""];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    if([notification object] == outlineView){
        NSMutableArray *selection = [NSMutableArray arrayWithArray:[outlineView allSelectedItems]];
    
        int validCount = 0;
        int i;
        for(i=0;i<[selection count];i++){
            ORDataSet* aDataSet = [selection objectAtIndex:i];
            if([aDataSet leafNode]){
                ORDataSetModel* obj = [aDataSet data];
                if([obj canJoinMultiPlot]){
                    validCount++;
                }
            }
        }
        [plotGroupButton setEnabled:validCount];
    }
}

- (void) multiPlotsChanged:(NSNotification*)aNotification
{
	[multiPlotView reloadData];
}


- (void) modelChanged:(NSNotification*)aNotification
{
    if(!aNotification || [aNotification object] == self){
		//[outlineView reloadItem:[model dataSet] reloadChildren:YES];
		scheduledToUpdate = NO;
		[outlineView reloadData];
		[multiPlotView reloadData];
	}
}

- (void) dataChanged:(NSNotification*)aNotification
{
    if(!scheduledToUpdate){
        [self performSelector:@selector(doUpdate) withObject:nil afterDelay:1.0];
        scheduledToUpdate = YES;
    }
}

- (void) doUpdate
{
    scheduledToUpdate = NO;
    [outlineView reloadData];
    [multiPlotView reloadData];
    //[outlineView reloadItem:[model dataSet] reloadChildren:YES];
}

- (void) dirChanged:(NSNotification*)note
{
	if([model directoryName]!=nil)[dirTextField setStringValue: [model directoryName]];
}


- (void) fileChanged:(NSNotification*)note
{
	if([model fileName]!=nil)[fileTextField setStringValue: [model fileName]];
}

- (void) writeFileChanged:(NSNotification*)note
{
	if([writeFileButton state] != [model writeFile]){
		[writeFileButton setState: [model writeFile]];
	}
	
	[self setButtonStates];		
}

- (void) setButtonStates
{
    BOOL willWrite = [model writeFile];
    if(willWrite == NO){
        [dirTextField setStringValue:@"---"];
        [fileTextField setStringValue:@"---"];
    }
    [chooseDirButton setEnabled:willWrite];
}


- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	[splitView storeLayoutWithName:[NSString stringWithFormat:@"Data Monitor-%lu",[model uniqueIdNumber]]];
}

#pragma  mark ¥¥¥Actions
- (IBAction) decodingDisabledAction:(id)sender;
{
    BOOL aFlag = ![model decodingDisabled];
    [model setDecodingDisabled:aFlag];
}

- (void) accumulateAction:(id)sender
{
	[model setAccumulate:[sender intValue]];	
}
- (IBAction) getInfo:(id)sender
{
    if([[self window] firstResponder] == outlineView){
        NSArray *selection = [outlineView allSelectedItems];
        NSEnumerator* e = [selection objectEnumerator];
        id item;
        while(item = [e nextObject]){
			NSLog(@"%@\n",[item shortName]);
        }
    }
}

- (IBAction) shipFinalHistogramsAction:(id)sender
{
	[model setShipFinalHistograms:[sender intValue]];	
}

- (IBAction) plotGroupAction:(id)sender
{
    NSMutableArray *selection = [NSMutableArray arrayWithArray:[outlineView allSelectedItems]];
    //launch the multiplot for the selection array...
    ORMultiPlot* newMultiPlot = [[ORMultiPlot alloc] init];
    
    NSEnumerator* e = [selection objectEnumerator];
    ORDataSet* aDataSet;
    int validCount = 0;
    while(aDataSet = [e nextObject]){
        if([aDataSet leafNode]){
            ORDataSetModel* obj = [aDataSet data];
            if([obj canJoinMultiPlot]){
                [newMultiPlot addDataSetName:[[aDataSet data] shortName]];
                validCount++;
				if(![newMultiPlot dataSet]){
					[newMultiPlot setDataSet:[obj dataSet]];
				}
            }
        }
    }
    if(validCount){
        [newMultiPlot setDataSource:[(ORHistoModel*)model dataSet]];
        [newMultiPlot doDoubleClick:nil];
        [model addMultiPlot:newMultiPlot];
    }
    [newMultiPlot release];
    [multiPlotView reloadData];
    [outlineView deselectAll:self];
    [outlineView reloadData];

}

- (IBAction) doubleClickMultiPlot:(id)sender
{
    id selectedObj = [multiPlotView itemAtRow:[multiPlotView selectedRow]];
    [selectedObj doDoubleClick:sender];
}

- (IBAction) doubleClick:(id)sender
{
    id selectedObj = [outlineView itemAtRow:[outlineView selectedRow]];
    [selectedObj doDoubleClick:sender];
}

- (IBAction) chooseDir:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setPrompt:@"Choose"];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* directoryName = [[[openPanel URL]path] stringByAbbreviatingWithTildeInPath];
            [model setDirectoryName:directoryName];
       }
    }];
}

- (IBAction) writeFileAction:(id)sender
{
    [model setWriteFile:[sender state]];
}

- (IBAction) clearAllAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Clear Counts"];
    [alert setInformativeText:@"Really Clear them? You will not be able to undo this."];
    [alert addButtonWithTitle:@"Yes/Clear It"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [[(ORHistoModel*)model dataSet] clear];
            [outlineView reloadData];
        }
    }];
#else
    NSBeginAlertSheet(@"Clear Counts",
                      @"Cancel",
                      @"Yes/Clear It",
                      nil,[self window],
                      self,
                      @selector(_clearSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really Clear them? You will not be able to undo this.");
#endif
}


#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void)_clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
        [[model dataSet] clear];
        [outlineView reloadData];
        //[outlineView reloadItem:[model dataSet] reloadChildren:YES];
        //[outlineView setNeedsDisplay:YES];
    }    
}
#endif

- (IBAction)delete:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction)cut:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction) removeItemAction:(id)sender
{ 
	if(![model involvedInCurrentRun]){
		if([[self window] firstResponder] == outlineView){
			NSArray *selection = [outlineView allSelectedItems];
			NSEnumerator* e = [selection objectEnumerator];
			ORDataSet* item;
			while(item = [e nextObject]){
				[(ORHistoModel*)model removeDataSet:item];
			}
			[[(ORHistoModel*)model dataSet] recountTotal];
			[outlineView deselectAll:self];
			[outlineView reloadData];
		}
		else {
			NSArray *selection = [multiPlotView allSelectedItems];
			NSEnumerator* e = [selection objectEnumerator];
			id item;
			while(item = [e nextObject]){
				if([item isKindOfClass:[ORMultiPlot class]]){
					[model removeMultiPlot:item];
				}
				else {//if([item isKindOfClass:[ORMultiPlotDataItem class]]){
					[item removeSelf];
				}
			}
			[multiPlotView deselectAll:self];
			[multiPlotView reloadData];
		}
	}
	
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [outlineView selectedRow] >= 0 || [multiPlotView selectedRow]>=0;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [outlineView selectedRow] >= 0 || [multiPlotView selectedRow]>=0;
    }    
    else if ([menuItem action] == @selector(copy:)) {
        return NO;
    }
    else if ([menuItem action] == @selector(getInfo:))	return ([outlineView selectedRow] >= 0);
    else  return [super validateMenuItem:menuItem];
}

#pragma  mark ¥¥¥Delegate Responsiblities
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

#pragma mark ¥¥¥Data Source Methods
- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item
{
    if(ov == outlineView){
        return  (item == nil) ? [model numberOfChildren]  : [item numberOfChildren];
    }
    else {
        if(!item)return [[model multiPlots] count];
        else {
            if([item respondsToSelector:@selector(count)])return [(ORMultiPlot*)item count];
            else return 0;
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
    if(ov == outlineView){
        return   (item == nil) ? [model numberOfChildren] != 0 : ([item numberOfChildren] != 0);
    }
    else {
        if(!item)return [[model multiPlots] count]!=0;
        else {
            if([item respondsToSelector:@selector(count)])return [(ORMultiPlot*)item count]!=0;
            else return NO;
        }
    }
}

- (id)outlineView:(NSOutlineView *)ov child:(NSUInteger)index ofItem:(id)item
{
    id anObj;
    if(ov == outlineView){
        if(!item)   anObj = model;
        else        anObj = [(ORMultiPlot*)item childAtIndex:index];
    }
    else {
        if(!item)   anObj = [[model multiPlots] objectAtIndex:index];
        else  anObj = [item objectAtIndex:index];
    }
    return anObj;
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if(ov == outlineView){
        return  ((item == nil) ? [model name] : [item name]);
    }
    else {
        if([tableColumn identifier]){
            return [item description];
        }
        else return nil;
    }
}
@end


