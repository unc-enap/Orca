// Author: 	Jan M. Wouters
// History:	2003-02-14 (jmw) - Original version.
	
#pragma mark ***Imported Files
#import <Cocoa/Cocoa.h>
#import "OrcaObject.h"

@interface ORGpibDevice : OrcaObject {
	@private
    short	mPrimaryAddress;
    short 	mSecondaryAddress;	
}

#pragma mark ***Initialization
- (void) makeConnectors;

#pragma mark ***Accessors
- (void)	setAddress: (short) aPrimaryAddress secondaryAddress: (short) aSecondaryAddress;
- (short)	primaryAddress;
- (short)	secondaryAddress;

#pragma mark ***Actions
- (void) connect: (short) aPrimaryAddress secondaryAddress: (short) aSecondaryAddress;

@end

#pragma mark ***Extern Definitions
extern NSString* ORGpibPrimaryAddressChangedNotification;
extern NSString* ORGpibSecondaryAddressChangedNotification;
