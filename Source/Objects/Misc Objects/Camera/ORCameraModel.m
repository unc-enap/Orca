//
//  ORCameraModel.m
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


#pragma mark •••Imported Files
#import "ORCameraModel.h"
#import "NSNotifications+Extensions.h"

NSString* ORCameraModelDeviceIndexChanged = @"ORCameraModelDeviceIndexChanged";
NSString* ORCameraModelTimeStartedChanged = @"ORCameraModelTimeStartedChanged";
NSString* ORCameraModelKeepFileIntervalChanged = @"ORCameraModelKeepFileIntervalChanged";
NSString* ORCameraModelSaveFileIntervalChanged = @"ORCameraModelSaveFileIntervalChanged";
NSString* ORCameraModelHistoryFolderChanged = @"ORCameraModelHistoryFolderChanged";
NSString* ORCameraLock							= @"ORCameraLock";
NSString* ORCameraModelUpdateIntervalChanged	= @"ORCameraModelUpdateIntervalChanged";
NSString* ORCameraModelRunningChanged			= @"ORCameraModelRunningChanged";
NSString* ORCameraModelMovieChanged				= @"ORCameraModelMovieChanged";

@interface ORCameraModel (private)
- (BOOL) startDevice:(QTCaptureDevice*) device;
- (void) captureOutput:(QTCaptureOutput *)captureOutput 
   didOutputVideoFrame:(CVImageBufferRef)videoFrame 
	  withSampleBuffer:(QTSampleBuffer *)sampleBuffer 
		fromConnection:(QTCaptureConnection *)connection;
- (uint32_t) saveIntervalInSeconds;
- (int32_t) keepFileIntervalInSeconds;
- (int) updateIntervalSeconds;
- (void) saveMovieToHistory;
- (void) cleanupHistory;
- (void) cleanupThread:(int32_t)keepTime;
- (void) addFrame;
@end


@implementation ORCameraModel

#pragma mark •••initialization
- (id) init
{
    self = [super init];
    return self;
}

-(void) dealloc
{
	[self stopSession];                     // Stop session
    [timeStarted release];
    [historyFolder release];
	[captureDecompressedVideoOutput setDelegate:nil];
	[captureSession release];
	[captureDeviceInput release];
	[captureDecompressedVideoOutput release];
	[mDevice release];
	[movie release];
    [super dealloc];
}

- (void) sleep
{
	[self stopSession];
	[super sleep];
}

- (BOOL) solitaryObject
{
    return YES;
}

- (void) awakeAfterDocumentLoaded
{
	
}

- (NSString*) helpURL
{
	return @"USB/Camera.html";
}

- (void) makeMainController
{
    [self linkToController:@"ORCameraController"];
}


#pragma mark ***Accessors

- (int) deviceIndex
{
    return deviceIndex;
}

- (void) setDeviceIndex:(int)aDeviceIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDeviceIndex:deviceIndex];
    
    deviceIndex = aDeviceIndex;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCameraModelDeviceIndexChanged object:self];
}

- (NSDate*) timeStarted
{
    return timeStarted;
}

- (void) setTimeStarted:(NSDate*)aTimeStarted
{
    [aTimeStarted retain];
    [timeStarted release];
    timeStarted = aTimeStarted;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCameraModelTimeStartedChanged object:self];
}

- (int) keepFileInterval
{
    return keepFileInterval;
}

- (void) setKeepFileInterval:(int)aKeepFileInterval
{
    [[[self undoManager] prepareWithInvocationTarget:self] setKeepFileInterval:keepFileInterval];
    
    keepFileInterval = aKeepFileInterval;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCameraModelKeepFileIntervalChanged object:self];
}

- (int) saveFileInterval
{
    return saveFileInterval;
}

- (void) setSaveFileInterval:(int)aSaveFileInterval
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSaveFileInterval:saveFileInterval];
    
    saveFileInterval = aSaveFileInterval;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCameraModelSaveFileIntervalChanged object:self];
}

- (NSString*) historyFolder
{
	if(historyFolder)return historyFolder;
	else return [@"~" stringByExpandingTildeInPath];
}

- (void) setHistoryFolder:(NSString*)aHistoryFolder
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistoryFolder:historyFolder];
    
    [historyFolder autorelease];
    historyFolder = [aHistoryFolder copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCameraModelHistoryFolderChanged object:self];
}

- (BOOL) running
{
	return [captureSession isRunning];
}

- (int) updateInterval
{
	return updateInterval;
}

- (void) setUpdateInterval:(int) anInterval
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUpdateInterval:updateInterval];
	updateInterval = anInterval;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCameraModelUpdateIntervalChanged object:self];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"Camera"]];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setDeviceIndex:[decoder decodeIntForKey:@"deviceIndex"]];
    [self setKeepFileInterval:[decoder decodeIntForKey:@"keepFileInterval"]];
    [self setSaveFileInterval:[decoder decodeIntForKey:@"saveFileInterval"]];
    [self setHistoryFolder:		[decoder decodeObjectForKey:@"historyFolder"]];
    [self setUpdateInterval:	[decoder decodeIntForKey:	@"updateInterval"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
  	[encoder encodeInt:deviceIndex forKey:@"deviceIndex"];
  	[encoder encodeInt:keepFileInterval forKey:@"keepFileInterval"];
  	[encoder encodeInt:saveFileInterval forKey:@"saveFileInterval"];
  	[encoder encodeObject:historyFolder		forKey:@"historyFolder"];
  	[encoder encodeInt:updateInterval		forKey:@"updateInterval"];
}

#pragma mark ***Camera Methods

- (void) startSession
{
	if(!captureSession){
		captureDeviceInput				= nil;
		captureDecompressedVideoOutput = nil;
		
		NSArray *devices = [self videoDevices];
		[devices count] > 0 ?
		NSLog(@"Video Devices:\n") :
		NSLog(@"No video devices found.\n");
		
		for( QTCaptureDevice *device in devices ){
			NSLog(@"%@\n", [device description] );
		}
		NSLog(@"Default Device: %@\n", [self defaultVideoDevice]);
		if([self deviceIndex] < [devices count]){
			mDevice = [[devices objectAtIndex:[self deviceIndex]] retain];
		}
		if(!mDevice) mDevice = [[self defaultVideoDevice] retain];
		
		QTMovie* aMovie = [[QTMovie alloc] initToWritableData:[NSMutableData data] error:nil];
		[self setMovie:aMovie];
		[aMovie release];

		[self startDevice:mDevice];
		[self setTimeStarted:[NSDate date]];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCameraModelRunningChanged object:self];
	}
}

- (void) stopSession
{
	while( captureSession != nil ){
					
		[captureSession stopRunning];
		
		if( [captureSession isRunning] ){
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: 0.1]];
		}
		else {
			[captureSession release];
			[captureDeviceInput release];
			[captureDecompressedVideoOutput release];
			
			captureSession = nil;
			captureDeviceInput = nil;
			captureDecompressedVideoOutput = nil;
		} 
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCameraModelRunningChanged object:self];
		
		[self saveMovieToHistory];
		[self cleanupHistory];
		[self setMovie:nil];
	}
}

- (void) setMovie:(QTMovie*)aMovie
{
	@synchronized(self){
		[aMovie retain];
		[movie release];
		movie = aMovie;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCameraModelMovieChanged object:self];
}

- (QTMovie*)movie
{
	QTMovie* aMovie;
	@synchronized(self){
		aMovie = [movie retain];
	}
	return [aMovie autorelease];
}

- (NSImage*) lastImage
{
	NSImage* anImage;
	@synchronized(self){
		anImage = [lastImage retain];
	}
	return [anImage autorelease];
	
}

- (NSArray*) videoDevices
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:3];
    [results addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]];
    [results addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
    return results;
}

- (QTCaptureDevice*)defaultVideoDevice
{
	QTCaptureDevice* device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
	if( device == nil ){
        device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeMuxed];
	}
    return device;
}

- (QTCaptureDevice*) deviceNamed:(NSString *)name
{    
    NSArray *devices = [self videoDevices];
	for( QTCaptureDevice *device in devices ){
        if ( [name isEqualToString:[device description]] )return device;
    }
    return nil;
}

- (uint32_t) calculatedFileSizeBytes
{
	float freq;
	if([self updateIntervalSeconds]) freq = 1/(float)[self updateIntervalSeconds];
	else freq = 1;
	return 18000 * freq * [self saveIntervalInSeconds];
}

- (void) addFrameNow
{
    @synchronized(self){
		[self addFrame];
	}
}
@end

@implementation ORCameraModel (private)
- (uint32_t) saveIntervalInSeconds
{
	switch(saveFileInterval){
		case 0: return 30 * 60;
		case 1: return 60 * 60;
		case 2: return 24 * 60 * 60;
	}
	return 30*60;
}

- (int32_t) keepFileIntervalInSeconds
{
	switch(keepFileInterval){
		case 0: return -1; //forever
		case 1: return 7 * 24 * 60 * 60;
		case 2: return 14 * 24 * 60 * 60;
		case 3: return 30 * 24 * 60 * 60;
		default: return -1;
	}
	return -1;
}
- (int) updateIntervalSeconds
{
	switch(updateInterval){
		case 0: return 1;
		case 1: return 5;
		case 2: return 10;
		case 3: return 30;
		case 4: return 60;
		case 5: return 5*60;
		case 6: return 10*60;
		case 7: return 30*60;
		default: return 1;
	}
	return 1;
}

- (void) addFrame
{
	if (lastImage) {
		
		NSImage* newFrame = [lastImage copy]; 
		[newFrame setSize:NSMakeSize(320,240)];
		[newFrame lockFocus];
		
		NSFont* theFont = [NSFont fontWithName:@"Geneva" size:14];
		NSDictionary* theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor whiteColor],NSForegroundColorAttributeName,[NSColor blackColor],NSBackgroundColorAttributeName,nil];
		NSAttributedString* s = [[NSAttributedString alloc] 
								 initWithString:[NSString stringWithFormat:@"%@",[NSDate date]] 
								 attributes:theAttributes];
		[s drawAtPoint:NSMakePoint(0,0)];
		[s release];
		[newFrame unlockFocus];
		@try {
			[movie addImage:newFrame 
				forDuration:QTMakeTime(1, 10) 
			 withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:@"jpeg", QTAddImageCodecType, [NSNumber numberWithInt:codecNormalQuality],QTAddImageCodecQuality,nil]];
		}
		@catch (NSException* e) {
		}
		[newFrame release];
		//[movie setCurrentTime:[movie duration]];
		
		NSDate* now = [NSDate date];
		if([now timeIntervalSinceDate:timeStarted] >= [self saveIntervalInSeconds]){
			[self saveMovieToHistory];
			QTMovie* aMovie = [[QTMovie alloc] initToWritableData:[NSMutableData data] error:nil];
			[self setMovie:aMovie];
			[aMovie release];
			[self cleanupHistory];
		}
	}
}
	
- (BOOL) startDevice:(QTCaptureDevice*) device
{
    if(!device) return NO;
    
    NSError *error = nil;
    
    // If we've already started with this device, return
    if( [device isEqual:[captureDeviceInput device]] &&
	   captureSession != nil &&
	   [captureSession isRunning] ){
        return YES;
    }
    else if( captureSession != nil ){
        [self stopSession];
    } 
    
	// Create the capture session
    captureSession = [[QTCaptureSession alloc] init];
	if( ![device open:&error] ){
		NSLog(@"Could not create capture session.\n" );
        [captureSession release];
        captureSession = nil;
		return NO;
	}
	
	// Create input object from the device
	captureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
	if (![captureSession addInput:captureDeviceInput error:&error]) {
		NSLog(@"Could not convert device to input device.\n");
        [captureSession release];
        [captureDeviceInput release];
        captureSession = nil;
        captureDeviceInput = nil;
		return NO;
	}
	
	// Decompressed video output
	captureDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
	[captureDecompressedVideoOutput setDelegate:self];
	if (![captureSession addOutput:captureDecompressedVideoOutput error:&error]) {
		NSLog(@"Could not create decompressed output.\n");
        [captureSession release];
        [captureDeviceInput release];
        [captureDecompressedVideoOutput release];
        captureSession = nil;
        captureDeviceInput = nil;
        captureDecompressedVideoOutput = nil;
		return NO;
	}
	
	 
	//movie capture setup
	captureMovieFileOutput = [[QTCaptureMovieFileOutput alloc] init];
    BOOL success = [captureSession addOutput:captureMovieFileOutput error:&error];
    if (!success) {
    }
	[captureMovieFileOutput setDelegate:self];
	
	NSEnumerator *connectionEnumerator = [[captureMovieFileOutput connections] objectEnumerator];
	QTCaptureConnection *connection;
	
	while ((connection = [connectionEnumerator nextObject])) {
		NSString *mediaType = [connection mediaType];
		QTCompressionOptions *compressionOptions = nil;
		if ([mediaType isEqualToString:QTMediaTypeVideo]) {
			compressionOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptions120SizeH264Video"];
		} 
		
		[captureMovieFileOutput setCompressionOptions:compressionOptions forConnection:connection];
	}
	//end movie capture setup
	
	//[captureDecompressedVideoOutput setMinimumVideoFrameInterval:1];
	
	[captureSession startRunning];
	
	
    return YES;
}  

// This delegate method is called whenever the QTCaptureDecompressedVideoOutput receives a frame
- (void) captureOutput: (QTCaptureOutput*)	captureOutput 
   didOutputVideoFrame: (CVImageBufferRef)	videoFrame 
	  withSampleBuffer: (QTSampleBuffer*)	sampleBuffer 
		fromConnection: (QTCaptureConnection*)connection
{
    if(videoFrame == nil) return;	
	CVImageBufferRef imageBuffer;

    @synchronized(self){	
        imageBuffer = CVBufferRetain(videoFrame);

		NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:imageBuffer]];
		NSImage *anImage = [[NSImage alloc] initWithSize:[imageRep size]];
		[anImage addRepresentation:imageRep];
		
		CVBufferRelease(videoFrame);

		[lastImage release];
		lastImage = anImage;
		
		
		if(!lastTime){
			lastTime = [NSDate timeIntervalSinceReferenceDate];
			[self performSelectorOnMainThread:@selector(addFrame) withObject:nil waitUntilDone:NO];
		}
		else {
			NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
			if(now - lastTime >= [self updateIntervalSeconds]){
				lastTime = now;
				[self performSelectorOnMainThread:@selector(addFrame) withObject:nil waitUntilDone:NO];
			}
		}
		
	}
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:@"CameraImageChanged" object:self userInfo:nil waitUntilDone:YES];
}

- (void) saveMovieToHistory
{		
	NSDate* now = [NSDate date];

	NSString* fileName = [now descriptionFromTemplate:@"Y_M_d_H_m_s.mov"];
	NSString* path = [historyFolder stringByAppendingPathComponent:fileName];
	[movie writeToFile: [path stringByExpandingTildeInPath]
		withAttributes: [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:QTMovieFlatten] 
				 error: nil];
}

- (void) cleanupHistory
{
	if([self keepFileIntervalInSeconds]>0){
		[NSThread detachNewThreadSelector:@selector(cleanupThread:) toTarget:self withObject:[NSNumber numberWithLong:[self keepFileIntervalInSeconds]]];
	}
}

- (void) cleanupThread:(int32_t)keepTime
{
	NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
		if( keepTime > 0){
			NSString* theFolder = [[self historyFolder] retain];
			NSFileManager* fm = [NSFileManager defaultManager];
			NSDirectoryEnumerator *enumerator  = [[NSFileManager defaultManager] enumeratorAtPath:  [theFolder stringByExpandingTildeInPath]];
			id aFilePath;
			NSMutableArray* filesToRemove = [NSMutableArray array];
			NSDate* now = [NSDate date];
			while ((aFilePath = [enumerator nextObject])) {
				if([aFilePath hasPrefix:@"20"] && [[aFilePath pathExtension] isEqualToString:@"mov"]){
					NSString* fullPath = [[theFolder stringByAppendingPathComponent:aFilePath] stringByExpandingTildeInPath];
					NSDictionary* attributes = [fm attributesOfItemAtPath:fullPath error:nil];
					NSDate* creationDate = [attributes objectForKey: NSFileCreationDate];
					if(creationDate && [now timeIntervalSinceDate: creationDate] >= keepTime){
						[filesToRemove addObject:fullPath];
					}
				}
			}
			[theFolder release];
			
			for(id aPath in filesToRemove){
				[fm removeItemAtPath:aPath error:nil];
			}
		}
	}
	@catch(NSException* e){
	}
	[thePool release];
}

@end
