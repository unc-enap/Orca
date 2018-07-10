//
//  ORDataBaseServicesController.h
//  Orca
//
//  Created by Mark Howe on Sept  28, 2006.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import <Cocoa/Cocoa.h>

#pragma mark ¥¥¥Forward Declarations
@class ORDataBaseServices;

@interface ORDataBaseServicesController : NSWindowController 
{
    IBOutlet NSTableView* servicesListView;
	
	id sqlConnection;
}

#pragma mark ¥¥¥Initialization
+ (id) sharedInstance;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window;

#pragma mark ¥¥¥Accessors
- (ORDataBaseServices*) dataBaseServices;

#pragma mark ¥¥¥Interface Management
- (void) servicesChanged:(NSNotification*)aNotification;


- (IBAction) subscribe:(id)sender;
- (IBAction) unsubscribe:(id)sender;


@end
