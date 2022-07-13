//-------------------------------------------------------------------------
//  OREHSF040nController.h
//
//  Created by Mark Howe on Thursday June 2,2022

#pragma mark ***Imported Files
#import "ORiSegHVCardController.h"

@interface OREHSF040nController : ORiSegHVCardController 
{
	IBOutlet   NSPopUpButton*	outputFailureBehaviorPU;
	IBOutlet   NSPopUpButton*	currentTripBehaviorPU;
	IBOutlet   NSTextField*		tripTimeTextField;
	IBOutlet   NSTextField*		rampTypeField;
	IBOutlet   NSTableView*		ramperTableView;
	IBOutlet   NSDrawer*		ramperDrawer;
	IBOutlet   NSTextField*		hwKillStatusField;
}

- (id)   init;

#pragma mark •••Interface Management
- (void) outputFailureBehaviorChanged:(NSNotification*)aNote;
- (void) currentTripBehaviorChanged:(NSNotification*)aNote;
- (void) tripTimeChanged:(NSNotification*)aNote;
- (void) ramperEnabledChanged:(NSNotification*)aNote;
- (void) ramperParameterChanged:(NSNotification*)aNote;
- (void) ramperStateChanged:(NSNotification*)aNote;
- (void) setRampTypeField;

#pragma mark •••Actions
- (IBAction) outputFailureBehaviorAction:(id)sender;
- (IBAction) currentTripBehaviorAction:(id)sender;
- (IBAction) tripTimeAction:(id)sender;

#pragma mark •••Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex;
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

@end
