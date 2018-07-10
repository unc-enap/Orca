//
//  ORDataBaseServicesController.m
//  Orca
//
//  Created by Mark Howe on Sept  28, 2006.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//

#import "ORDataBaseServicesController.h"
#import "ORDataBaseServices.h"
#import "ORDocument.h"

static ORDataBaseServicesController* sharedInstance = nil;


@implementation ORDataBaseServicesController

+ (id) sharedInstance
{
    if(!sharedInstance){
        sharedInstance = [[ORDataBaseServicesController alloc] init];
    }
    return sharedInstance;
}


-(id)init
{
    self = [super initWithWindowNibName:@"DataBaseServices"];
    [self setWindowFrameAutosaveName:@"DataBaseServices"];
    return self;
}

- (void) dealloc
{
    sharedInstance = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    [self updateWindow];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[NSApp delegate]  undoManager];
}


#pragma mark ¥¥¥Accessors
- (ORDataBaseServices*) dataBaseServices
{
    return [ORDataBaseServices sharedInstance];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(servicesChanged:)
                         name : ORDataBaseServicesChangedNotification
                       object : [self dataBaseServices]];
}


#pragma mark ¥¥¥Actions
- (IBAction) saveDocument:(id)sender
{
    [[[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[[NSApp delegate]document] saveDocumentAs:sender];
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [self servicesChanged:nil];
}

- (void) servicesChanged:(NSNotification*)aNotification
{
	[servicesListView reloadData];
}

#pragma mark ¥¥¥Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    id obj = [[self dataBaseServices] serviceAtIndex:rowIndex];
	//if([[aTableColumn identifier] isEqualToString:@"subscriberCount"]){
	//	return [NSNumber numberWithInt:[[self dataBaseServices] subscriberCount:rowIndex]];
	//}
    //else {
		return [obj valueForKey:[aTableColumn identifier]];
	//}
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[self dataBaseServices] servicesCount];
}

- (IBAction) subscribe:(id)sender
{
	[[ORDataBaseServices sharedInstance] registerClient:@"Orca" to:@"ORCASqlServer"];
}

- (IBAction) unsubscribe:(id)sender
{
	[[ORDataBaseServices sharedInstance] unregisterClient:@"Orca" from:@"ORCASqlServer"];
	[sqlConnection release];
	sqlConnection = nil;
}
@end
