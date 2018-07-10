//
//  ORVmeCrateModel.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
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

#import "ORVmeCrate.h"

#pragma mark ¥¥¥Forward Declarations

@interface ORVmeCrateModel : ORVmeCrate   {
}

- (void) makeConnectors;
- (void) setUpImage;
- (void) makeMainController;
- (void) connected;
- (void) disconnected;

#pragma mark ¥¥¥Accessors
- (NSString*) adapterArchiveKey;
- (NSString*) crateAdapterConnectorKey;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) powerFailed:(NSNotification*)aNotification;
- (void) powerRestored:(NSNotification*)aNotification;
@end

@interface ORVmeCrateModel (OROrderedObjHolding)
- (int) maxNumberOfObjects;
- (int) objWidth;
@end


