//----------------------------------------------------------------------------------------------------
//  ORStatusController.h
//  Controlls access to the array of comments in the status window.
//
//  Created by Mark Howe on Wed Jan 02 2002.
//  Copyright  © 2001 CENPA. All rights reserved.
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
#import "ORStatusController.h"
#import "ORDataSet.h"
#import "ORRunModel.h"
#import "ORMailCenter.h"
#import "SynthesizeSingleton.h"
#import "ORAlarm.h"
#import "ORAlarmCollection.h"

NSString* ORStatusFlushedNotification	 = @"ORStatusFlushedNotification";
NSString* ORStatusLogUpdatedNotification = @"ORStatusLogUpdatedNotification";
NSString* ORStatusFlushSize				 = @"ORStatusFlushSize";

ORStatusController* theLogger = nil;

@interface ORStatusController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) deleteHistoryActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
- (void) mainThreadPrint:(NSAttributedString*)s1;
@end

#define kStatusConnection @"StatusConnection"
#define kMaxTextSize 500000

@implementation ORStatusController

#pragma mark ¥¥¥Initialization

SYNTHESIZE_SINGLETON_FOR_ORCLASS(StatusController);

- (id)init
{
    if (self = [super initWithWindowNibName:@"StatusWindow"]) {
        [self setWindowFrameAutosaveName:@"StatusWindow"];
        theLogger = self;
        if(!dataSet){
            [self setDataSet:[[[ORDataSet alloc]initWithKey:@"Errors" guardian:nil] autorelease] ];
        }
    }
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [dataSet release];
	[lastSnapShot release];
    [super dealloc];
}

-(void) awakeFromNib
{
    [statusView setEditable:NO];
    [outlineView setDataSource:self];
    [self showWindow:self];
    
	logBookDirty = NO;
	[saveLogBookButton setEnabled:NO];
	
	[self populateFilterPopup];
	
	[self loadAlarmHistory];
	
    if(alarmLogSize > 2*1000*1000){
        NSLogColor([NSColor redColor],@"The Alarm Log is getting big (%uMB). Please consider clearing it. Otherwise ORCA will take a int32_t time starting\n",alarmLogSize/(1000*1000));
    }
    
	NSString* s = [NSString stringWithFormat:@"%@ ORCA started",[[NSDate date] stdDescription]]; //don't change this string
	[self updateAlarmLog:s];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSControlTextDidChangeNotification object:logBookField];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alarmPosted:) name:ORAlarmAddedToCollection object : nil];	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alarmCleared:) name:ORAlarmRemovedFromCollection object : nil];	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alarmAcknowledged:) name:ORAlarmWasAcknowledgedNotification object : nil];
}

- (void) loadAlarmHistory
{
	[alarmLogView setString:@""];
	//load the alarm history
	NSString* alarmHistoryPath = [[ApplicationSupport sharedApplicationSupport] applicationSupportFolder:@"History"];
	alarmHistoryPath = [alarmHistoryPath stringByAppendingPathComponent:@"Alarms"];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    alarmLogSize= ([[fm attributesOfItemAtPath:alarmHistoryPath error:nil] fileSize]);

	NSString* s = [NSString stringWithContentsOfFile:alarmHistoryPath encoding:NSASCIIStringEncoding error:nil];
	NSArray* lines = [s componentsSeparatedByString:@"\n"];
    NSUInteger total = [lines count];
    BOOL displayPercent = NO;
    if(total<100000){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:@"Loading Alarm History" forKey:@"Message"]];
    }
    else {
        displayPercent = YES;
    }
    int n = 0;
    int lastPercent=0;
	for(id aLine in lines)	{
        n++;
        int percent = (int)(100 * n/(float)total);
        if(displayPercent && (percent != lastPercent)){
            NSString* s = [NSString stringWithFormat:@"Loading Alarm History (%d%%)",percent];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:s forKey:@"Message"]];
            lastPercent = percent;
        }
		[self printAlarm:aLine];
	}
}

- (void) populateFilterPopup
{
	[alarmFilterPU removeAllItems];
	int i;
	[alarmFilterPU addItemWithTitle:@"Show All"];
	for(i=0;i<kNumAlarmSeverityTypes;i++){
		[alarmFilterPU addItemWithTitle:[ORAlarm alarmSeverityName:i]];
	}
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [(ORAppDelegate*)[NSApp delegate]  undoManager];
}

#pragma mark ¥¥¥Accessors
- (void) setLogBookFile:(NSString*)aFilePath
{
	[[[(ORAppDelegate*)[NSApp delegate] undoManager] prepareWithInvocationTarget:self] setLogBookFile:logBookFile];
	
	if(!aFilePath)aFilePath = [@"~/OrcaLogBook.rtfd" stringByExpandingTildeInPath];
	if(![[aFilePath pathExtension] isEqualToString:@"rtfd"]){
		aFilePath = [[aFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"rtfd"];
	}
    [logBookFile autorelease];
    logBookFile = [aFilePath copy];
	
	[logBookPathField setStringValue:[logBookFile stringByAbbreviatingWithTildeInPath]];
	
	if([[NSFileManager defaultManager]  fileExistsAtPath:logBookFile]){
		if(![logBookField readRTFDFromFile:logBookFile]){
			NSLogColor([NSColor redColor],@"Couldn't open LogBook <%@>.\n",logBookFile);
		}
	}
	else {
		[logBookField setString:@""];
	}
}

- (oneway void) setDataSet: (ORDataSet *) aDataSet
{
    [aDataSet retain];
    [dataSet release];
    dataSet = aDataSet;
}

- (NSString*) errorSummary
{
    NSMutableString* string = [NSMutableString stringWithCapacity:1024];
    return [NSString stringWithFormat:@"%@",[dataSet summarizeIntoString:string]];
}


- (oneway void) printAttributedString:(NSAttributedString*)s1
{
    [self performSelectorOnMainThread:@selector(mainThreadPrint:) withObject:s1 waitUntilDone:[NSThread isMainThread]];
}


- (oneway void) logError: (NSString*)anError usingKeyArray:(NSArray*)keys
{
    if(!dataSet){
        [self setDataSet:[[[ORDataSet alloc]initWithKey:@"Errors" guardian:nil] autorelease] ];
    }
    
    [dataSet loadGenericData:anError sender:nil usingKeyArray:keys];
    [errorTextField setStringValue:[keys lastObject]];
    
    if(!scheduledToUpdate){
        scheduledToUpdate = YES;
        [self performSelector:@selector(updateErrorDisplay) withObject:nil afterDelay:1.0];
    }
}

-(void) printAlarm: (NSString*)s1
{
	NSInteger filterIndex = [alarmFilterPU indexOfSelectedItem];
	NSString* filter = [[alarmFilterPU titleOfSelectedItem] stringByAppendingString:@"]"];
	
	if([s1 length]){
		if(filterIndex == 0 || ![s1 hasSuffix:@"]"] || [s1 hasSuffix:filter]){
			s1 = [s1 stringByAppendingString:@"\n"];
			if([self alarmLogTextlength]){
				[alarmLogView replaceCharactersInRange:NSMakeRange([self alarmLogTextlength], 0) withString:s1];
				[alarmLogView scrollRangeToVisible: NSMakeRange([self alarmLogTextlength], 0)];	
			}
			else {
				[alarmLogView setString:s1];
			}
			NSUInteger len = [s1 length];
			
			if([s1 hasSuffix:@"ORCA started\n"]){
				[[alarmLogView textStorage] setAttributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName ]
													range:NSMakeRange([self alarmLogTextlength]-len,len)];
			}
			else {
				[[alarmLogView textStorage] setAttributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName ]
													range:NSMakeRange([self alarmLogTextlength]-len,17)];

			}
		}
	}
}

- (NSString*) contents
{
	NSString* contents;
	@synchronized(self){
		contents =  [[statusView string] copy];
	}
	return [contents autorelease];
}

- (NSString*) alarmLogContents
{
   	NSString* contents;
	@synchronized(self){
		contents =  [[alarmLogView string] copy];
	}
	return [contents autorelease];
}

- (void) doSnapShot
{
    [self doPeriodicSnapShotToPath:[[NSUserDefaults standardUserDefaults] objectForKey:ORPrefHeartBeatPath]];
}

- (void) doPeriodicSnapShotToPath:(NSString*) aPath
{
	if([aPath length] == 0) return;
	if(![[NSFileManager defaultManager] fileExistsAtPath:aPath]){
		[[NSFileManager defaultManager] createDirectoryAtPath:aPath withIntermediateDirectories:YES attributes:nil error:nil];
	}
    @synchronized(self){

        //get the current date
        NSDate* now = [NSDate date];
        NSString* theFileName = [NSString stringWithFormat:@"StatusLog_%04d_%02d_%02d",(int32_t)[now yearOfCommonEra],(int32_t)[now monthOfYear],(int32_t)[now dayOfMonth]];
        aPath = [aPath stringByAppendingPathComponent:theFileName];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:aPath];
        NSString* contents = [[ORStatusController sharedStatusController] contents];
        if([contents length]){
            
            [lastSnapShot release];
            lastSnapShot = [now retain];
            
            if(fileExists){
                [[NSFileManager defaultManager] removeItemAtPath:aPath error:nil];
            }
            [contents writeToFile:aPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
        }
    }
}

- (NSString*) contentsTail:(uint32_t)aDuration
{
	return [self contentsTail:aDuration includeDurationHeader:YES];
}

- (NSString*) contentsTail:(uint32_t)aDuration includeDurationHeader:(BOOL)header
{
	NSString* tailContents	= @"";
	BOOL	  valid			= NO;
    NSString*	    contents;
	@synchronized(self){
		contents			= [[[statusView string] copy] autorelease];
    }
    
    NSArray*	lines				= [contents componentsSeparatedByString:@"\n"];
    NSDate*     theReferenceDate	= [NSDate date];
    int count=0;
    for(NSString* aLine in [lines reverseObjectEnumerator]){
        //get first character
        int datePart = [aLine intValue];
        if(datePart == 0){
            if([aLine length]){
                tailContents = [aLine stringByAppendingFormat:@"\n%@",tailContents]; 
            }
            continue;
        }
        else {
            NSString* theDateAsString = [NSString stringWithFormat:@"20%02d-%02d-%02d %@",
                                         [[aLine substringWithRange:NSMakeRange(4,2)] intValue],   //year part
                                         [[aLine substringWithRange:NSMakeRange(0,2)] intValue],	//month part
                                         [[aLine substringWithRange:NSMakeRange(2,2)] intValue],	//day part
                                         [aLine substringWithRange:NSMakeRange(7,8)]];  //time part
            
            NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

            NSDate* theDate = [dateFormatter dateFromString:theDateAsString];
            [dateFormatter release];
            if(theDate){
                NSTimeInterval deltaTimeForLine = [theReferenceDate timeIntervalSinceDate:theDate];
                if(deltaTimeForLine <= aDuration || (++count<500)){
                    tailContents = [aLine stringByAppendingFormat:@"\n%@",tailContents]; 
                    valid = YES;
                }
                else break;
            }
        }
    }
	
	if(valid){
		if(header)return [NSString stringWithFormat:@"Last %u seconds of ORCA Status log\n\n%@",aDuration,tailContents];
		else return tailContents;
	}
	else return nil;
}



- (void) updateErrorDisplay
{
    scheduledToUpdate = NO;
    [outlineView reloadItem:dataSet reloadChildren:YES];
    [errorField setIntegerValue:[dataSet totalCounts]];
}

- (NSUInteger) statusTextlength
{
    NSUInteger theLength;
    @synchronized(self){
        theLength =  [[statusView textStorage] length];
    }
    return theLength;
}

- (NSUInteger) alarmLogTextlength
{
    NSUInteger theLength;
    @synchronized(self){
        theLength = [[alarmLogView textStorage] length];
    }
    return theLength;
}

- (IBAction) saveDocument:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocumentAs:sender];
}

- (IBAction) alarmFilterAction:(id)sender
{
	[self loadAlarmHistory];
}


#pragma mark ¥¥¥Data Source Methods
- (NSUInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return (item == nil) ? 1  : [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return    (item == nil) ? YES : ([item numberOfChildren] != 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSUInteger)index ofItem:(id)item
{
    if(item)   return [(ORDataSet*)item childAtIndex:index];
    else	return dataSet;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return  ((item == nil) ? [self name] : [item name]);
}

- (NSUInteger)  numberOfChildren
{
    return [dataSet count];
}

- (id)   childAtIndex:(NSUInteger)index
{
    NSEnumerator* e = [dataSet objectEnumerator];
    id obj;
    id child = nil;
    short i = 0;
    while(obj = [e nextObject]){
        if(i++ == index){
            child = obj;
            break;
        }
    }
    return child;
}

- (NSString*)   name
{
    return @"Errors";
}

#pragma mark ¥¥¥Actions
- (IBAction) expandAction:(id)sender
{
    id selectedObj = [outlineView itemAtRow:[outlineView selectedRow]];
    [outlineView expandItem:selectedObj expandChildren:YES];
}

- (IBAction) clearAllAction:(id)sender
{
    [dataSet clear];
    [outlineView reloadItem:dataSet  reloadChildren:YES];
    [outlineView setNeedsDisplay:YES];
    [errorField setIntegerValue:[dataSet totalCounts]];
}

- (IBAction)delete:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction)cut:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction)selectAll:(id)sender
{
    [outlineView selectAll:sender];
}

- (IBAction) insertDate:(id)sender
{
	NSString* theDate = [[NSDate date] descriptionFromTemplate:@"MM/dd HH:mm"];
    
    [logBookField insertText:theDate replacementRange:NSMakeRange([[statusView string] length],0)];
}

- (IBAction) insertConfigurationName:(id)sender
{
	NSString* theConfigFile = [NSString stringWithFormat:@"Configuration File: %@",[[[(ORAppDelegate*)[NSApp delegate] document] fileURL] path]];
	[logBookField insertText: theConfigFile replacementRange:NSMakeRange([[statusView string] length],0)];
}

- (IBAction) insertRunNumber:(id)sender
{
	NSArray* runControlObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
	NSString* theRun;
	if([runControlObjects count]){
		theRun = [NSString stringWithFormat:@"Run Number %u",[[runControlObjects objectAtIndex:0] runNumber]];
	}
	else {
		theRun = @"No Run Control Obj";
	}
	[logBookField insertText:theRun replacementRange:NSMakeRange([[statusView string] length],0)];
}

- (IBAction) mailContent:(id)sender
{
    @synchronized(self){
        NSString* tabIdentifer = [[tabView selectedTabViewItem]identifier];
        if([tabIdentifer isEqualToString:@"status"]){
            ORMailCenter* theMailCenter = [ORMailCenter mailCenterWithDelegate:self];
            [theMailCenter showWindow:self];
            [theMailCenter setTextBodyToRTFData:[statusView RTFFromRange:NSMakeRange(0,[[statusView string] length])]];
        }
        else if([tabIdentifer isEqualToString:@"logBook"]){
            ORMailCenter* theMailCenter = [ORMailCenter mailCenterWithDelegate:self];
            [theMailCenter showWindow:self];
            [self saveLogBook:self];
            [theMailCenter setFileToAttach:logBookFile];
        }
    }
}

- (void) mailSent:(NSString*)address
{
	NSLog(@"StatusLog Content was sent to:\n%@\n",address);
}

- (IBAction) removeItemAction:(id)sender
{ 
    NSArray *selection = [outlineView allSelectedItems];
    NSEnumerator* e = [selection objectEnumerator];
    id item;
    while(item = [e nextObject]){
        [self removeDataSet:item];
    }
    [outlineView deselectAll:self];
    [dataSet recountTotal];
    [errorField setIntegerValue:[dataSet totalCounts]];
    [outlineView reloadData];
    
}

- (IBAction) saveLogBook:(id)sender
{
	if(!logBookFile)return;
	if(logBookDirty)[[(ORAppDelegate*)[NSApp delegate] document] updateChangeCount:NSChangeUndone];
	
	if([logBookFile isEqualToString:@"untitled.rtfd"]){
		[self saveAsLogBook:nil];
	}
	else {
		[logBookField writeRTFDToFile:logBookFile atomically:YES];
		logBookDirty = NO;
		[saveLogBookButton setEnabled:NO];
	}
	
}

- (IBAction) saveAsLogBook:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if(logBookFile){
        startDir = [logBookFile stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* newPath = [[savePanel URL] path ];
            
            if(![[newPath pathExtension] isEqualToString:@"rtfd"]){
                newPath = [[newPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"rtfd"];
            }
            [logBookField writeRTFDToFile:newPath atomically:YES];
            [self setLogBookFile:newPath];
            
            logBookDirty = NO;
            [saveLogBookButton setEnabled:NO];
        }
    }];
}

- (IBAction) loadLogBook:(id)sender
{
    NSString* startDir = NSHomeDirectory(); //default to home
    if(logBookFile){
        startDir = [logBookFile stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Load Log Book"];
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* fileName = [[openPanel URL] path];
            [self setLogBookFile:fileName];
        }
    }];
}

- (IBAction) newLogBook:(id)sender
{
	BOOL cancel = ORRunAlertPanel(@"Starting a new logbook.",@"Is this really what you want?\nAny unsaved changes will be lost!",@"Cancel",@"Yes, Make New LogBook",nil);
	if(!cancel){
		[logBookField setString:@""];
		[self setLogBookFile:@"untitled"];
	}
}

- (void) removeDataSet:(ORDataSet*)item
{
    if([[item name] rangeOfString:[self name]].location != NSNotFound) {
        [self setDataSet:[[[ORDataSet alloc]initWithKey:@"Errors" guardian:nil] autorelease] ];
    }
    else [dataSet removeObject:item];
}

- (void) alarmPosted:(NSNotification*)aNote
{
	ORAlarm* alarm = [aNote object];
	NSString* s = [NSString stringWithFormat:@"%@ Posted: %@ [%@]",[alarm timePosted],[alarm name],[alarm severityName]];
	[self updateAlarmLog:s];
}

- (void) alarmCleared:(NSNotification*)aNote
{
	ORAlarm* alarm = [aNote object];
	NSString* s = [NSString stringWithFormat:@"%@ Cleared: %@ [%@]",[alarm timePosted],[alarm name],[alarm severityName]];
	[self updateAlarmLog:s];
}

- (void) alarmAcknowledged:(NSNotification*)aNote
{
	ORAlarm* alarm = [aNote object];
	
	NSString* s = [NSString stringWithFormat:@"%@ Acknowledged: %@ [%@]",[alarm timePosted],[alarm name],[alarm severityName]];
	[self updateAlarmLog:s];
}

- (void) updateAlarmLog:(NSString*)s
{
	if([s length]){
		[self printAlarm:s];
		
		NSString* alarmHistoryPath = [[ApplicationSupport sharedApplicationSupport] applicationSupportFolder:@"History"];
		alarmHistoryPath = [alarmHistoryPath stringByAppendingPathComponent:@"Alarms"];
		NSFileManager* fm = [NSFileManager defaultManager];
		if(![fm fileExistsAtPath:alarmHistoryPath]){
			[fm createFileAtPath:alarmHistoryPath contents:nil attributes:nil];
		}
		NSFileHandle* fh = [NSFileHandle fileHandleForUpdatingAtPath:alarmHistoryPath];
		[fh seekToEndOfFile];
		s = [s stringByAppendingString:@"\n"];
		[fh writeData:[s dataUsingEncoding:NSASCIIStringEncoding]];
		[fh closeFile];
	}
}

- (IBAction) clearAlarmHistoryAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Really delete the Alarm history?"];
    [alert setInformativeText:@"Deletion of the history can not be undone."];
    [alert addButtonWithTitle:@"Yes, Delete It"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];

    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            NSString* alarmHistoryPath = [[ApplicationSupport sharedApplicationSupport] applicationSupportFolder:@"History"];
            alarmHistoryPath = [alarmHistoryPath stringByAppendingPathComponent:@"Alarms"];
            NSFileManager* fm = [NSFileManager defaultManager];
            [fm removeItemAtPath:alarmHistoryPath error:nil];
            [alarmLogView setString:@""];
            NSLog(@"Alarm history deleted\n");
        }
    }];
#else
	NSBeginAlertSheet(@"Really delete the Alarm history?",
                      @"Cancel",
                      @"Yes, Delete It",
                      nil,[self window],
                      self,
                      @selector(deleteHistoryActionDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Deletion of the history can not be undone.");
#endif
}

- (IBAction) userInputAction:(id)sender
{
    NSString* s = [userInputField stringValue];
    if([s length]){
        NSLog(@"%@\n",s);
        [userInputField setStringValue:@""];
    }
}

- (IBAction) saveStatusLog:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save Log As"];
    NSString* startDir = NSHomeDirectory(); //default to home
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* newPath = [[savePanel URL] path ];
            
            if(![[newPath pathExtension] isEqualToString:@"rtfd"]){
                newPath = [[newPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"rtfd"];
            }
            @synchronized(self){
                [statusView writeRTFDToFile:newPath atomically:YES];
            }
         }
    }];
}
#pragma  mark ¥¥¥Delegate Responsiblities
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

- (NSString*) substringWithRange:(NSRange)aRange
{
    NSString* result;
    @try {
        NSString* theText = [[statusView textStorage] string];
        result = [[[theText substringWithRange:aRange]retain] autorelease];
	}
	@catch(NSException* localException) {
        result = @"";
    }
    return result;
}

- (void) handleInvocation:(NSInvocation*) anInvocation
{
    [anInvocation invoke];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [outlineView selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [outlineView selectedRow] >= 0;
    }
    else if ([menuItem action] == @selector(selectAll:)) {
        return YES;
    }
	else if([menuItem action] == @selector(mailContent:)){
		NSString* tabIdentifer = [[tabView selectedTabViewItem]identifier];
		if([tabIdentifer isEqualToString:@"status"])			return YES;
		else if([tabIdentifer isEqualToString:@"logBook"])	return YES;
		else return NO;
	}
    else  return [(ORAppDelegate*)[NSApp delegate] validateMenuItem:menuItem];
}

- (void)textDidChange:(NSNotification *)notification
{
	if([notification object] == logBookField){
		if(!logBookDirty)[[(ORAppDelegate*)[NSApp delegate] document] updateChangeCount:NSChangeDone];
		logBookDirty = YES;
		[saveLogBookButton setEnabled:YES];
	}
}


#pragma mark ¥¥¥Archivale
- (void) decode:(NSCoder*) aDecoder
{
	[[(ORAppDelegate*)[NSApp delegate] undoManager] disableUndoRegistration];
	[self setLogBookFile:[aDecoder decodeObjectForKey:@"LogBookFile"]];
	[[(ORAppDelegate*)[NSApp delegate] undoManager] enableUndoRegistration];
}

- (void) encode:(NSCoder*) anEncoder
{
	[anEncoder encodeObject:logBookFile forKey:@"LogBookFile"];
}

- (void) loadCurrentLogBook
{
	if(logBookFile){
		[logBookField readRTFDFromFile:logBookFile];
	}
}

- (NSString*) fullID
{
    //need to provide for the couchDB stuff
    return @"StatusLog";
}

- (void) scheduleCouchDBUpdate
{
    if(!scheduledToPostToDB){
        scheduledToPostToDB = YES;
        [self performSelector:@selector(postToCouchDB) withObject:nil afterDelay:notFirstTime?60:10];
    }
}

- (void) postToCouchDB
{
    scheduledToPostToDB = NO;
    notFirstTime        = YES;
    NSString* s = [self contents];
    NSDictionary* dbRecord = [NSDictionary dictionaryWithObjectsAndKeys:
                              s,				@"statuslog",
                              @"StatusLog",		@"type",
                              nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:dbRecord];

    
}

@end

@implementation ORPrintableView
- (IBAction) print:(id)sender
{
	
	// set printing properties
	NSPrintInfo* pInfo = [[(ORAppDelegate*)[NSApp delegate]document] printInfo];
	[pInfo setHorizontalPagination:NSFitPagination];
	[pInfo setHorizontallyCentered:NO];
	[pInfo setVerticallyCentered:NO];
	[pInfo setLeftMargin:36.0];
	[pInfo setRightMargin:36.0];
	[pInfo setTopMargin:72.0];
	[pInfo setBottomMargin:36.0];
	// create new view just for printing
	NSTextView *printView = [[NSTextView alloc]initWithFrame: [pInfo imageablePageBounds]];
	// copy the textview into the printview
	NSData* textData = [self RTFDFromRange:NSMakeRange(0, [[self textStorage] length])];
	NSRange textViewRange = NSMakeRange(0, 0);
	
	[printView replaceCharactersInRange: textViewRange 
							   withRTFD:textData];
	
    [printView setDrawsBackground:NO];
	
	NSPrintOperation* op = [NSPrintOperation printOperationWithView: printView printInfo: 
							pInfo];
	//[op setShowsProgressPanel: YES];
	[op runOperationModalForWindow:[self window] delegate:nil didRunSelector:nil contextInfo:nil];
	
	
	[printView release];
	
}
@end

@implementation ORPrintableOutlineView
- (IBAction) print:(id)sender
{
	// set printing properties
	NSPrintInfo* pInfo = [[(ORAppDelegate*)[NSApp delegate]document] printInfo];
	[pInfo setHorizontalPagination:NSFitPagination];
	[pInfo setHorizontallyCentered:NO];
	[pInfo setVerticallyCentered:NO];
	[pInfo setLeftMargin:36.0];
	[pInfo setRightMargin:36.0];
	[pInfo setTopMargin:72.0];
	[pInfo setBottomMargin:36.0];
	// create new view just for printing
	NSPrintOperation* op = [NSPrintOperation printOperationWithView: self printInfo: pInfo];
	//[op setShowsProgressPanel: YES];
	[op runOperationModalForWindow:[self window] delegate:nil didRunSelector:nil contextInfo:nil];
}

@end


#pragma mark ¥¥¥¥¥Log Helper Function
//----------------------------------------------------------------------------------------------------
//NSLogString
//	a helper function to redirect a call to logStatus to a logger defined by the NSApp delegate
//----------------------------------------------------------------------------------------------------
void NSLogString(NSString* s,...)
{
    NSColor* aColor = [NSColor blackColor];
    @try {
        va_list myArgs;
        va_start(myArgs,s);
        
        NSAttributedString* s1 = [[[NSAttributedString alloc]
                                   initWithString:[[[NSString alloc] initWithFormat:s
                                                                             locale:nil
                                                                          arguments:myArgs] autorelease]
                                   attributes:[NSDictionary dictionaryWithObject:aColor
                                                                          forKey:NSForegroundColorAttributeName ]]autorelease];
        va_end(myArgs);
        
        [sharedStatusController printAttributedString:s1];
    }
    @catch(NSException* localException) {
    }
}

//----------------------------------------------------------------------------------------------------
//NSLogAttr
//	A function to print out attributed strings to the log.
//----------------------------------------------------------------------------------------------------
void NSLogAttr(NSAttributedString* s)
{
    [sharedStatusController printAttributedString:s];
}


//----------------------------------------------------------------------------------------------------
//NSLogColor
//	a helper function to output colorized text
//----------------------------------------------------------------------------------------------------
void NSLogColor(NSColor* aColor,NSString* s,...)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        va_list myArgs;
        va_start(myArgs,s);
        
        NSAttributedString* s1 = [[[NSAttributedString alloc]
                                   initWithString:[[[NSString alloc] initWithFormat:s
                                                                             locale:nil
                                                                          arguments:myArgs] autorelease]
                                   attributes:[NSDictionary dictionaryWithObject:aColor
                                                                          forKey:NSForegroundColorAttributeName ]]autorelease];
        va_end(myArgs);
        [sharedStatusController printAttributedString:s1];
        
	}
	@catch(NSException* localException) {
	}
	[pool release];
}

//----------------------------------------------------------------------------------------------------
//NSLogFont
//	a helper function to output different fonts
//----------------------------------------------------------------------------------------------------
void NSLogFont(NSFont* aFont,NSString* s,...)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        va_list myArgs;
        va_start(myArgs,s);
        NSAttributedString* s1 = [[[NSAttributedString alloc]
                                   initWithString:[[[NSString alloc] initWithFormat:s
                                                                             locale:nil
                                                                          arguments:myArgs] autorelease]
                                    attributes:[NSDictionary dictionaryWithObject:aFont
                                                                          forKey:NSFontAttributeName ]] autorelease];
        va_end(myArgs);
        [sharedStatusController printAttributedString:s1];
	}
	@catch(NSException* localException) {
	}
	[pool release];
}

void NSLogMono(NSString* s,...)
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        va_list myArgs;
        va_start(myArgs,s);
        NSFont* aFont = [NSFont fontWithName:@"Monaco" size:11];
        NSAttributedString* s1 = [[[NSAttributedString alloc]
                                   initWithString:[[[NSString alloc] initWithFormat:s
                                                                             locale:nil
                                                                          arguments:myArgs] autorelease]
                                   attributes:[NSDictionary dictionaryWithObject:aFont
                                                                          forKey:NSFontAttributeName ]] autorelease];
        va_end(myArgs);
        [sharedStatusController printAttributedString:s1];
    }
    @catch(NSException* localException) {
    }
    [pool release];
}

void NSLogStartTable(NSString* aTitle,int aWidth)
{
    aTitle = [aTitle stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSString* dashes = @"_";
    NSUInteger len = [aTitle length];
    int i;
    for(i=0;i<len;i++){
        dashes = [dashes stringByAppendingString:@"_"];
    }
    NSLogMono(@"%@\n",[dashes rightJustified:len + 6]);
    NSLogMono(@"   / %@ \\\n",aTitle);
    dashes = @"=";
    for(i=0;i<aWidth-1;i++){
        dashes = [dashes stringByAppendingString:@"="];
    }
    NSLogMono(@"%@\n",dashes);
}
void NSLogDivider(NSString* divider, int aWidth)
{
    NSString* dash = [divider substringToIndex:1];
    NSMutableString* dashes = [[@"" mutableCopy]autorelease];
    int i;
    for(i=0;i<aWidth;i++){
        [dashes appendString:dash];
    }
    NSLogMono(@"%@\n",dashes);

}
//----------------------------------------------------------------------------------------------------
//LogError
//	a helper function to redirect a call to logError to a logger defined by the NSApp delegate
//----------------------------------------------------------------------------------------------------
void NSLogError(NSString* aString,...)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        va_list myArgs;
        va_start(myArgs,aString);
        
        NSDate* now = [NSDate date];
        NSString* s1 = [NSString stringWithFormat:@"%@ %@",[now stdDescription],aString];
        
        NSMutableArray* theArgs = [NSMutableArray arrayWithCapacity:10];
        while(1) {
            id obj = va_arg(myArgs, id);
            if(!obj)break;
            [theArgs addObject:obj];
        }
        va_end(myArgs);
        
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[sharedStatusController methodSignatureForSelector:@selector(logError:usingKeyArray:)]];
        
        [invocation setTarget:sharedStatusController];
        [invocation setSelector:@selector(logError:usingKeyArray:)];
        [invocation setArgument:&s1 atIndex:2];
        [invocation setArgument:&theArgs atIndex:3];
        [invocation retainArguments];
        
        [sharedStatusController performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:NO];
        
	}
	@catch(NSException* localException) {
	}
	[pool release];
}

@implementation ORStatusController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) deleteHistoryActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){		
		NSString* alarmHistoryPath = [[ApplicationSupport sharedApplicationSupport] applicationSupportFolder:@"History"];
		alarmHistoryPath = [alarmHistoryPath stringByAppendingPathComponent:@"Alarms"];
		NSFileManager* fm = [NSFileManager defaultManager];
		[fm removeItemAtPath:alarmHistoryPath error:nil];
		[alarmLogView setString:@""];
		NSLog(@"Alarm history deleted\n");
	}
}
#endif
- (void) mainThreadPrint:(NSAttributedString*)s1
{
    if(![NSThread isMainThread])return;
    [sharedStatusController scheduleCouchDBUpdate];

    NSDate* now  	= [NSDate date];
    NSMutableAttributedString* now_Attr = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",[now stdDescription]] attributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName ]] autorelease];
    
    [now_Attr appendAttributedString:s1];
    
    
    [s1 retain];

    [statusView replaceCharactersInRange:NSMakeRange([self statusTextlength], 0) withString:[now_Attr string]];
    [statusView scrollRangeToVisible: NSMakeRange([self statusTextlength], 0)];
    
    if([self statusTextlength] > kMaxTextSize){
        [[statusView textStorage] deleteCharactersInRange:NSMakeRange(0,kMaxTextSize/3)];
        NSString* theText = [[statusView textStorage] string];
        NSRange endOfLineRange = [theText rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
        NSUInteger extra = 0;
        if(endOfLineRange.location != NSNotFound){
            [[statusView textStorage] deleteCharactersInRange:NSMakeRange(0,endOfLineRange.location)];
            extra = endOfLineRange.location;
        }
        [[NSNotificationCenter defaultCenter]postNotificationName:ORStatusFlushedNotification
                                                           object:self
                                                         userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    [NSNumber numberWithInteger:kMaxTextSize/3+extra],ORStatusFlushSize,nil]];
    }
    
    NSUInteger len = [now_Attr length];
    NSUInteger i=0;
    while (i<len) {
        NSRange range;
        NSDictionary* dict = [now_Attr attributesAtIndex:i effectiveRange:&range];
        range.location += [self statusTextlength] - len;
        [[statusView textStorage] setAttributes:dict range:range];
        i += range.length;
    }
    [s1 release];
    
}
@end
