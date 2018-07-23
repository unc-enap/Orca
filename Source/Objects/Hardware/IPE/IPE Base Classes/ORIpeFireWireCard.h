//
//  ORIpeFireWireCard.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24, 2006.
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

#import "ORIpeCard.h"

@class ORFireWireInterface;
@class ORAlarm;

@interface ORIpeFireWireCard : ORIpeCard
{
	@protected
		ORFireWireInterface* fireWireInterface;
		BOOL pBusSim;
		ORAlarm* simulationAlarm;
}

#pragma mark ¥¥¥Accessors
- (ORFireWireInterface*) fireWireInterface;
- (void) setFireWireInterface:(ORFireWireInterface*)aFwInterface;
- (id) controller;
- (void) setGuardian:(id)aGuardian;
- (NSDictionary*) matchingDictionary;
- (BOOL) pBusSim;
- (void) setPBusSim:(BOOL)flag;
- (void) checkSimulationAlarm;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) serviceChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥HW Access
- (void) findInterface;
- (void) dumpROM;
- (BOOL) serviceIsOpen;
- (BOOL) serviceIsAlive;
- (void) startConnectionAttempts;
- (void) attemptConnection;



- (uint32_t) read:(uint32_t) address;
- (void) read:(uint64_t) address data:(uint32_t*)theData size:(uint32_t)len;

- (void) write:(uint32_t) address 
			   value:(uint32_t)aValue;

- (void) writeBitsAtAddress:(uint32_t)anAddress 
					   value:(uint32_t)dataWord 
					   mask:(uint32_t)aMask  
					shifted:(int)shiftAmount;


- (void) setBitsLowAtAddress:(uint32_t)anAddress 
						mask:(uint32_t)aMask;
						
- (void) setBitsHighAtAddress:(uint32_t)anAddress 
						 mask:(uint32_t)aMask;

- (void) readRegisterBlock:(uint32_t)  anAddress 
				dataBuffer:(uint32_t*) aDataBuffer
					length:(uint32_t)  length 
				 increment:(uint32_t)  incr
			   numberSlots:(uint32_t)  nSlots 
			 slotIncrement:(uint32_t)  incrSlots;

- (void) readBlock:(uint32_t)  anAddress 
		dataBuffer:(uint32_t*) aDataBuffer
			length:(uint32_t)  length 
		 increment:(uint32_t)  incr;


- (void) writeBlock:(uint32_t)  anAddress 
		 dataBuffer:(uint32_t*) aDataBuffer
			 length:(uint32_t)  length 
		  increment:(uint32_t)  incr;

- (void) clearBlock:(uint32_t)  anAddress 
		 pattern:(uint32_t) aPattern
			 length:(uint32_t)  length 
		  increment:(uint32_t)  incr;


@end

extern NSString* ORIpeInterfaceChanged;
extern NSString* ORIpePBusSimChanged;

