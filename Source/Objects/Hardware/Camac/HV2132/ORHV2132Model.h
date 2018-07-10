/*
 *  ORHV2132Model.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORCamacIOCard.h"

#pragma mark ¥¥¥Forward Declarations
@class ORDataPacket;

//#define HV2132ReadWorking
//#define HV2132NoHardware


enum {
	kHV2132ModifyOneVoltage					= 0,				
	kHV2132SetValue							= 1,							
	kHV2132ModifyAll3_3kVVoltages			= 2,		
	kHV2132ReadOneVoltage					= 3,							
	kHV2132ReadAllVoltages					= 4,						
	kHV2132HVOnOff							= 5,							
	kHV2132RestoreChannel					= 6,						
	kHV2132PresetAll3_3kV					= 7,				
	kHV2132ReadDemandValue					= 8,						
	kHV2132StatusRequest					= 9,						
	kHV2132ReadAllDemandValues				= 10,					
	kHV2132EnableDisableResponse			= 11,				
	kHV2132PresetAll7kVChannels				= 12,				
	kHV2132SetAllVoltageCurrentDemandValues = 13,	
	kHV2132ZeroChannel						= 14,						
	kHV2132IdPodComplement					= 15					
} hv2132Cmds;

enum {
	kHV2132TrueVoltage			 = 3,		
	kHV2132HVOnOffStatus		 = 5,	
	kHV2132DemandValue			 = 8,
	kHV2132FailedResponse		 = 9,
	kHV2132PodComplement		 = 10,	
	kHV2132Finished				 = 11,
	kHV2132ParityError			 = 12,
	kHV2132OverwriteError		 = 13,
	kHV2132TripCondition		 = 14,
	kHV2132TransmitError		 = 15
}hv2132Response;

#define kHV2132NumberSupplies 32

@interface ORHV2132Model : ORCamacIOCard{
    @private
		int channel;
		int mainFrame;
		int hvValue;
        NSString* connectorName;
        ORConnector*  connector; //we won't draw this connector.
		NSLock* commLock;
		NSString* 		dirName;

		NSMutableDictionary* hvRecord;  //tmp fake-out until we can get the read back to work
										//we'll just keep a record of the last value sent
										//one dictionary for each mainframe: key HVMainFrameX
										//each mainframe dictionary: 
										//key: HVStatus value: YES/NO
										//key: setTimeX  value: reference time for channel X
										//key: HVValueX  value: last voltage set for channel X
										
										//store the whole thing in perferences as ORCAHV2132Status
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;

#pragma mark ¥¥¥Notifications
- (void)registerNotificationObservers;
- (void) runStopped:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runAboutToStart:(NSNotification*)aNote;
- (void) powerRestored:(NSNotification*)aNote;
- (void) setMainFrameIDs:(NSNotification*)aNote;
      
#pragma mark ¥¥¥Accessors
- (ORConnector*)connector;
- (void)        setConnector:(ORConnector*)aConnector;
- (NSString*)   connectorName;
- (void)        setConnectorName:(NSString*)aName;
- (int)			hvValue;
- (void)		setHvValue:(int)aHvValue;
- (int)			mainFrame;
- (void)		setMainFrame:(int)aMainFrame;
- (int)			channel;
- (void)		setChannel:(int)aChannel;
- (void)		setDirName:(NSString*)aDirName;
- (NSString*)	dirName;

- (void) setSlot:(int)aSlot;
- (void) setGuardian:(id)aGuardian;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;

#pragma mark ¥¥¥Hardware functions
- (id) getHVController;
- (void) enableL1L2:(BOOL) state;
- (void) clearBuffer;
- (void) sendCmd:(unsigned short)aCmd label:(NSString*)aLabel;
- (void) readData:(unsigned short*)data numWords:(int)num;
- (void) setVoltage:(int) hvValue mainFrame:(int) mainFrame channel:(int) channel;
- (void) readVoltage:(int*) hvValue mainFrame:(int) mainFrame channel:(int) channel;
- (void) readAllVoltages:(int*)hvValues mainFrame:(int) mainFrame;
- (void) setEnableResponse:(BOOL)state mainFrame:(int)aMainFrame;
- (void) setHV:(BOOL)state mainFrame:(int)aMainFrame;
- (void) readTarget:(int*) aValue mainFrame:(int) aMainFrame channel:(int) aChannel;
- (void) readAllTargets:(int*)aValues mainFrame:(int) aMainFrame;
- (void) readStatus:(int*) aValue failedMask:(unsigned short*)failed mainFrame:(int) aMainFrame;
- (void) readPodComplement:(unsigned short*) typeMask mainFrame:(int) aMainFrame;

#pragma mark ¥¥¥Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (void) loadHVParams;
- (void) saveHVParams;

@end

extern NSString* ORHV2132ModelHvValueChanged;
extern NSString* ORHV2132ModelMainFrameChanged;
extern NSString* ORHV2132ModelChannelChanged;
extern NSString* ORHV2132SettingsLock;
extern NSString* ORHV2132StateFileDirChanged;
extern NSString* ORHV2132VoltageChanged;
extern NSString* ORHV2132OnOffChanged;

@interface OrcaObject (HVController)
- (void) setMainFrameID:(unsigned long)aValue;
@end