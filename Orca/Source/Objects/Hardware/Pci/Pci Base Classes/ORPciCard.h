//
//  ORPciCard.h
//  Orca
//
//  Created by Mark Howe on Mon Dec 16 2002.
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

#import "ORCard.h"


#pragma mark ¥¥¥Forward Declarations
@class ORConnector;

@interface ORPciCard : ORCard {
	@private
		NSString*		connectorName;
		ORConnector*	connector; //we won't draw this connector.
	@protected
		BOOL hardwareExists;
        BOOL driverExists;
		BOOL okToShowResetWarning;
}
- (void) loadImage:(NSString*)anImageName;
- (void) awakeAfterDocumentLoaded;

#pragma mark ¥¥¥Accessors
- (NSString*) cardSlotChangedNotification;
- (Class)	guardianClass;
- (BOOL) hardwareExists;
- (ORConnector*)connector;
- (void) 		setConnector:(ORConnector*)aConnector;
- (NSString*) 	connectorName;
- (void) 		setConnectorName:(NSString*)aName;
- (void) 		setSlot:(int)aSlot;
@end

#pragma mark ¥¥¥Extern Definitions
extern NSString* ORPCICardSlotChangedNotification;
