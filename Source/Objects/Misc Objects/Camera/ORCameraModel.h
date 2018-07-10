//
//  ORContainerModel.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
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

#import <QTKit/QTKit.h>

@interface ORCameraModel : OrcaObject  
{
	int									updateInterval;
	QTCaptureDevice*					mDevice;
	QTCaptureSession*					captureSession;
    QTCaptureDeviceInput*				captureDeviceInput;
    QTCaptureDecompressedVideoOutput*	captureDecompressedVideoOutput;
	QTCaptureMovieFileOutput*			captureMovieFileOutput;
	NSImage*							lastImage;
	
	QTMovie*							movie;
	NSTimeInterval						lastTime;
    NSString*							historyFolder;
    int									saveFileInterval;
    int									keepFileInterval;
    NSDate*								timeStarted;
    int									deviceIndex;
}

- (void) setUpImage;

#pragma mark ***Accessors
- (int) deviceIndex;
- (void) setDeviceIndex:(int)aDeviceIndex;
- (NSDate*) timeStarted;
- (void) setTimeStarted:(NSDate*)aTimeStarted;
- (int) keepFileInterval;
- (void) setKeepFileInterval:(int)aKeepFileInterval;
- (int) saveFileInterval;
- (void) setSaveFileInterval:(int)aSaveFileInterval;
- (NSString*) historyFolder;
- (void) setHistoryFolder:(NSString*)aHistoryFolder;
- (BOOL) running;
- (void) setMovie:(QTMovie*)aMovie;
- (QTMovie*)movie;
- (unsigned long) calculatedFileSizeBytes;

#pragma mark ***Polling
- (int) updateInterval;
- (void) setUpdateInterval:(int) anInterval;

#pragma mark ***Camera Methods
- (void)			 startSession;
- (void)			 stopSession;
- (NSArray*)		 videoDevices;
- (QTCaptureDevice*) defaultVideoDevice;
- (QTCaptureDevice*) deviceNamed:(NSString *)name;
- (NSImage*)		 lastImage;
- (void)			 addFrameNow;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORCameraModelDeviceIndexChanged;
extern NSString* ORCameraModelTimeStartedChanged;
extern NSString* ORCameraModelKeepFileIntervalChanged;
extern NSString* ORCameraModelSaveFileIntervalChanged;
extern NSString* ORCameraModelHistoryFolderChanged;
extern NSString* ORCameraModelUpdateIntervalChanged;
extern NSString* ORCameraModelCameraChangedNotification;
extern NSString* ORCameraLock;
extern NSString* ORCameraPollRateChanged;
extern NSString* ORCameraModelRunningChanged;
extern NSString* ORCameraModelMovieChanged;

