//
//  ORReplayDataModel.h
//  Orca
//
//  Created by Rielage on Thu Oct 02 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORFileMover.h"
#import "ORDataProcessing.h"

#pragma mark ¥¥¥Forward Declarations
@class ORHeaderItem;
@class ORDataSet;

@interface ORReplayDataModel :  OrcaObject
{
    @private
		NSOperationQueue* queue;
		BOOL			stop;
        NSMutableArray*	filesToReplay;
        id<ORDataProcessing> nextObject;

        ORHeaderItem*   header;
        NSString*       lastListPath;
        NSString*       lastFilePath;
		NSString*       fileToReplay;
        NSArray*        dataRecords;

        double			percentComplete;
		BOOL			sentRunStart;

}

#pragma mark ¥¥¥Accessors
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

#pragma mark ¥¥¥Data Handling
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
- (void) sendDataArray:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
- (void) sendRunStart:(NSDictionary*)userInfo;
- (void) sendRunEnd:(NSDictionary*)userInfo;
- (void) sendCloseOutRun:(NSDictionary*)userInfo;
- (void) sendRunSubRunStart:(NSDictionary*)userInfo;
@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORReplayFileListChangedNotification;
extern NSString* ORReplayRunningNotification;
extern NSString* ORReplayStoppedNotification;

extern NSString* ORRelayFileChangedNotification;
extern NSString* ORReplayProgressChangedNotification;
