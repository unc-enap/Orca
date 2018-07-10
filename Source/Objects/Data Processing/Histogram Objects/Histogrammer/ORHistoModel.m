//
//  ORHistoModel.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 24 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORHistoModel.h"
#import "ORDataPacket.h"
#import "ORDataTaker.h"
#import "ORDataSet.h"
#import "OR1DHisto.h"
#import "OR2DHisto.h"
#import "ORDecoder.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORHistoModelAccumulateChanged				= @"ORHistoModelAccumulateChanged";
NSString* ORHistoModelShipFinalHistogramsChanged	= @"ORHistoModelShipFinalHistogramsChanged";
NSString* ORHistoModelChangedNotification			= @"The Histogram Model Object Has Changed";
NSString* ORHistoModelDirChangedNotification		= @"The Histogram Model Dir Changed";
NSString* ORHistoModelFileChangedNotification		= @"The Histogram Model File Has Changed";
NSString* ORHistoModelWriteFileChangedNotification	= @"The Histogram Model WriteFile Has Changed";
NSString* ORHistoModelMultiPlotsChangedNotification = @"ORHistoModelMultiPlotsChangedNotification";
NSString* ORHistoModelDecodingDisabledChanged       = @"ORHistoModelDecodingDisabledChanged";

#pragma mark ¥¥¥Definitions
static NSString *ORHistoDataConnection 		= @"Histogrammer Data Connector";
static NSString *ORHistoPassThruConnection 	= @"Histogrammer PassThru Connector";

@interface ORHistoModel (private)
- (void) shipTheFinalHistograms:(ORDataPacket*)aDataPacket;
@end

@implementation ORHistoModel

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    mLock = [[NSLock alloc] init];
	dataSet = nil;
    [[self undoManager] enableUndoRegistration];
    
    
    return self;
}

- (void) sleep
{
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORHistoDataConnection];
	[aConnector setIoType:kInputConnector];
    [aConnector release];

    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize ,0 ) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORHistoPassThruConnection];
	[aConnector setIoType:kOutputConnector];
    [aConnector release];
    
}

-(void)dealloc
{    
	[dummy1DHisto release];
	[dummy2DHisto release];
    [multiPlots makeObjectsPerformSelector:@selector(invalidateDataSource) withObject:nil];
    [multiPlots release];
    [dataSet release];
    [directoryName release];
    [fileName release];
    [mLock release];
    [super dealloc];
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"Histo"];
    NSSize theIconSize = [aCachedImage size];
    
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeCopy fraction:1.0];
    
    if([self uniqueIdNumber]){
        NSAttributedString* n = [[NSAttributedString alloc] 
                                initWithString:[NSString stringWithFormat:@"%lu",[self uniqueIdNumber]]
                                    attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:12] forKey:NSFontAttributeName]];
        
        [n drawInRect:NSMakeRect(3,[i size].height-17,[i size].width-20,16)];
        [n release];

    }
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORForceRedraw
                      object: self];

}

- (id) findObjectWithFullID:(NSString*)aFullID;
{
    if([aFullID isEqualToString:[self fullID]])return self;
    else {
		return [dataSet findObjectWithFullID:aFullID];
	}
}

- (NSArray*) collectObjectsOfClass:(Class)aClass
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
    @synchronized (self) {
        
        [collection addObjectsFromArray:[super collectObjectsOfClass:aClass]];
        
        NSEnumerator* e  = [dataSet objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject]){
            [collection addObjectsFromArray:[anObject collectObjectsOfClass:aClass]];
        }
    }
    return collection;
}


- (void) makeMainController
{
    [self linkToController:@"ORHistoController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Data_Monitor.html";
}

- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector
{
	
	NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
    [collection addObjectsFromArray:[super collectObjectsRespondingTo:aSelector]];
	
 	if(shipFinalHistograms){
		//argh --- special case -- the final histograms have to be included
		if(!dummy1DHisto)dummy1DHisto = [[OR1DHisto alloc] init];
		if([dummy1DHisto respondsToSelector:aSelector]){
			[collection addObject:dummy1DHisto];
		}
		if(!dummy2DHisto)dummy2DHisto = [[OR2DHisto alloc] init];
		if([dummy2DHisto respondsToSelector:aSelector]){
			[collection addObject:dummy2DHisto];
		}
	} 
    [mLock lock];
    @try {  
        NSArray* theCollection =  [dataSet collectObjectsRespondingTo:aSelector];  
        [collection addObjectsFromArray:theCollection];
    }
    @finally {
         [mLock unlock];
    }
	return collection;
}

- (NSArray*) subObjectsThatMayHaveDialogs
{
	return [dataSet collectionOfDataSets];
}

- (id) objectForKeyArray:(NSMutableArray*)anArray
{
	return [dataSet objectForKeyArray:anArray] ;
}

#pragma mark ¥¥¥Accessors
- (BOOL) decodingDisabled
{
    return decodingDisabled;
}

- (void) setDecodingDisabled:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDecodingDisabled:decodingDisabled];
    
    decodingDisabled = aFlag;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHistoModelDecodingDisabledChanged object:self];
  
}

- (BOOL) accumulate
{
    return accumulate;
}

- (void) setAccumulate:(BOOL)aAccumulate
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAccumulate:accumulate];
    
    accumulate = aAccumulate;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHistoModelAccumulateChanged object:self];
}

- (BOOL) shipFinalHistograms
{
    return shipFinalHistograms;
}

- (void) setShipFinalHistograms:(BOOL)aShipFinalHistograms
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipFinalHistograms:shipFinalHistograms];
    
    shipFinalHistograms = aShipFinalHistograms;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHistoModelShipFinalHistogramsChanged object:self];
}

- (ORDataSet*) dataSet
{
    ORDataSet* temp = nil;    
    [mLock lock];
    @try {
        temp = [[dataSet retain] autorelease];
    }
    @finally {
         [mLock unlock];
    }
    return temp;
}

- (void) setDataSet:(ORDataSet*)aDataSet
{
    [mLock lock];
    [aDataSet retain];
    [dataSet release];
    dataSet = aDataSet;
    [mLock unlock];
    
    [dataSet registerForWatchers];
    
    [multiPlots makeObjectsPerformSelector:@selector(setDataSource:) withObject:dataSet];
    
}

- (ORDataSet*) dataSetWithName:(NSString*)aName
{
    ORDataSet* theSet = nil;
    [mLock lock];
    @try {
        theSet =  [[[dataSet dataSetWithName:aName]retain] autorelease];
    }
    @finally {
         [mLock unlock];
    }
	return theSet;
}

- (void) setDirectoryName:(NSString*)aDirName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDirectoryName:[self directoryName]];
    
    
    [directoryName autorelease];
    directoryName = [aDirName copy];
    
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORHistoModelDirChangedNotification
                              object: self ];
    
}

- (NSString*)directoryName
{
    return directoryName;
}

- (void) setFileName:(NSString*)aFileName
{
    
    [fileName autorelease];
    fileName = [aFileName copy];
    
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORHistoModelFileChangedNotification
                              object: self ];
}

- (NSString*)fileName
{
    return fileName;
}

- (BOOL) writeFile
{
    return writeFile;
}

- (void) setWriteFile:(BOOL)newWriteFile
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteFile:[self writeFile]];
    
    writeFile=newWriteFile;
    
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORHistoModelWriteFileChangedNotification
                              object: self ];
    
}

- (NSMutableArray *) multiPlots
{
    return multiPlots; 
}

- (void) setMultiPlots: (NSMutableArray *) aMultiPlots
{
    [aMultiPlots retain];
    [multiPlots release];
    multiPlots = aMultiPlots;
}

- (void) addMultiPlot:(id)aMultiPlot
{
    if(!multiPlots){
        [self setMultiPlots:[NSMutableArray array]];
    }
    
    [[[self undoManager] prepareWithInvocationTarget:self] removeMultiPlot:aMultiPlot];
    
    [multiPlots addObject:aMultiPlot];
    
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORHistoModelMultiPlotsChangedNotification
                              object: self ];
}

- (void) removeMultiPlot:(id)aMultiPlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] addMultiPlot:aMultiPlot];
    
    [aMultiPlot removeFrom:multiPlots];
    
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORHistoModelMultiPlotsChangedNotification
                              object: self ];
}

- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder
{
    if(!decodingDisabled){
         if(!dataSet){
            [self setDataSet:[[[ORDataSet alloc]initWithKey:@"System" guardian:nil] autorelease] ];
        }
            
        [mLock lock];
        @try {
            //process the data
            for(id someData in dataArray){
                [aDecoder decode:someData intoDataSet:dataSet];
            }
        }
        @finally {
             [mLock unlock];
        }
    }
    
	//pass it on
	id theNextObject = [self objectConnectedTo:ORHistoPassThruConnection];
	[theNextObject processData:dataArray decoder:aDecoder];
}

- (void) setRunMode:(int)aRunMode;
{
}

- (BOOL) leafNode
{
	return NO;
}

#pragma mark ¥¥¥Run Management

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [dataSet appendDataDescription:aDataPacket userInfo:userInfo];
}

- (void) runTaskStarted:(NSDictionary*)userInfo
{

	processedFinalCall = NO;
    if(!dataSet){
        [self setDataSet:[[[ORDataSet alloc]initWithKey:@"System" guardian:nil] autorelease] ];
    }
	  
	long runNumber = -1;
	if(userInfo){
		runNumber = [[userInfo objectForKey:kRunNumber] intValue];
	}
	else {
		id header = [userInfo objectForKey:kHeader];
		NSArray* dataChainObjects = [header objectForNestedKey:@"ObjectInfo,DataChain"];
		NSDictionary* runControlEntry = [(NSDictionary*)[dataChainObjects objectAtIndex:0] objectForKey:@"Run Control"];
		runNumber = [[runControlEntry objectForKey:@"RunNumber"] longValue];
	}	  
	[dataSet setRunNumber:runNumber];
	
	if(!accumulate){
		[dataSet clear];
	}
	
 	id nextObject =  [self objectConnectedTo: ORHistoPassThruConnection];
	[nextObject runTaskStarted:userInfo];
	[nextObject setInvolvedInCurrentRun:YES];
	
}

- (void) subRunTaskStarted:(NSDictionary*)userInfo
{
	//we don't care
}

- (void) runTaskStopped:(NSDictionary*)userInfo
{
  	id nextObject =  [self objectConnectedTo: ORHistoPassThruConnection];
	[nextObject runTaskStopped:userInfo];
	[nextObject setInvolvedInCurrentRun:NO];
	[dataSet runTaskStopped];
}

- (void) endOfRunCleanup:(NSDictionary*)userInfo
{
 	if(shipFinalHistograms){
		ORDataPacket* aDataPacket = [userInfo objectForKey:kDataPacket];
		[self shipTheFinalHistograms:aDataPacket];
	}
}

- (void) runTaskBoundary
{
   [dataSet runTaskBoundary];
}

- (void) preCloseOut:(NSDictionary*)userInfo
{
}

- (void) closeOutRun:(NSDictionary*)userInfo
{

	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORHistoModelChangedNotification
                              object: self ];
    
    BOOL runMode = [[userInfo objectForKey:kRunMode] boolValue];
    if([self writeFile] && (runMode == kNormalRun)){
        int runNumber = [[userInfo objectForKey:kRunNumber] intValue];
        int subRunNumber = [[userInfo objectForKey:kSubRunNumber] intValue];
		NSString* runNumberString = [NSString stringWithFormat:@"HistogramsRun%d",runNumber];
		if(subRunNumber!=0){
			runNumberString = [runNumberString stringByAppendingFormat:@".%d",subRunNumber];
		}

        [self setFileName:runNumberString];
        NSString* fullFileName = [[directoryName stringByExpandingTildeInPath] stringByAppendingPathComponent:fileName];
        FILE* aFile = fopen([fullFileName cStringUsingEncoding:NSASCIIStringEncoding],"w"); 
        if(aFile){
            NSLog(@"Writing Histogram File: %@\n",fullFileName);
            fprintf(aFile,"IGOR\n");
            [dataSet writeDataToFile:aFile];
            fclose(aFile);
            NSFileManager* fileManager = [NSFileManager defaultManager];
            NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
            [attributes setObject:[NSNumber numberWithUnsignedLong:'IGTX'] forKey:NSFileHFSTypeCode];
            [attributes setObject:[NSNumber numberWithUnsignedLong:'IGR0'] forKey:NSFileHFSCreatorCode];
			[fileManager setAttributes:attributes ofItemAtPath:fullFileName error:nil];
       }
    }
    
	processedFinalCall = YES;
    [[self objectConnectedTo:ORHistoPassThruConnection] closeOutRun:userInfo];

}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(ORDataSet*)item
{
    return (item == nil) ? 1  : [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(ORDataSet*)item
{
    return    (item == nil) ? [self numberOfChildren]!=0 : ([item numberOfChildren] != 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSUInteger)index ofItem:(ORDataSet*)item
{
    if(item)   return [item childAtIndex:index];
    else	return dataSet;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(ORDataSet*)item
{
    return  ((item == nil) ? @"System" : [item name]);
}

- (NSUInteger)  numberOfChildren
{
    int count =  [dataSet count];
    return count;
}

- (id)   childAtIndex:(NSUInteger)index
{
    id child = nil;
    [mLock lock];
    @try {
        NSEnumerator* e = [dataSet objectEnumerator];
        id obj;
        short i = 0;
        while(obj = [e nextObject]){
            if(i++ == index){
                child = [[obj retain] autorelease];
                break;
            }
        }
     }
    @finally {
         [mLock unlock];
    }
   return child;
}


- (id)   name
{
    return @"System";
}

- (void) removeDataSet:(ORDataSet*)item
{
    if([[item name] isEqualToString: [self name]]) {
        [self setDataSet:nil];
    }
    else { 
        [mLock lock];
        @try {
            [dataSet removeObject:item];
        }
        @finally {
             [mLock unlock];
        }
	}
}


#pragma mark ¥¥¥Archival
static NSString *ORHistoDirName 				= @"Histo file dir name";
static NSString *ORHistoWriteFile 				= @"Histo file write file";
static NSString *ORHistoDataSet 				= @"Histo file data Set";
static NSString *ORHistoMultiPlots 				= @"Histo Multiplot Set";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	mLock = [[NSLock alloc] init];
    
    [[self undoManager] disableUndoRegistration];
    [self setAccumulate:[decoder decodeBoolForKey:@"accumulate"]];
    [self setDecodingDisabled:[decoder decodeBoolForKey:@"decodingDisabled"]];
    [self setShipFinalHistograms:[decoder decodeBoolForKey:@"shipFinalHistograms"]];
    [self setDirectoryName:[decoder decodeObjectForKey:ORHistoDirName]];
    [self setWriteFile:[decoder decodeIntForKey:ORHistoWriteFile]];
    [self setDataSet:[decoder decodeObjectForKey:ORHistoDataSet]];
    [self setMultiPlots:[decoder decodeObjectForKey:ORHistoMultiPlots]];
    [[self undoManager] enableUndoRegistration];
    
    [multiPlots makeObjectsPerformSelector:@selector(setDataSource:) withObject:dataSet];
        
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:decodingDisabled forKey:@"decodingDisabled"];
    [encoder encodeBool:accumulate forKey:@"accumulate"];
    [encoder encodeBool:shipFinalHistograms forKey:@"shipFinalHistograms"];
    [encoder encodeObject:[self directoryName] forKey:ORHistoDirName];
    [encoder encodeInt:[self writeFile] forKey:ORHistoWriteFile];
    [encoder encodeObject:dataSet forKey:ORHistoDataSet];
    [encoder encodeObject:[self multiPlots] forKey:ORHistoMultiPlots];
}

@end

@implementation ORHistoModel (private)
- (void) shipTheFinalHistograms:(ORDataPacket*)aDataPacket
{
	NSArray* objs1d = [[self document]  collectObjectsOfClass:[OR1DHisto class]];
	for(id anObj in objs1d)[anObj setDataId:[dummy1DHisto dataId]];
	
	NSArray* objs2d = [[self document]  collectObjectsOfClass:[OR2DHisto class]];
	for(id anObj in objs2d)[anObj setDataId:[dummy2DHisto dataId]];
    [mLock lock];
    @try {
        [dataSet packageData:aDataPacket userInfo:nil];
    }
    @finally {
         [mLock unlock];
    }
}
@end

