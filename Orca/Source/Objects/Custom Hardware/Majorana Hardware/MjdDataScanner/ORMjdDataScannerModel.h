//
//  ORMjdDataScannerModel.h
//
//  Created by Mark Howe on 08/4/2015.
//  Copyright 2015 University of North Carolina. All rights reserved.
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORFileMover.h"
#import "ORDataProcessing.h"

#pragma mark •••Forward Declarations
@class ORHeaderItem;
@class ORDataSet;

@interface ORMjdDataScannerModel :  OrcaObject
{
    @private
		NSOperationQueue* queue;
		BOOL			stop;
        NSMutableArray*	filesToReplay;

        ORHeaderItem*   header;
        NSString*       lastListPath;
        NSString*       lastFilePath;
		NSString*       fileToReplay;
        NSArray*        dataRecords;

        double			percentComplete;
		BOOL			sentRunStart;

}

#pragma mark •••Accessors
- (double)		percentComplete;
- (NSString*)   fileToReplay;
- (void)        setFileToReplay:(NSString*)newFileToReplay;
- (NSArray*)	filesToReplay;
- (void)		addFilesToReplay:(NSMutableArray*)newFilesToReplay;
- (ORHeaderItem *)header;
- (void)		setHeader:(ORHeaderItem *)aHeader;
- (BOOL)		isReplaying;
- (NSString *)	lastListPath;
- (void)		setLastListPath: (NSString *) aSetLastListPath;
- (NSString *)	lastFilePath;
- (void)		setLastFilePath: (NSString *) aSetLastListPath;

#pragma mark •••Data Handling
- (void) checkStatus;
- (void) updateProgress:(NSNumber*)amountDone;
- (BOOL) cancelAndStop;
- (void) stopReplay;
- (void) readHeaderForFileIndex:(int)index;
- (void) removeFilesWithIndexes:(NSIndexSet*)indexSet;
- (void) stopReplay;
- (void) removeAll;
- (void) removeFiles:(NSMutableArray*)anArray;
- (void) replayFiles;
@end

#pragma mark •••External String Definitions
extern NSString* ORMjdDataScannerFileListChanged;
extern NSString* ORMjdDataScannerRunningNotification;
extern NSString* ORMjdDataScannerStoppedNotification;

extern NSString* ORMjdDataScannerFileChangedNotification;
extern NSString* ORMjdDataScannerProgressChangedNotification;
