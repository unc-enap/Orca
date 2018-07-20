//
//  ORDataFileModel.h
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
#import "ORAdcProcessing.h"

#pragma mark ¥¥¥Forward Declarations
@class ORQueue;
@class ORSmartFolder;
@class ORAlarm;
@class ORDecoder;

#define kStopOnLimit	0
#define kRestartOnLimit 1
#define kMinDiskSpace   2 //GBytes
#define kScaryDiskSpace 50 //GBytes

@interface ORDataFileModel :  ORDataChainObject <ORDataProcessing,ORAdcProcessing>
{
    @private
        NSFileHandle*	filePointer;
        uint64_t	dataFileSize;
        NSString*		fileName;

        NSUInteger	    statusStart;
        BOOL			saveConfiguration;
        BOOL			ignoreMode;
        BOOL			processedRunStart;
        BOOL			processedCloseRun;

        ORSmartFolder*	dataFolder;
        ORSmartFolder*	statusFolder;
        ORSmartFolder*	configFolder;
        
        NSMutableData*	dataBuffer;
        NSTimeInterval	lastTime;
		BOOL			limitSize;
		float			maxFileSize;
		int				fileSegment;
		BOOL			fileLimitExceeded;
		NSString*		filePrefix;
        NSString*		fileStaticSuffix;
		BOOL			useFolderStructure;
		BOOL			useDatedFileNames;
		int				sizeLimitReachedAction;
        ORAlarm*		diskFullAlarm;
        ORAlarm*		diskFillingAlarm;
		int				checkCount;
		int				runMode;
		NSTimeInterval	lastFileCheckTime;
		NSString*		openFilePath;
		BOOL			savedFirstTime; //use to force a config save
		BOOL			processCheckedOnce;
		float			percentFull;
		float			processLimitHigh;
        BOOL            generateMD5;
        NSOperationQueue* md5Queue;
        NSDate*         startTime;
}

#pragma mark ¥¥¥Accessors
- (BOOL) generateMD5;
- (void) setGenerateMD5:(BOOL)aGenerateMD5;
- (float) processLimitHigh;
- (void) setProcessLimitHigh:(float)aProcessLimitHigh;
- (BOOL) useDatedFileNames;
- (void) setUseDatedFileNames:(BOOL)aUseDatedFileNames;
- (BOOL) useFolderStructure;
- (void) setUseFolderStructure:(BOOL)aUseFolderStructure;
- (NSString*) filePrefix;
- (void) setFilePrefix:(NSString*)aFilePrefix;
- (NSString*) fileStaticSuffix;
- (void) setFileStaticSuffix:(NSString*)aFileSuffix;
- (int) fileSegment;
- (void) setFileSegment:(int)aFileSegment;
- (float) maxFileSize;
- (void) setMaxFileSize:(float)aMaxFileSize;
- (BOOL) limitSize;
- (void) setLimitSize:(BOOL)aLimitSize;
- (ORSmartFolder *)dataFolder;
- (void)setDataFolder:(ORSmartFolder *)aDataFolder;
- (ORSmartFolder *)statusFolder;
- (void)setStatusFolder:(ORSmartFolder *)aStatusFolder;
- (ORSmartFolder *)configFolder;
- (void)setConfigFolder:(ORSmartFolder *)aConfigFolder;
- (int)sizeLimitReachedAction;
- (void) setSizeLimitReachedAction:(int)aValue;
- (void) setFileName:(NSString*)aFileName;
- (NSString*)fileName;
- (NSFileHandle *)filePointer;
- (void)setFilePointer:(NSFileHandle *)aFilePointer;
- (void)setTitles;
- (uint64_t)dataFileSize;
- (void) setDataFileSize:(uint64_t)aSize;
- (void) getDataFileSize;
- (void) checkDiskStatus;

- (BOOL)saveConfiguration;
- (void)setSaveConfiguration:(BOOL)flag;
- (NSString*) tempDir;
- (void) sendFile:(NSString*)fullFileName;
- (void) sendFiles:(NSArray*)filesToSend;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) runAboutToStart:(NSNotification*)aNotification;
- (void) setRunMode:(int)aMode;
- (void) statusLogFlushed:(NSNotification*)aNotification;
- (void) preCloseOut:(NSDictionary*)userInfo;
- (void) closeOutLogFiles:(NSNotification*)aNote;

#pragma mark ¥¥¥Data Handling
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
- (void) runTaskStarted:(NSDictionary*)userInfo;
- (void) runTaskStopped:(NSDictionary*)userInfo;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ¥¥¥Adc Processing Protocol
- (void)processIsStarting;
- (void)processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel;
- (double) convertedValue:(int)channel;
- (double) maxValueForChan:(int)channel;
@end


#pragma mark ¥¥¥External String Definitions
extern NSString* ORDataFileModelGenerateMD5Changed;
extern NSString* ORDataFileModelProcessLimitHighChanged;
extern NSString* ORDataFileModelUseDatedFileNamesChanged;
extern NSString* ORDataFileModelUseFolderStructureChanged;
extern NSString* ORDataFileModelFilePrefixChanged;
extern NSString* ORDataFileModelFileSegmentChanged;
extern NSString* ORDataFileModelMaxFileSizeChanged;
extern NSString* ORDataFileModelLimitSizeChanged;
extern NSString* ORDataFileChangedNotification;
extern NSString* ORDataFileStatusChangedNotification;
extern NSString* ORDataFileSizeChangedNotification;
extern NSString* ORDataFileLock;
extern NSString* ORDataSaveConfigurationChangedNotification;
extern NSString* ORDataFileModelSizeLimitReachedActionChanged;


@interface ORMD5Op : NSOperation
{
	id delegate;
    NSString* filePath;
}
- (id) initWithFilePath:(NSString*)aPath delegate:(id)aDelegate;
- (void) main;
@end
