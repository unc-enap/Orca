//
//  ORIP220Model.h
//  Orca
//
//  Created ¥¥¥by Mark Howe on Tue Jun 5 2007.
//  Copyright Â© 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORVmeIPCard.h"

@interface ORIP220Model :  ORVmeIPCard
{
	@private
        NSLock* hwLock;
		float	outputVoltage[16];
		BOOL	transferMode;
}

#pragma mark ¥¥¥Initialization

#pragma mark ¥¥¥Accessors
- (float) outputVoltage:(unsigned short)index;
- (void) setOutputVoltage:(unsigned short)index withValue:(float)aValue;
- (void) setTransferMode:(BOOL)flag;
- (BOOL) transferMode;
- (NSString*) processingTitle;

#pragma mark ¥¥¥Hardware Access
- (void) resetBoard;
- (void) initBoard;
- (void) readBoard;

@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORIP220VoltageChanged;
extern NSString* ORIP220TransferModeChanged;
extern NSString* ORIP220SettingsLock;

