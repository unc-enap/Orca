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


@implementation NSOutlineView (OrcaExtensions)

- (NSMenuItem *)selectedItem { return [self itemAtRow: [self selectedRow]]; }

- (NSArray*)allSelectedItems {
    NSMutableArray *items = [NSMutableArray array];
	NSIndexSet* selectedSet = [self selectedRowIndexes];
	NSUInteger current_index = [selectedSet firstIndex];
	while (current_index != NSNotFound){
        if ([self itemAtRow:current_index]) [items addObject: [self itemAtRow:current_index]];
		current_index = [selectedSet indexGreaterThanIndex: current_index];
	}

    return items;
}

- (void)selectItems:(NSArray*)items byExtendingSelection:(BOOL)extend {
    int i;
    if (extend==NO) [self deselectAll:nil];
    for (i=0;i<[items count];i++) {
        NSInteger row = [self rowForItem:[items objectAtIndex:i]];
		if(row>=0) {
			NSIndexSet* aSet = [NSIndexSet indexSetWithIndex:row];
			[self selectRowIndexes:aSet byExtendingSelection:YES];
		}
    }
}
- (id) parentOfSelectedRow
{
	NSInteger currentRow = [self selectedRow];
	if (currentRow == -1) { // i.e. no selected row
		return nil;
	}
	NSInteger currentRowLevel = [self levelForRow:currentRow];
	if (currentRowLevel == 0) {
		// i.e. it's at the top level
		return nil;
	}
	// just decrement the row number until the level number decrements
	while ([self levelForRow:--currentRow] >= currentRowLevel) { }
	return [self itemAtRow:currentRow];
}


@end

