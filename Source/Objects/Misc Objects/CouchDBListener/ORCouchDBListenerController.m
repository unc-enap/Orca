//
//  ORCouchDBController.m
//  Orca
//
//  Created by Thomas Stolz on 05/20/13.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORCouchDBListenerController.h"
#import "ORCouchDBListenerModel.h"
#import "ORCouchDB.h"
#import "NSNotifications+Extensions.h"
#import <YAJL/NSObject+YAJL.h>

@implementation ORCouchDBListenerController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"CouchDBListener"];
    [self listeningChanged:nil];
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

-(void) awakeFromNib
{
    [super awakeFromNib];
    [self performSelectorOnMainThread:@selector(updateDisplays) withObject:nil waitUntilDone:NO];
}

#pragma mark •••Registration
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(databaseListChanged:)
                         name : ORCouchDBListenerModelDatabaseListChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectListChanged:)
                         name : ORCouchDBListenerModelObjectListChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(listeningChanged:)
                         name : ORCouchDBListenerModelListeningChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(commandsChanged:)
                         name : ORCouchDBListenerModelCommandsChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(statusLogChanged:)
                         name : ORCouchDBListenerModelStatusLogChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(statusLogChanged:)
                         name : ORCouchDBListenerModelStatusLogAppended
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(heartbeatChanged:)
                         name : ORCouchDBListenerModelHeartbeatChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(hostChanged:)
                         name : ORCouchDBListenerModelHostChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(portChanged:)
                         name : ORCouchDBListenerModelPortChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(usernameChanged:)
                         name : ORCouchDBListenerModelUsernameChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(passwordChanged:)
                         name : ORCouchDBListenerModelPasswordChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(databaseChanged:)
                         name : ORCouchDBListenerModelDatabaseChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(updatePathChanged:)
                         name : ORCouchDBListenerModelUpdatePathChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(listenOnStartChanged:)
                         name : ORCouchDBListenerModelListenOnStartChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(saveHeartbeatsWhileListeningChanged:)
                         name : ORCouchDBListenerModelSaveHeartbeatsWhileListeningChanged
                       object : nil];
}

- (void) updateWindow
{
	[super updateWindow];
}

#pragma mark ***Interface Management
- (void) databaseListChanged:(NSNotification *)aNote
{
    [databaseListView removeAllItems];
    [databaseListView addItemsWithObjectValues:[model databaseList]];
    [databaseListView setObjectValue:[model database]];
}

- (void) listeningChanged:(NSNotification *)aNote
{
    if ([model isListening]){
        [startStopButton setTitle:@"Stop!"];
        [self disableControls];
    }
    else{
        [startStopButton setTitle:@"Listen!"];
        [self enableControls];
    }
}

- (void) objectListChanged:(NSNotification *)aNote
{
    [cmdObjectBox removeAllItems];
    [cmdObjectBox addItemsWithObjectValues:[model objectList]];
}

- (void) commandsChanged:(NSNotification *)aNote
{
    [cmdTable reloadData];
}

- (void) statusLogChanged:(NSNotification *)aNote
{
    if ([[aNote name] isEqualToString:ORCouchDBListenerModelStatusLogAppended]) {
        NSAttributedString* attr = [[[NSAttributedString alloc] initWithString:[aNote object]]autorelease];
        [[statusLog textStorage] appendAttributedString:attr];
        [statusLog scrollRangeToVisible:NSMakeRange([[statusLog string] length], 0)];
    } else {
        [statusLog setString:[model statusLog]];
    }
}

- (void) hostChanged:(NSNotification *)aNote
{
    [hostField setStringValue:[model hostName]];
}
- (void) portChanged:(NSNotification*)aNote
{
    [portField setIntegerValue:[model portNumber]];
}
- (void) databaseChanged:(NSNotification*)aNote
{
    [databaseListView setObjectValue:[model database]];
}
- (void) usernameChanged:(NSNotification*)aNote
{
    [userNameField setStringValue:[model userName]];
}
- (void) passwordChanged:(NSNotification*)aNote
{
    [pwdField setStringValue:[model password]];
}
- (void) heartbeatChanged:(NSNotification*)aNote
{
    [heartbeatField setIntegerValue:[model heartbeat]];
}
- (void) updatePathChanged:(NSNotification*)aNote
{
    NSString* updatePath = [model updatePath];
    if ([updatePath length] == 0) {
        [updateNameField setStringValue:@""];
        [updateDesignDocField setStringValue:@""];
    } else {
        NSArray* components = [updatePath componentsSeparatedByString:@"/"];
        if ([components count] != 4) return;
        [updateNameField setStringValue:[components objectAtIndex:3]];
        [updateDesignDocField setStringValue:[components objectAtIndex:1]];
    }
}

- (void) listenOnStartChanged:(NSNotification*)aNote
{
    [cmdListenOnStart setState:[model listenOnStart]];
}

- (void) saveHeartbeatsWhileListeningChanged:(NSNotification *)aNote
{
    [cmdSaveHeartbeatsWhileListening setState:[model saveHeartbeatsWhileListening]];
}

#pragma mark •••Actions
- (void) updateDisplays
{
    
    
    [self heartbeatChanged:nil];
    [self hostChanged:nil];
    [self portChanged:nil];
    [self usernameChanged:nil];
    [self passwordChanged:nil];
    [self listeningChanged:nil];
    
    [self objectListChanged:nil];
    [self listeningChanged:nil];
    [cmdTable reloadData];
    [cmdCommonMethodsOnly setState:[model commonMethodsOnly]];
    [self statusLogChanged:nil];
    [self databaseChanged:nil];
    [self updatePathChanged:nil];
    [self listenOnStartChanged:nil];
    [self saveHeartbeatsWhileListeningChanged:nil];
    
}

- (void) disableControls
{
    [databaseListView setEnabled:NO];
    [hostField setEnabled:NO];
    [heartbeatField setEnabled:NO];
    [userNameField setEnabled:NO];
    [pwdField setEnabled:NO];
    [portField setEnabled:NO];
    [cmdApplyButton setEnabled:NO];
    [cmdRemoveButton setEnabled:NO];
    [cmdEditButton setEnabled:NO];
    [cmdCommonMethodsOnly setEnabled:NO];
    [cmdLabelField setEnabled:NO];
    [cmdMethodBox setEnabled:NO];
    [cmdObjectBox setEnabled:NO];
    [cmdTable setEnabled:NO];
    [cmdInfoField setEnabled:NO];
    [cmdObjectUpdateButton setEnabled:NO];
    [cmdValueField setEnabled:NO];
    [cmdTestExecuteButton setEnabled:NO];
    [cmdSaveHeartbeatsWhileListening setEnabled:NO];

}

- (void) enableControls
{
    [databaseListView setEnabled:YES];
    [hostField setEnabled:YES];
    [heartbeatField setEnabled:YES];
    [userNameField setEnabled:YES];
    [pwdField setEnabled:YES];
    [portField setEnabled:YES];
    [cmdApplyButton setEnabled:YES];
    [cmdRemoveButton setEnabled:YES];
    [cmdEditButton setEnabled:YES];
    [cmdCommonMethodsOnly setEnabled:YES];
    [cmdLabelField setEnabled:YES];
    [cmdMethodBox setEnabled:YES];
    [cmdObjectBox setEnabled:YES];
    [cmdTable setEnabled:YES];
    [cmdInfoField setEnabled:YES];
    [cmdObjectUpdateButton setEnabled:YES];
    [cmdTestExecuteButton setEnabled:YES];
    [cmdSaveHeartbeatsWhileListening setEnabled:YES];
}

- (IBAction) heartbeatSet:(id)sender
{
    [model setHeartbeat:[heartbeatField integerValue]];
}

- (IBAction) databaseSelected:(id)sender
{
    [model setDatabaseName:[databaseListView stringValue]];
}

- (IBAction) hostSet:(id)sender
{
    [model setHostName:[hostField stringValue]];
    [model listDatabases];
}

- (IBAction) portSet:(id)sender
{
    [model setPortNumber:[portField integerValue]];
}

- (IBAction) userNameSet:(id)Sender
{
    [model setUserName:[userNameField stringValue]];
}

- (IBAction) pwdSet:(id)Sender
{
    [model setPassword:[pwdField stringValue]];
}

- (IBAction) changeListening:(id)sender
{
    [self endEditing];
    [model performSelectorInBackground:@selector(startStopSession) withObject:nil];
}

- (IBAction) listDB:(id)sender
{
    [model listDatabases];
}

- (IBAction) listenOnStartAction:(id)sender
{
    [model setListenOnStart:[sender state]];
}

- (IBAction) cmdRemoveAction:(id)sender
{
    [model removeCommand:(int)[cmdTable selectedRow]];
    
}

- (IBAction) cmdEditAction:(id)sender
{
    [self endEditing];
    id cmd = [model commandAtIndex:(int)[cmdTable selectedRow]];
    [cmdLabelField setStringValue:[cmd objectForKey:@"Label"]];
    [cmdObjectBox setStringValue:[cmd objectForKey:@"Object"]];
    [cmdMethodBox setStringValue:[cmd objectForKey:@"Selector"]];
    [cmdValueField setStringValue:[cmd objectForKey:@"Value"]];
    [cmdInfoField setStringValue:[cmd objectForKey:@"Info"]];
    
    [model removeCommand:(int)[cmdTable selectedRow]];
    
}
- (IBAction) cmdApplyAction:(id)sender
{
    [self endEditing];
    NSString* label=[NSString stringWithString:[cmdLabelField stringValue]];
    NSString* obj=[NSString stringWithString:[cmdObjectBox objectValue]];
    NSString* sel=[NSString stringWithString:[cmdMethodBox stringValue]];
    NSString* val=[NSString stringWithString:[cmdValueField stringValue]];
    NSString* info=[NSString stringWithString:[cmdInfoField stringValue]];
    
    [model addCommand:obj label:label selector:sel info:info value:val];
}
- (IBAction) cmdObjectSelected:(id)sender
{
    [cmdMethodBox removeAllItems];
    [cmdMethodBox addItemsWithObjectValues:[model getMethodListForObjectID:[cmdObjectBox objectValue]]];
}
- (IBAction) cmdListCommonMethodsAction:(id)sender
{
    [model setCommonMethods:(BOOL)[cmdCommonMethodsOnly state]];
    [cmdMethodBox removeAllItems];
    [cmdMethodBox addItemsWithObjectValues:[model getMethodListForObjectID:[cmdObjectBox objectValue]]];

}
- (IBAction) updateObjectList:(id)sender
{
    [model updateObjectList];
}
- (IBAction) testExecute:(id)sender
{
    NSString* key=[[model commandAtIndex:(int)[cmdTable selectedRow]] objectForKey:@"Label"];
    id returnVal = [NSNull null];
    if([model executeCommand:key arguments:nil returnVal:&returnVal]){
        [model log:[NSString stringWithFormat:@"successfully executed command with label '%@'", key]];

        @try {
            // See if we can parse it.
            //NSString* resultString = [returnVal yajl_JSONString];
            NSData* sData = [returnVal dataUsingEncoding:NSASCIIStringEncoding];
            NSString* resultString = [NSJSONSerialization JSONObjectWithData:sData options:NSJSONReadingMutableContainers error:nil];
            [model log:[NSString stringWithFormat:@"   received and parsed result: '%@'",resultString]];
        }
        @catch (NSException *exception) {
            [model log:[NSString stringWithFormat:@"   CANNOT parse result to JSON: '%@'",returnVal]];
        }
    }
    else{
        [model log:[NSString stringWithFormat:@"execution of command '%@' failed", key]];
    }
}
- (IBAction) clearStatusLog:(id)sender
{
    [model setStatusLog:@""];
}

- (IBAction) updatePathAction:(id)sender
{
    NSString* designdoc = [updateDesignDocField stringValue];
    NSString* updatename = [updateNameField stringValue];
    if ([updatename length] == 0 && [designdoc length] == 0) {
        [model setUpdatePath:nil];
    } else if ([updatename length] != 0 && [designdoc length] != 0) {
        [model setUpdatePath:[NSString stringWithFormat:@"_design/%@/_update/%@",designdoc,updatename]];
    }
}

- (IBAction) saveHeartbeatsWhileListeningAction:(id)sender
{
    [model setSaveHeartbeatsWhileListening:[sender state]];
}

#pragma mark •••DataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [model commandCount];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    id obj = [model commandAtIndex:(int)rowIndex];
    return [obj valueForKey:[aTableColumn identifier]];

}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    id obj = [model commandAtIndex:(int)rowIndex];
	[obj setObject:anObject forKey:[aTableColumn identifier]];

}



@end
