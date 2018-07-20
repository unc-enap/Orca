//
//  ORRunNotesModel.m
//  Orca
//
//  Created by Mark Howe on Tues Feb 09 2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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
#import "ORRunNotesModel.h"
#import "ORDataPacket.h"
#import "ORDataProcessing.h"

#pragma mark •••Local Strings
NSString* ORRunNotesModelDefinitionsFilePathChanged = @"ORRunNotesModelDefinitionsFilePathChanged";
static NSString* ORRunNotesInConnector 	= @"Data Task In Connector";
static NSString* ORRunNotesDataOut      = @"Data Task Data Out Connector";

NSString* ORRunNotesModelDoNotOpenChanged	 = @"ORRunNotesModelDoNotOpenChanged";
NSString* ORRunNotesModelIgnoreValuesChanged = @"ORRunNotesModelIgnoreValuesChanged";
NSString* ORRunNotesModelModalChanged		 = @"ORRunNotesModelModalChanged";
NSString* ORRunNotesItemsAdded				 = @"ORRunNotesItemsAdded";
NSString* ORRunNotesItemsRemoved		     = @"ORRunNotesItemsRemoved";
NSString* ORRunNotesCommentsChanged			 = @"ORRunNotesCommentsChanged";
NSString* ORRunNotesListLock				 = @"ORRunNotesListLock";
NSString* ORRunNotesItemChanged				 = @"ORRunNotesItemChanged";

@implementation ORRunNotesModel

#pragma mark •••initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [definitionsFilePath release];
	[items release];
    [super dealloc];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(8,[self frame].size.height-[self frame].size.height/2+kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORRunNotesInConnector];
    [aConnector setOffColor:[NSColor purpleColor]];
    [aConnector setConnectorType:'RUNC'];
    [aConnector release];
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize-2,[self frame].size.height-[self frame].size.height/2+kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORRunNotesDataOut];
	[aConnector setIoType:kOutputConnector];
    [aConnector setOffColor:[NSColor purpleColor]];
    [aConnector setConnectorType:'RUNC'];
    [aConnector release];
}

- (BOOL) solitaryObject
{
    return YES;
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
	if(ignoreValues || doNotOpen){
		NSImage* aCachedImage = [NSImage imageNamed:@"RunNotes"];
		NSSize theIconSize = [aCachedImage size];
		
		NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
		[i lockFocus];
		
        [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
		NSImage* aNoticeImage = [NSImage imageNamed:@"notice"];
		[aNoticeImage drawAtPoint:NSMakePoint([i size].width/2-[aNoticeImage size].width/2 ,[i size].height/2-[aNoticeImage size].height) fromRect:[aNoticeImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
		
		[i unlockFocus];
		
		[self setImage:i];
		[i release];
		
	}
	else [self setImage:[NSImage imageNamed:@"RunNotes"]];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
}


- (void) makeMainController
{
    [self linkToController:@"ORRunNotesController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Run_Notes.html";
}

#pragma mark ***Accessors

- (NSString*) definitionsFilePath
{
    if([definitionsFilePath length])return @"";
    else                            return definitionsFilePath;
}

- (void) setDefinitionsFilePath:(NSString*)aDefinitionsFilePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDefinitionsFilePath:definitionsFilePath];
    if([aDefinitionsFilePath length]==0)aDefinitionsFilePath= @"";
    [definitionsFilePath autorelease];
    definitionsFilePath = [aDefinitionsFilePath copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesModelDefinitionsFilePathChanged object:self];
}
- (BOOL) doNotOpen
{
    return doNotOpen;
}

- (void) setDoNotOpen:(BOOL)aDoNotOpen
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoNotOpen:doNotOpen];
    
    doNotOpen = aDoNotOpen;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesModelDoNotOpenChanged object:self];
	
	[self setUpImage];
}

- (BOOL) ignoreValues
{
    return ignoreValues;
}

- (void) setIgnoreValues:(BOOL)aIgnoreValues
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnoreValues:ignoreValues];
    
    ignoreValues = aIgnoreValues;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesModelIgnoreValuesChanged object:self];
	[self setUpImage];
}

- (BOOL) isModal
{
	return isModal;
}

- (void) setIsModal:(BOOL)state
{
	isModal = state;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesModelModalChanged object:self];
}

- (BOOL) runModals
{
	BOOL continueRun = NO;
	if(doNotOpen)continueRun = YES;
	else {
		[self makeMainController];
		NSWindow* myWindow = [[self findController] window];
		[myWindow center];
		if(!myWindow)continueRun = YES;
		else {
			[self setIsModal:YES];
			modalResult = 0;
			NSModalSession session = [NSApp beginModalSessionForWindow:myWindow];
			for (;;) {
				NSInteger result = [NSApp runModalSession:session];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
				if (result != NSModalResponseContinue){
#else 
                    if (result != NSRunContinuesResponse){
#endif
					break;
				}
			}
			[NSApp endModalSession:session];
			[self setIsModal:NO];
			continueRun = modalResult;
		}
	}	
	return continueRun;
}

- (void) cancelRun
{
	NSLog(@"RunNotes canceling run\n");
	[NSApp stopModalWithCode:0]; //Arg... seems to have no effect
	modalResult = 0;			 //so we have to set this variable
	[self setIsModal:NO];
}

- (void) continueWithRun
{
	[NSApp stopModalWithCode:1]; //Arg... seems to have no effect
	modalResult = 1;			 //so we have to set this variable
	[self setIsModal:NO];
}


- (NSString*) comments
{
	if(!comments)return @"";
	return comments;
}

- (void) setCommentsNoNote:(NSString*)aString
{
	if(!aString)aString= @"";
    [comments autorelease];
    comments = [aString copy];	
}

- (void) setComments:(NSString*)aString
{
	[[[self undoManager] prepareWithInvocationTarget:self] setComments:comments];
    
    [comments autorelease];
    comments = [aString copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesCommentsChanged object: self];
}

- (void) addItem:(id)anItem atIndex:(NSInteger)anIndex
{
	if(!items) items= [[NSMutableArray array] retain];
	if([items count] == 0)anIndex = 0;
	anIndex = MIN(anIndex,(int)[items count]);
	[[[self undoManager] prepareWithInvocationTarget:self] removeItemAtIndex:anIndex];
	[items insertObject:anItem atIndex:anIndex];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesItemsAdded object:self userInfo:userInfo];
}


- (void) removeItemAtIndex:(NSInteger) anIndex
{
	id anItem = [items objectAtIndex:anIndex];
	[[[self undoManager] prepareWithInvocationTarget:self] addItem:anItem atIndex:anIndex];
	[items removeObjectAtIndex:anIndex];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesItemsRemoved object:self userInfo:userInfo];
}

- (id) itemAtIndex:(NSInteger)anIndex
{
	if(anIndex>=0 && anIndex<[items count])return [items objectAtIndex:anIndex];
	else return nil;
}

- (uint32_t) itemCount
{
	return (uint32_t)[items count];
}


- (BOOL) readNamesFromFile;
{
    if(definitionsFilePath){        
        NSString* contents = [NSString stringWithContentsOfFile:definitionsFilePath encoding:NSASCIIStringEncoding error:nil];
        NSArray* lines;
		contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
		contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
        lines = [contents componentsSeparatedByString:@"\n"];
            
        for(id aLine in lines){
			aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
			aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([aLine length] == 0)continue;
            NSArray* parts = [aLine componentsSeparatedByString:@","];
            if([parts count] == 2){
                [self addObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
             }
            else return NO;
        }
    }
    return YES;
}


- (NSString*) commonScriptMethods { return methodsInCommonSection(self); }


#pragma mark Scripting Methods
- (void) commonScriptMethodSectionBegin { }

- (void) change:(id)aKey toValue:(id)aValue
{
	if(!items) items= [[NSMutableArray array] retain];
 	for(id anItem in items){
		if([anItem objectForKey:aKey]){
            [anItem setObject:aValue forKey:aKey];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesItemChanged object:self userInfo:nil];
			return;
		}
	}
    NSLog(@"%@ is not in RunNotes list of items\n",aKey);
}

- (void) addObject:(id)anItem forKey:(id)aKey
{
    [[self undoManager] disableUndoRegistration];
	if(!items) items= [[NSMutableArray array] retain];
    for(id anObj in items){
		if([anObj objectForKey:aKey]!=nil){
			[items removeObject:anObj];
			break;
		}
	}
	id newItem = [NSMutableDictionary dictionaryWithObject:anItem forKey:aKey];
	[items addObject:newItem];
    [[self undoManager] enableUndoRegistration];
}

- (void) removeObjectWithKey:(id)aKey
{
    [[self undoManager] enableUndoRegistration];
	for(id anItem in items){
		if([anItem objectForKey:aKey]){
			[items removeObject:anItem];
			break;
		}
	}
    [[self undoManager] disableUndoRegistration];
}

- (void) commonScriptMethodSectionEnd { }


#pragma mark •••Run Management
//mostly just pass-thrus for the run control commands.
- (void) runTaskStarted:(NSDictionary*)userInfo
{	
	if(!ignoreValues){
		NSMutableDictionary* runNotes = [NSMutableDictionary dictionary];
        if([[self comments] length]){
            [runNotes setObject:[self comments] forKey:@"comments"];
        }
        if([items count]){
            [runNotes setObject:items forKey:@"parameters"];
        }
		if([[runNotes allKeys] count]){
            [[userInfo objectForKey:kHeader] setObject:runNotes forKey:@"RunNotes"];
        }
	}
		
	nextObject =  [self objectConnectedTo: ORRunNotesDataOut]; //cach for a little more efficiency
    [nextObject runTaskStarted:userInfo];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo { [nextObject takeData:aDataPacket userInfo:userInfo]; }
- (void) runIsStopping:(NSDictionary*)userInfo		{ [nextObject runIsStopping:userInfo];  }
- (void) runTaskStopped:(NSDictionary*)userInfo	{ [nextObject runTaskStopped:userInfo]; }
- (void) preCloseOut:(NSDictionary*)userInfo		{ [nextObject preCloseOut:userInfo];    }
- (void) closeOutRun:(NSDictionary*)userInfo		{ [nextObject closeOutRun:userInfo];    }
- (BOOL) doneTakingData					{ return [nextObject doneTakingData];   }
- (void) setRunMode:(int)runMode		{ [[self objectConnectedTo: ORRunNotesDataOut] setRunMode:runMode]; }

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
    [self setDefinitionsFilePath:[decoder decodeObjectForKey:@"definitionsFilePath"]];
	items = [[decoder decodeObjectForKey:@"items"] retain];
	
    [self setDoNotOpen:		[decoder decodeBoolForKey:@"doNotOpen"]];
    [self setIgnoreValues:	[decoder decodeBoolForKey:@"ignoreValues"]];
	[self setComments:		[decoder decodeObjectForKey:@"comments"]];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject:definitionsFilePath forKey:@"definitionsFilePath"];
	[encoder encodeBool:doNotOpen		forKey:@"doNotOpen"];
	[encoder encodeBool:ignoreValues	forKey:@"ignoreValues"];
	[encoder encodeObject:items			forKey:@"items"];
	[encoder encodeObject:comments		forKey:@"comments"];
}

@end



