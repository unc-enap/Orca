//
//  ORGpibEnet.h
//  Orca
//
//  Created by Jan Wouters on Sat Feb 15 2003.
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


#define kMaxGpibAddresses 	31
#define kNumBoards 2
#define kNotInitialized		-1
#define kDefaultGpibPort 0


#pragma mark ***Errors
#define OExceptionGpibError	@"GPIBError"

#import "EduWashingtonNplOrcaNi488PlugIn.h"

#pragma mark ***Class Definition
@interface ORGpibEnetModel : OrcaObject {
    short                       mBoardIndex;
    short                       mDeviceUnit[ kMaxGpibAddresses ];
    short                       mDeviceSecondaryAddress[ kMaxGpibAddresses ];  
    NSMutableString*            mErrorMsg;  
    NSRecursiveLock*            theHWLock;
	bool                        mMonitorRead;
	bool                        mMonitorWrite;
    ORAlarm*                    noDriverAlarm;
    ORAlarm*                    noPluginAlarm;
    EduWashingtonNplOrcaNi488PlugIn*  gpibEnetInstance;
}

#pragma mark ***Initialization.
- (void)	commonInit;
- (id) 		init;
- (void) 	dealloc;
- (void) 	makeConnectors;
- (NSString*) pluginName;

#pragma mark ***Accessors
- (BOOL)    isEnabled;
- (short) 	boardIndex;
- (void) 	setBoardIndex: (short) anIndex;
- (int) 	ibsta;
- (int)		iberr;
- (long)	ibcntl;
- (NSMutableString*)	errorMsg;

#pragma mark ***Commands
- (void) 	changePrimaryAddress: (short) anOldPrimaryAddress newAddress: (short) aNewPrimaryAddress;
- (void) 	changeState: (short) aPrimaryAddress online: (BOOL) aState;
- (BOOL) 	checkAddress: (short) aPrimaryAddress;
- (void) 	deactivateAddress: (short) aPrimaryAddress;
- (void) 	resetDevice: (short) aPrimaryAddress;
- (void) 	setupDevice: (short) aPrimaryAddress secondaryAddress: (short) aSecondaryAddress;
- (long) 	readFromDevice: (short) aPrimaryAddress data: (char*) aData 
                                               maxLength: (long) aMaxLength;
- (void) 	writeToDevice: (short) aPrimaryAddress command: (NSString*) aCommand;
- (long) 	writeReadDevice: (short) aPrimaryAddress command: (NSString*) aCommand data: (char*) aData
                                                   maxLength: (long) aMaxLength;

- (void) 	enableEOT:(short)aPrimaryAddress state: (BOOL) state;
- (void) 	wait: (short) aPrimaryAddress mask: (short) aWaitMask;


- (void)	checkDeviceThrow: (short) aPrimaryAddress;
- (void)	checkDeviceThrow: (short) aPrimaryAddress checkSetup: (BOOL) aState;
- (void)	GpibError: (NSMutableString*) aMsg;
- (NSString*) 	boardNames: (short) anIndex;
- (id) 		getGpibController;
- (void)	setGPIBMonitorRead: (bool) aMonitorRead;
- (void)	setGPIBMonitorWrite: (bool) aMonitorWrite;

@end

#pragma mark ***Notification string definitions.
extern NSString*	ORGpibMonitorNotification;
extern NSString*	ORGpibEnetTestLock;
extern NSString*	ORGPIBBoardChangedNotification;

#pragma mark ***Other string definitions.
extern NSString*	ORGpibMonitor;
