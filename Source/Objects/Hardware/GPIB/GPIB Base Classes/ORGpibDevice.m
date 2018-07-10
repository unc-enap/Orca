// Author:	Jan M. Wouters
// History:	2003-02-14 (jmw)

#pragma mark ¥¥¥Imported Files
#import "ORGpibDevice.h"
#import "ORGpibEnetModel.h"
#import "ORConnector.h"
#import "StatusLog.h"

static NSString* ORGpibConnection 	= @"GPIB Device Connector";

@implementation ORGpibDevice

#pragma mark ¥¥¥Notification Strings
NSString*	ORGpibPrimaryAddressChangedNotification 	= @"GPIB Primary Address Changed";
NSString*	ORGpibSecondaryAddressChangedNotification 	= @"GPIB Secondary Address Changed";

#pragma mark ¥¥¥Initalization
- (id) initWithDocument: (ORDocument*) aDocument
{
    self = [ super initWithDocument: aDocument ];
    return self;
}


- (void) makeConnectors
//--------------------------------------------------------------------------------
/*" make a connector with which GPIB device can connect to controller box. 
    _{#Return	- None}
"*/
//--------------------------------------------------------------------------------
{
	ORConnector* connectorObj = [[ ORConnector alloc ] 
                                initAt: NSMakePoint( [ self x ] + [ self frame ].size.width 
                                                     - kConnectorSize, [ self y ] )
                            withParent: self];
	[[ self connectors ] setObject: connectorObj forKey: ORGpibConnection ];
	[ connectorObj release ];
}


- (void) dealloc
{
    [ super dealloc ];
}

#pragma mark ¥¥¥Accessors
- (short) primaryAddress
{
    return mPrimaryAddress;
}

- (short) secondaryAddress
{
    return( mSecondaryAddress );
}

- (void) setAddress: (short) aPrimaryAddress secondaryAddress: (short) aSecondaryAddress
//--------------------------------------------------------------------------------
/*" Set the address for the GPIB device.  Send notification of change. 
    _{#anAddress	- None}
"*/
//--------------------------------------------------------------------------------
{
//    [[[ self undoManager ] prepareWithInvocationTarget: self ] 
//                        setAddress:[ self mPrimaryAddress secondaryAddress: mSecondaryAddress ]];
    mPrimaryAddress = aPrimaryAddress;
    mSecondaryAddress = aSecondaryAddress;

    [[ NSNotificationCenter defaultCenter ]
         postNotificationName: ORGpibPrimaryAddressChangedNotification
                       object: [ self document ]
                     userInfo: [ NSDictionary dictionaryWithObject: self 
                                                            forKey: ORNotificationSender ]];

    [[ NSNotificationCenter defaultCenter ]
         postNotificationName: ORGpibSecondaryAddressChangedNotification
                       object: [ self document ]
                     userInfo: [ NSDictionary dictionaryWithObject: self 
                                                            forKey: ORNotificationSender ]];

}


#pragma mark ***Actions
- (void) connect: (short) aPrimaryAddress secondaryAddress: (short) aSecondaryAddress
{
    NS_DURING
        ORConnector* connectorObj = [[ self connectors ] objectForKey: ORGpibConnection ];
        [[[ connectorObj connector ] parent ] setupDevice: aPrimaryAddress 
                                         secondaryAddress: aSecondaryAddress ];
                                   
        [ self setAddress: aPrimaryAddress secondaryAddress: aSecondaryAddress ];
        
    NS_HANDLER
        [ localException raise ];
    NS_ENDHANDLER
}


#pragma mark ¥¥¥Archival
static NSString *ORGpibPrimaryAddress			= @"ORGpib Primary Address";
static NSString *ORGpibSecondaryAddress			= @"ORGpib Secondary Address";

- (id) initWithCoder: (NSCoder*) decoder
{
    self = [ super initWithCoder: decoder ];

    [[ self undoManager ] disableUndoRegistration ];

    [ self setAddress: [decoder decodeIntForKey: ORGpibPrimaryAddress ] 
     secondaryAddress: [ decoder decodeIntForKey: ORGpibSecondaryAddress ]];
    
    [[ self undoManager ] enableUndoRegistration];
    return self;
}


- (void) encodeWithCoder: (NSCoder*) encoder
{
    [ super encodeWithCoder: encoder ];
    [ encoder encodeInt: mPrimaryAddress forKey: ORGpibPrimaryAddress ];
    [ encoder encodeInt: mSecondaryAddress forKey: ORGpibSecondaryAddress ];
}

@end
