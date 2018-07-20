//
//  ORHeaderExplorerModel.h
//  Orca
//
//  Created by Mark Howe on Tue Feb 26.
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


#pragma mark •••Imported Files

#pragma mark •••Forward Declarations
@class ORDataPacket;
@class ThreadWorker;
@class ORHeaderItem;
@class ORDataSet;

@interface ORHeaderExplorerModel :  OrcaObject
{
    @private
		BOOL			stop;
        NSMutableArray*	filesToProcess;

        ORHeaderItem*   header;
        NSString*       lastListPath;
        NSString*       lastFilePath;
		NSString*       fileToProcess;
        ORDataPacket*   fileAsDataPacket;

        BOOL			reading;
        uint32_t   currentFileIndex;
		
		NSMutableArray* runArray;
		uint32_t	minRunStartTime;
		uint32_t	maxRunEndTime;
		int32_t			selectionDate;
		int				selectedRunIndex;
		int				selectedFileIndex;

		BOOL			autoProcess;
		NSMutableArray*	searchKeys;
		BOOL			useFilter;
		NSOperationQueue* queue;
		double		   totalToBeProcessed;	
		double		   amountDoneSoFar;
		double			percentComplete;
}

#pragma mark •••Accessors
- (double) percentComplete;
- (BOOL) useFilter;
- (void) setUseFilter:(BOOL)aUseFilter;
- (NSMutableArray*) searchKeys;
- (void) addSearchKeys:(NSMutableArray*)newKeys;
- (void) removeSearchKeys:(NSMutableArray*)anArray;
- (void) removeSearchKeysWithIndexes:(NSIndexSet*)indexSet;
- (void) replace:(NSInteger)index withSearchKey:(NSString*)aKey;
- (void) insert:(NSInteger)index withSearchKey:(NSString*)aKey;
- (BOOL) autoProcess;
- (void) setAutoProcess:(BOOL)aAutoProcess;
- (int) selectedRunIndex;
- (int) selectedFileIndex;
- (void) setSelectedFileIndex:(int)anIndex;
- (void) setSelectedRunIndex:(int)anIndex;
- (int32_t)  selectionDate;
- (void) setSelectionDate:(int32_t)aValue;
- (NSDictionary*) runDictionaryForIndex:(int)index;
- (uint32_t)   total;
- (NSString*)   fileToProcess;
- (void)        setFileToProcess:(NSString*)newFileToProcess;
- (NSArray*) filesToProcess;
- (void) addFilesToProcess:(NSMutableArray*)newFilesToProcess;
- (ORHeaderItem *)header;
- (void)setHeader:(ORHeaderItem *)aHeader;
- (void) loadHeader;
- (NSMutableDictionary*) filteredHeader:(id)aHeader;
- (BOOL)isProcessing;
- (NSString *) lastListPath;
- (void) setLastListPath: (NSString *) aSetLastListPath;
- (NSString *) lastFilePath;
- (void) setLastFilePath: (NSString *) aSetLastListPath;
- (uint32_t)	minRunStartTime;
- (uint32_t)	maxRunEndTime;
- (BOOL) fileHasBeenProcessed:(uint32_t)anIndex;

#pragma mark •••Data Handling
- (void) stopProcessing;
- (void) removeFilesWithIndexes:(NSIndexSet*)indexSet;
- (void) stopProcessing;
- (void) removeAll;
- (void) removeFiles:(NSMutableArray*)anArray;
- (BOOL) readHeaders;
- (void) findSelectedRunByDate;
- (void) selectFirstRunForFileIndex:(int)anIndex;
- (void) assembleDataForPlotting;
- (void) assembleDataForPlotting:(int)keyNumber;
- (void)logHeader:(NSDictionary*)aHeader
		 runStart:(uint32_t)aRunStart 
		   runEnd:(uint32_t)aRunEnd 
		runNumber:(uint32_t)aRunNumber 
		useSubRun:(uint32_t)aUseSubRun
	 subRunNumber:(uint32_t)aSubRunNumber
		 fileSize:(uint32_t)aFileSize
		 fileName:(NSString*)aFilePath;
- (int) indexOfFile:(NSString*)aFilePath;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


#pragma mark •••External String Definitions
extern NSString* ORHeaderExplorerUseFilterChanged;
extern NSString* ORHeaderExplorerAutoProcessChanged;
extern NSString* ORHeaderExplorerListChanged;
extern NSString* ORHeaderExplorerProcessing;
extern NSString* ORHeaderExplorerProcessingFinished;

extern NSString* ORHeaderExplorerProcessingEnded;
extern NSString* ORHeaderExplorerProcessingFile;
extern NSString* ORHeaderExplorerSelectionDate;
extern NSString* ORHeaderExplorerRunSelectionChanged;
extern NSString* ORHeaderExplorerOneFileDone;
extern NSString* ORHeaderExplorerHeaderChanged;

extern NSString* ORHeaderExplorerSearchKeysChanged;
extern NSString* ORHeaderExplorerProgressChanged;
extern NSString* ORHeaderExplorerFileSelectionChanged;

