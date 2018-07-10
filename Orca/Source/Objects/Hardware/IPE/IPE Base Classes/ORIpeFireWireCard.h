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



- (unsigned long) read:(unsigned long) address;
- (void) read:(unsigned long long) address data:(unsigned long*)theData size:(unsigned long)len;

- (void) write:(unsigned long) address 
			   value:(unsigned long)aValue;

- (void) writeBitsAtAddress:(unsigned long)anAddress 
					   value:(unsigned long)dataWord 
					   mask:(unsigned long)aMask  
					shifted:(int)shiftAmount;


- (void) setBitsLowAtAddress:(unsigned long)anAddress 
						mask:(unsigned long)aMask;
						
- (void) setBitsHighAtAddress:(unsigned long)anAddress 
						 mask:(unsigned long)aMask;

- (void) readRegisterBlock:(unsigned long)  anAddress 
				dataBuffer:(unsigned long*) aDataBuffer
					length:(unsigned long)  length 
				 increment:(unsigned long)  incr
			   numberSlots:(unsigned long)  nSlots 
			 slotIncrement:(unsigned long)  incrSlots;

- (void) readBlock:(unsigned long)  anAddress 
		dataBuffer:(unsigned long*) aDataBuffer
			length:(unsigned long)  length 
		 increment:(unsigned long)  incr;


- (void) writeBlock:(unsigned long)  anAddress 
		 dataBuffer:(unsigned long*) aDataBuffer
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr;

- (void) clearBlock:(unsigned long)  anAddress 
		 pattern:(unsigned long) aPattern
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr;


@end

extern NSString* ORIpeInterfaceChanged;
extern NSString* ORIpePBusSimChanged;

