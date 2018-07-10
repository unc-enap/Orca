//
//  ORHistoModel.h
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
#import "ORDataChainObject.h"
#import "ORDataProcessing.h"

#pragma mark ¥¥¥Forward Declarations
@class ORDataPacket;
@class ORDataSet;
@class OR1DHisto;
@class OR2DHisto;
@class ORDecoder;
@class ORDataPacket;

@interface ORHistoModel :  ORDataChainObject <ORDataProcessing>
{
    @private
        ORDataSet*   dataSet;
        NSString*    directoryName;
        NSString*    fileName;
        BOOL		 writeFile;
		NSLock*		 mLock;
        BOOL         processedFinalCall;
        NSMutableArray* multiPlots;
		BOOL		shipFinalHistograms;
		OR1DHisto*  dummy1DHisto;
		OR2DHisto*  dummy2DHisto;
        BOOL        decodingDisabled;
        BOOL        accumulate;
}


#pragma mark ¥¥¥Initialization
- (void) makeConnectors;

#pragma mark ¥¥¥Accessors
- (BOOL) accumulate;
- (void) setAccumulate:(BOOL)aAccumulate;
- (BOOL) decodingDisabled;
- (void) setDecodingDisabled:(BOOL)aFlag;
- (BOOL)		shipFinalHistograms;
- (void)		setShipFinalHistograms:(BOOL)aShipFinalHistograms;
- (id)			objectForKeyArray:(NSMutableArray*)anArray;
- (ORDataSet*) 	dataSet;
- (void)        setDataSet:(ORDataSet*)aDataSet;
- (void)        setDirectoryName:(NSString*)aFileName;
- (NSString*)	directoryName;
- (void)        setFileName:(NSString*)aFileName;
- (NSString*)	fileName;
- (BOOL)        writeFile;
- (void)        setWriteFile:(BOOL)newWriteFile;
- (NSMutableArray *)    multiPlots;
- (void) setMultiPlots:(NSMutableArray *) aMultiPlots;
- (void) addMultiPlot:(id)aMultiPlot;
- (void) removeMultiPlot:(id)aMultiPlot;
- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector;
- (ORDataSet*) dataSetWithName:(NSString*)aName;

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStarted:(NSDictionary*)userInfo;
- (void) runTaskStopped:(NSDictionary*)userInfo;
- (void) preCloseOut:(NSDictionary*)userInfo;
- (void) closeOutRun:(NSDictionary*)userInfo;
- (void) runTaskBoundary;
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;

- (NSUInteger)  outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(ORDataSet*)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(ORDataSet*)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(NSUInteger)index ofItem:(ORDataSet*)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(ORDataSet*)item;
- (NSUInteger)  numberOfChildren;
- (id)   childAtIndex:(NSUInteger)index;
- (id)   name;
- (void) removeDataSet:(ORDataSet*)aSet;
- (BOOL) leafNode;
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (void) setRunMode:(int)aRunMode;
@end


@interface NSObject (ORHistModel)
- (void) removeFrom:(NSMutableArray*)anArray;
- (void) invalidateDataSource;
@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORHistoModelAccumulateChanged;
extern NSString* ORHistoModelShipFinalHistogramsChanged;
extern NSString* ORHistoModelDirChangedNotification;
extern NSString* ORHistoModelFileChangedNotification;
extern NSString* ORHistoModelWriteFileChangedNotification;
extern NSString* ORHistoModelMultiPlotsChangedNotification;
extern NSString* ORHistoModelDecodingDisabledChanged;

