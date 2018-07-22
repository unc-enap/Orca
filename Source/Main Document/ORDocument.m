//
//  ORDocument.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 03 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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
#define __CARBONSOUND__ //temp until undated to >10.3
#import <Carbon/Carbon.h>
#import "ORStatusController.h"
#import "ORDocumentController.h"
#import "ORAlarmCollection.h"
#import "ORProcessCenter.h"
#import "ORUSB.h"

#import "ORTaskMaster.h"
#import "ORHWWizardController.h"
#import "ORCommandCenter.h"

@implementation ORDocument

#pragma mark ¥¥¥Document ID Strings
static NSString* ORDocumentType       = @"Orca Experiment"; //must == CFBundleTypeName entry in Info.plist file.
static NSString* ORDocumentVersionKey = @"Version";
static int       ORDocumentVersion    = 1;

#pragma mark ¥¥¥External Strings
NSString* ORStatusTextChangedNotification   = @"Status Text Has Changed";
NSString* ORDocumentLoadedNotification      = @"ORDocumentLoadedNotification";
NSString* ORDocumentScaleChangedNotification= @"ORDocumentScaleChangedNotification";
NSString* ORDocumentClosedNotification		=@"ORDocumentClosedNotification";
NSString* ORDocumentLock					= @"ORDocumentLock";

#pragma mark ¥¥¥Initialization
- (id)init
{
    if(self =[super init]){
		[ORStatusController sharedStatusController];
        
        [(ORAppDelegate*)[NSApp delegate] setDocument:self];
        [self setGroup:[[[ORGroup alloc] init] autorelease]];
        
       	[self setOrcaControllers:[NSMutableArray array]];
        
        NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
        [notifyCenter addObserver : self
                         selector : @selector(windowClosing:)
                             name : NSWindowWillCloseNotification
                           object : nil];
        
        
        [notifyCenter addObserver : self
                         selector : @selector(objectsRemoved:)
                             name : ORGroupObjectsRemoved
                           object : nil];
        
        
        [ORCommandCenter sharedCommandCenter];
       // [[ORUSB sharedUSB] searchForDevices];

    }
    return self;
}

- (id) initForURL:(NSURL *)url withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)typeName error:(NSError **)outError
{
    @try {
        if([(ORAppDelegate*)[NSApp delegate] document]){
            NSLogColor([NSColor redColor],@"Did not open [%@]. Only one experiment can be open at a time\n",[[url path] stringByAbbreviatingWithTildeInPath]);
            return nil;
        }
        else {
           id theDoc =  [super initForURL:url withContentsOfURL:contentsURL ofType:typeName error:outError];
            if(theDoc)NSLog(@"Opened [%@]\n",[[url path] stringByAbbreviatingWithTildeInPath]);
            return theDoc;
        }
    }
    @catch(NSException* e){
        NSLog(@"Exception thrown trying to open [%@]\n",[[url path] stringByAbbreviatingWithTildeInPath]);
        [(ORAppDelegate*)[NSApp delegate] setDocument:nil];
    }
    return nil;
}
- (id) initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
    @try {
        if([(ORAppDelegate*)[NSApp delegate] document]){
            NSLogColor([NSColor redColor],@"Did not open [%@]. Only one experiment can be open at a time\n",[[url path] stringByAbbreviatingWithTildeInPath]);
            return nil;
        }
        else {
            id theDoc =  [super initWithContentsOfURL:url ofType:typeName error:outError];
            if(theDoc)NSLog(@"Opened [%@]\n",[[url path] stringByAbbreviatingWithTildeInPath]);
            return theDoc;
        }
    }
    @catch(NSException* e){
        NSLog(@"Exception thrown trying to open [%@]\n",[[url path] stringByAbbreviatingWithTildeInPath]);
        [(ORAppDelegate*)[NSApp delegate] setDocument:nil];
    }
    return nil;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [statusText release];
	@try {
		[orcaControllers makeObjectsPerformSelector:@selector(close)];
		[orcaControllers release];
	}
	@catch(NSException* localException) {
	}
    [group sleep];
    [group release];
    [customRunParameters release];

    [[self undoManager] removeAllActions];
	//RestoreApplicationDockTileImage();
    
	[(ORAppDelegate*)[NSApp delegate] setDocument:nil];
    //[self setDbConnection:nil];
    [super dealloc];
}

#pragma mark ¥¥¥Assessors

- (BOOL) documentCanBeChanged
{
    return ![gSecurity isLocked:ORDocumentLock] && ![gOrcaGlobals runInProgress] && ![gOrcaGlobals testInProgress];
}

- (void)setGroup:(ORGroup *)aGroup
{ 
    [aGroup retain];
    [group release];
    group = aGroup;
}

- (ORGroup*)group
{
    return group;
}


- (NSMutableArray*) orcaControllers
{
    return orcaControllers;
}
- (void) setOrcaControllers:(NSMutableArray*)newOrcaControllers
{
    [newOrcaControllers retain];
    [orcaControllers release];
    orcaControllers = newOrcaControllers;
}


- (int)scaleFactor 
{
    
    return scaleFactor;
}

- (void)setScaleFactor:(int)aScaleFactor 
{
    if(aScaleFactor < 20)aScaleFactor = 20;
    else if(aScaleFactor>150)aScaleFactor=150;
    
    if(abs(aScaleFactor-scaleFactor)>1){
        [[[self undoManager] prepareWithInvocationTarget:self] setScaleFactor:scaleFactor];
		
        scaleFactor = aScaleFactor;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDocumentScaleChangedNotification
                                                            object:self];
    }
}


- (NSString*) statusText
{
    return statusText;
}

- (void) setStatusText:(NSString*)aName
{
    //not undoable..
    
    [statusText autorelease];
    statusText = [aName copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORStatusTextChangedNotification
	 object:self];
    
}

- (void) assignUniqueIDNumber:(id)objToGetID
{
    if(![objToGetID uniqueIdNumber]){
        NSArray* objects = [self collectObjectsOfClass:[objToGetID class]];
        uint32_t anId = 1;
        do {
            BOOL idAlreadyUsed = NO;
            for(id anObj in objects){
                if(anObj == objToGetID)continue;
                if([anObj uniqueIdNumber] == anId){
                    anId++;
                    idAlreadyUsed = YES;
                    break;
                }
            }
            if(!idAlreadyUsed){
                [objToGetID setUniqueIdNumber:anId];
                break;
            }
        }while(1);
    }
}

#pragma mark ¥¥¥Window Management
- (void) makeWindowControllers
{
    ORDocumentController* documentController = [[ORDocumentController alloc] init];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:@"Preloading Catalog..." forKey:@"Message"]];
	[documentController preloadCatalog];
	
	
    if(scaleFactor == 0)[self setScaleFactor:100];
    [self addWindowController:documentController];
    [documentController showWindow:self];
	
    [documentController release];
}

- (void) resetAlreadyVisitedInChainSearch
{
	[[self group] resetAlreadyVisitedInChainSearch];
}

- (NSArray*) collectObjectsWithClassName:(NSString*)aClassName
{
    return [self collectObjectsOfClass:NSClassFromString(aClassName)];
}


- (NSArray*) collectObjectsOfClass:(Class)aClass
{
    return [[self group] collectObjectsOfClass:aClass];
}

- (NSArray*) collectObjectsConformingTo:(Protocol*)aProtocol
{
    return [[self group] collectObjectsConformingTo:aProtocol];
}

- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector
{
    return [[self group] collectObjectsRespondingTo:aSelector];
}

- (id) findObjectWithFullID:(NSString*)aFullID
{
    return [[self group] findObjectWithFullID:aFullID];
}

- (NSMutableDictionary*) fillInHeaderInfo:(NSMutableDictionary*)dictionary
{
	//add in the document parameters
	NSMutableDictionary* docDict = [NSMutableDictionary dictionary];
    [docDict setObject:[[self fileURL]path] forKey:@"documentName"];
    [docDict setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"OrcaVersion"];
	
	NSFileManager* fm			= [NSFileManager defaultManager];
	NSString* svnVersionPath	= [[NSBundle mainBundle] pathForResource:@"svnversion"ofType:nil];
	NSMutableString* svnVersion = [NSMutableString stringWithString:@""];
	
	if([fm fileExistsAtPath:svnVersionPath]){
		svnVersion = [NSMutableString stringWithContentsOfFile:svnVersionPath encoding:NSASCIIStringEncoding error:nil];
		if([svnVersion hasSuffix:@"\n"]){
			[svnVersion replaceCharactersInRange:NSMakeRange([svnVersion length]-1, 1) withString:@""];
		}
	}
	
    [docDict setObject:[svnVersion length]?svnVersion:@"0"   forKey:@"svnModVersion"];

    [docDict setObject:[NSString stringWithFormat:@"%@",[[NSDate date] stdDescription]]   forKey:@"date"];
    [dictionary setObject:docDict forKey:@"Document Info"];
		
	//setup and add Objects to object info list
	NSMutableDictionary* objectInfoDictionary = [NSMutableDictionary dictionary];
	NSMutableArray* allObjects		= (NSMutableArray*)[self collectObjectsOfClass:NSClassFromString(@"OrcaObject")];
	NSMutableArray* crates			= [NSMutableArray array];
	NSMutableArray* dataChain		= [NSMutableArray array];
	NSMutableArray* gpib			= [NSMutableArray array];
	NSMutableArray* usb				= [NSMutableArray array];
	NSMutableArray* serial			= [NSMutableArray array];
	NSMutableArray* auxHw			= [NSMutableArray array];
	NSMutableDictionary* exp		= [NSMutableDictionary dictionary];
	for(id anObj in allObjects){
		if([anObj isKindOfClass:NSClassFromString(@"ORCrate")]){
			if([anObj respondsToSelector:@selector(addObjectInfoToArray:)]){
				[anObj addObjectInfoToArray:crates];
			}
		}
		else if([anObj isKindOfClass:NSClassFromString(@"ORDataChainObject")]){
			if([anObj respondsToSelector:@selector(addObjectInfoToArray:)]){
				[anObj addObjectInfoToArray:dataChain];
			}
		}
		else if([anObj isKindOfClass:NSClassFromString(@"ORDataChainObjectWithGroup")]){//TODO: Mark, check if this is OK -tb- Till 2013-05-24
			if([anObj respondsToSelector:@selector(addObjectInfoToArray:)]){
				[anObj addObjectInfoToArray:dataChain];
			}
		}
		else if([anObj isKindOfClass:NSClassFromString(@"ORGpibDeviceModel")]){
			if([anObj respondsToSelector:@selector(addObjectInfoToArray:)]){
				[anObj addObjectInfoToArray:gpib];
			}
		}
		else if([anObj isKindOfClass:NSClassFromString(@"ORSerialDeviceModel")]){
			if([anObj respondsToSelector:@selector(addObjectInfoToArray:)]){
				[anObj addObjectInfoToArray:serial];
			}
		}
		else if([anObj isKindOfClass:NSClassFromString(@"ORUsbDeviceModel")]){
			if([anObj respondsToSelector:@selector(addObjectInfoToArray:)]){
				[anObj addObjectInfoToArray:usb];
			}
		}
		else if([anObj isKindOfClass:NSClassFromString(@"ORExperimentModel")]){
			if([anObj respondsToSelector:@selector(addParametersToDictionary:)]){
				[anObj addParametersToDictionary:objectInfoDictionary];
			}
		}
        
		else if([anObj isKindOfClass:NSClassFromString(@"ORAuxHw")]){
			if([anObj respondsToSelector:@selector(addObjectInfoToArray:)]){
				[anObj addObjectInfoToArray:auxHw];
			}
		}
        
        
	}
	
	
	if([crates count]){
		[objectInfoDictionary setObject:crates forKey:@"Crates"];
	}
	if([dataChain count]){
		[objectInfoDictionary setObject:dataChain forKey:@"DataChain"];
	}
	if([gpib count]){
		[objectInfoDictionary setObject:gpib forKey:@"Gpib"];
	}
	if([usb count]){
		[objectInfoDictionary setObject:usb forKey:@"USB"];
	}
	if([serial count]){
		[objectInfoDictionary setObject:serial forKey:@"Serial"];
	}
	if([auxHw count]){
		[objectInfoDictionary setObject:auxHw forKey:@"AuxHw"];
	}
	if([exp count]){
		[objectInfoDictionary setObject:exp forKey:@"Experiments"];
	}
    if(customRunParameters){
        [objectInfoDictionary setObject:customRunParameters forKey:@"Custom"];
        [customRunParameters release];
        customRunParameters = nil;
    }
	//add the Object Info into the dictionary from our argument list.
	if([objectInfoDictionary count]){
		[dictionary setObject:objectInfoDictionary forKey:@"ObjectInfo"];
	}
    return dictionary;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	return [group addParametersToDictionary:dictionary];
}

- (void) addCustomRunParameters:(id)anObject forKey:(NSString*)aKey
{
    if(!customRunParameters)customRunParameters = [[NSMutableDictionary dictionary] retain];
    [customRunParameters setObject:anObject forKey:aKey];
}

#pragma mark ¥¥¥Archival
static NSString* ORGroupKey             = @"ORGroup";
static NSString* OROrcaControllers	    = @"OROrcaControllers";
static NSString* ORTaskMasterVisibleKey = @"ORTaskMasterVisibleKey";
static NSString* ORDocumentScaleFactor  = @"ORDocumentScaleFactor";

- (NSData *)dataOfType:(NSString *)type error:(NSError **)outError
{
	//special case -- if the config file came from a fall back config, then we won't store it as the last file
	NSString* lastFile = [[NSUserDefaults standardUserDefaults] stringForKey:@"config"];
	if(![lastFile length]){
		[self performSelector:@selector(saveDefaultFileName) withObject:nil afterDelay:0];
	}
	if ([type isEqualToString:ORDocumentType]) {
		
		NSMutableData *data = [NSMutableData data];
		NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		
		[[ORGlobal sharedGlobal] saveParams:archiver];
		
		//PH comment out so archiver uses the default binary plist format
		//[archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
		
		[archiver encodeInteger:ORDocumentVersion forKey:ORDocumentVersionKey];
		
		[archiver encodeObject:[self group] forKey:ORGroupKey];
		
		[archiver encodeObject:[self controllersToSave] forKey:OROrcaControllers];						
		
		[archiver encodeBool:[[[ORTaskMaster sharedTaskMaster] window] isVisible] forKey:ORTaskMasterVisibleKey];
		
		[archiver encodeInteger:scaleFactor forKey:ORDocumentScaleFactor];						
        
		
		[[ORAlarmCollection sharedAlarmCollection] encodeEMailList:archiver];
		[[ORStatusController sharedStatusController] encode:archiver];
		[[ORStatusController sharedStatusController] saveLogBook:nil];

		[archiver finishEncoding];
		
		[archiver release];
		
		[[self undoManager] removeAllActions];
		
		[self performSelector:@selector(saveFinished) withObject:nil afterDelay:0];
		
		return data;
	}
    
    return nil;
}

- (void) saveFinished
{
	NSLog(@"Saved Configuration: %@\n",[[self fileURL] path]);
	@try {
		[afterSaveTarget performSelector:afterSaveSelector];
	}
	@catch(NSException* localException) {
	}
	afterSaveTarget = nil;
}
- (void) afterSaveDo:(SEL)aSelector withTarget:(id)aTarget
{
	afterSaveTarget = aTarget;
	afterSaveSelector = aSelector;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)type error:(NSError **)outError;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:@"Loading Configuration..." forKey:@"Message"]];
	if ([type isEqualToString:ORDocumentType]) {
		
		//special case -- if the config file came from a fall back config, then we won't store it as the last file
		NSString* lastFile = [[NSUserDefaults standardUserDefaults] stringForKey:@"config"];
		if(![lastFile length]){
			[self performSelector:@selector(saveDefaultFileName) withObject:nil afterDelay:0];
		}
		
		[[self undoManager] disableUndoRegistration];
		
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		
		[self setGroup:[unarchiver decodeObjectForKey:ORGroupKey]];	    
		[[ORGlobal sharedGlobal] loadParams:unarchiver];
		
		[[ORAlarmCollection sharedAlarmCollection] decodeEMailList:unarchiver];
		[[ORStatusController sharedStatusController] decode:unarchiver];
		
		@try {
			if((GetCurrentKeyModifiers() & shiftKey) == 0){
				[self setOrcaControllers:[unarchiver decodeObjectForKey:OROrcaControllers]];
				[self checkControllers];
			}
			else {
				NSLogColor([NSColor redColor], @"Shift Key down....Dialogs NOT loaded.\n");
			}
		}
		@catch(NSException* localException) {
			NSLogColor([NSColor redColor], @"Something wrong with the dialog configuration... Dialogs NOT restored\n");
			NSLogColor([NSColor redColor], @"but model data OK.\n");		
		}
		
		if([unarchiver decodeBoolForKey:ORTaskMasterVisibleKey] == YES){
			[[[ORTaskMaster sharedTaskMaster] window] orderFront:nil];
		}
		
		
		int value = [unarchiver decodeIntForKey:ORDocumentScaleFactor];
		if(value == 0)value = 100;
		[self setScaleFactor:value];
		
		
		[unarchiver finishDecoding];
		[unarchiver release];
		
		[[self undoManager] enableUndoRegistration];
		
		[[self group] wakeUp];
		

		for(id controller in orcaControllers){
			@try {
				[[controller window] orderFront:controller];
			}
			@catch(NSException* localException) {
			}
		}

		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:ORDocumentLoadedNotification
		 object:self];
		
		@try {
			//[[ORUSB sharedUSB] awakeAfterDocumentLoaded];
			[group awakeAfterDocumentLoaded];
		}
		@catch(NSException* localException) {
		}
		
		[[ORProcessCenter sharedProcessCenter] awakeAfterDocumentLoaded];
		
		[[self undoManager] removeAllActions];
		
		
		return YES;
	}
	return NO;
}

- (NSArray*) controllersToSave
{
	NSMutableArray* controllersToSave = [NSMutableArray array];
    for(id controller in orcaControllers){
        if([controller model] != [[ORCommandCenter sharedCommandCenter] scriptIDEModel]){
            [controllersToSave addObject:controller];
        }
    }
	return controllersToSave;
}

- (void) checkControllers
{
    NSMutableArray* badObjs = [NSMutableArray array];
    for (id controller in orcaControllers){
        if(![controller isKindOfClass:[OrcaObjectController class]]){
            [badObjs addObject:controller];
        }
    }
    [orcaControllers removeObjectsInArray:badObjs];
}

- (void) saveDocument:(id)sender
{
	if([self isDocumentEdited])[[ORGlobal sharedGlobal] setDocumentWasEdited:YES];
	[super saveDocument:sender];
}


- (void) saveDefaultFileName
{
	NSString* theLastFile = [[self fileURL]path];
    [[NSUserDefaults standardUserDefaults] setObject:theLastFile forKey:ORLastDocumentName];
}

- (void) copyDocumentTo:(NSString*)aPath append:(NSString*)aString
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* path = [aPath stringByAppendingPathComponent:[[[self fileURL] path ]lastPathComponent]];
    NSString* ext = [[[self fileURL] path]pathExtension];
    path = [path stringByDeletingPathExtension];
	NSString* startName = [[self fileURL] path];
    NSString* finalName = [[path stringByAppendingFormat:@"_%@",aString]stringByAppendingPathExtension:ext];
    NSError* copyError=nil;
    if([fm copyItemAtPath:startName toPath:finalName error:&copyError]){
        NSLog(@"Copy %@ to %@\n",startName,finalName);
    }
    else {
        NSLogColor([NSColor redColor],@"Error: Unable to copy %@ to %@\n",startName,finalName);
        NSLogColor([NSColor redColor],@"%@\n",copyError);
    }
    
}


#pragma mark ¥¥¥Orca Dialog Management
- (void) duplicateDialog:(id)dialog
{
    
    id controller = [[NSClassFromString([dialog className]) alloc] init];
    
    if([controller isKindOfClass:[OrcaObjectController class]]){
        
        [controller setModel:[dialog model]];
        
        if(!orcaControllers){
            [self setOrcaControllers:[NSMutableArray array]];
        }
        
        [orcaControllers addObject:controller];
        [controller showWindow:self];
    }
    [controller release];
}

- (void) makeController:(NSString*)aClassName forObject:(id)aModel
{
    
    BOOL shareDialogs = ![[[NSUserDefaults standardUserDefaults] objectForKey: OROpeningDialogPreferences] intValue];
    
    BOOL optionKeyIsDown = ([[NSApp currentEvent] modifierFlags] & 0x80000)>0;
    
    if(optionKeyIsDown) {
        if(shareDialogs)shareDialogs = NO;
        else shareDialogs = YES;
    }
    
    
    //if a dialog already exists then use it no matter what.
    for(id controller in orcaControllers){
        if([controller model] == aModel){
            [controller showWindow:self];
			[[controller window] makeFirstResponder:[controller window]];
            return;
        }
    }
    
    //ok, the dialog doesn't exist yet....
    if(shareDialogs == YES){
        //try to share one
        for(id controller in orcaControllers){
            if([controller class] == NSClassFromString(aClassName)){
                [controller setModel:aModel];
                [controller showWindow:self];
				[[controller window] makeFirstResponder:[controller window]];
                return;
            }
        }
    }
    
    //if we get here then we'll have to make one.
    id controller = [[NSClassFromString(aClassName) alloc] init];
    if([controller isKindOfClass:[OrcaObjectController class]]){
        
        [controller setModel:aModel];
        
        if(!orcaControllers){
            [self setOrcaControllers:[NSMutableArray array]];
        }
        
		[orcaControllers addObject:controller];

        [controller showWindow:self];
		//[[controller window] makeFirstResponder:[controller window]];
    }
    [controller release];
}

- (void) makeControllerPDF:(NSString*)aClassName forObject:(id)aModel
{
    id controller = [[[NSClassFromString(aClassName) alloc] init]autorelease];
    if([controller isKindOfClass:[OrcaObjectController class]]){
        [[controller window] setFrameOrigin:NSMakePoint(8000,8000)];
        [controller setModel:aModel];
		[[[controller window] contentView] setNeedsDisplay:YES];
		[self performSelector:@selector(makePDFFromController:) withObject:controller afterDelay:0];
	}
}

- (void) makePDFFromController:(id)aController
{
	NSData* pdfData = [[aController window] dataWithPDFInsideRect:[[[aController window] contentView]frame]];
	[pdfData writeToFile:[@"~/ORCAPages/page.pdf" stringByExpandingTildeInPath] atomically:NO];
}


- (void)objectsRemoved:(NSNotification*)aNote
{
    NSArray* list = [[aNote userInfo] objectForKey:ORGroupObjectList];
    for(id anObj in list){
        NSArray* totalList = [anObj familyList];    
        for(id objToBeRemoved in totalList){
            id controllersToRemove = [self findControllersWithModel:objToBeRemoved];
            [orcaControllers removeObjectsInArray:controllersToRemove];
			//tricky, we also have to worry about objects that have subobjects that have dialogs
			id subObjectsToBeRemoved = [objToBeRemoved subObjectsThatMayHaveDialogs];
			for(id subObjectToBeRemoved in subObjectsToBeRemoved){
				controllersToRemove = [self findControllersWithModel:subObjectToBeRemoved];
	            [orcaControllers removeObjectsInArray:controllersToRemove];
			}
        }
    }
    
}

- (NSArray*) findControllersWithModel:(id)obj
{ 
    NSMutableArray* list = [NSMutableArray array];
    for(id controller in orcaControllers){
        if([controller model] == obj){
            [list addObject:controller];
        }
    }
    return list;
}

- (void)windowClosing:(NSNotification*)aNote
{
    
    for(id controller in orcaControllers){
        if([controller window] == [aNote object]){
            //[controller retain];
			@try {
                [[NSNotificationCenter defaultCenter] removeObserver:controller];
                [controller setModel:nil];
				[orcaControllers removeObject:controller];
			}
			@catch(NSException* localException) {
			}
			// [controller performSelector:@selector(release) withObject:nil afterDelay:.1];
            break;
        }
    }
}

- (BOOL) shouldCloseWindowController:(NSWindowController *)windowController 
{
	if (![windowController isKindOfClass:NSClassFromString(@"ORDocumentController")]){
		return YES;
	}
	else if([[ORGlobal sharedGlobal] forcedHalt]){
		return YES;
	}
    else if([[ORGlobal sharedGlobal] runInProgress]){
        ORRunAlertPanel(@"Run In Progess", @"Experiment can NOT be closed.", nil, nil,nil);
        return NO;
    }
    else if([self isDocumentEdited]){
        ORRunAlertPanel(@"Document Unsaved", @"Experiment can NOT be closed.", nil, nil,nil);
        return NO;
    }
	else {
		NSString* s;
		NSString* buttonString;
		int runningProcessCount = [[ORProcessCenter sharedProcessCenter] numberRunningProcesses];
		if(runningProcessCount>0){
			s = [NSString stringWithFormat:@"Closing main window will close this experiment and %d Running Process%@!",runningProcessCount,runningProcessCount>1?@"es":@""];
			buttonString = @"Stop Processes and Close Experiment";
		}
		else {
			s = @"Closing main window will close this experiment!";
			buttonString = @"Close Experiment";
		}
        BOOL cancel = ORRunAlertPanel(s,@"Is this really what you want?",@"Cancel",buttonString,nil);
        if(!cancel){
            //[[self undoManager] removeAllActions];
            [[NSNotificationCenter defaultCenter]
			 postNotificationName:ORDocumentClosedNotification
			 object:self];
            NSLog(@"Closing [%@]\n",[[[self fileURL]path] stringByAbbreviatingWithTildeInPath]);
            return YES;
        }
        else return NO;
        
    }
}

- (void) windowMovedToFront:(NSWindowController*)aController
{
    if(aController && [orcaControllers containsObject:aController]){
        [aController retain];
        [orcaControllers removeObject:aController];
        [orcaControllers addObject:aController];
        [aController release];
    }
}
- (void) closeAllWindows
{
	[orcaControllers makeObjectsPerformSelector:@selector(close)];
}
@end
