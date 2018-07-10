//--------------------------------------------------------------------------------
// Class:	ORGpibEnetModel
// Notes:	ibsta - Global provided by NI library indicating status of all commands.
//			iberr - Global, If ibsta & ERR then iberr contains detailed error information.
//			ibctnl - Global containing number of bytes read or written.
// History:	2003-02-15 (jmw)
// Author:	Jan M. Wouters
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
#pragma mark ***Imported Files
//#include <NI488/ni488.h>
#include <stdio.h>

#include "ORGpibEnetModel.h"
#include "StatusLog.h"

#pragma mark ***Defines
static NSString *mBoardNames[ kNumBoards ] = {
@"GPIB0",
@"GPIB1"
};

static NSString*	ORGpibEnetConnection		= @"GPIB Enet Connector";
NSString*			ORGpibEnetTestLock			= @"ORGpibEnetTestLock";

NSString*			ORGpibMonitorNotification   = @"ORGpibMonitorNotification";
NSString*			ORGpibMonitor				= @"ORGpibMonitor";
NSString*			ORGPIBBoardChangedNotification = @"ORGpibBoardChangedNotification";

@implementation ORGpibEnetModel
#pragma mark ***Initialization
- (void) commonInit
{
    short 	i;
    
	theHWLock = [[NSRecursiveLock alloc] init];    
    
    mErrorMsg = [[ NSMutableString alloc ] initWithFormat: @"" ];
    
    for ( i = 0; i < kMaxGpibAddresses; i++ ){
        mDeviceUnit[ i ] = kNotInitialized;
        mDeviceSecondaryAddress[ i ] = 0;
    } 
    
    [ self setBoardIndex: kDefaultGpibPort ];
    
    NSString* plugInDirectory = [[NSBundle mainBundle] builtInPlugInsPath];
    /* Now find the GPIB-ENET bundle. */
    NSBundle* gpibEnetBundle = [NSBundle bundleWithPath:
								[NSString stringWithFormat:@"%@/%@",plugInDirectory,[ self pluginName ]]];
    
    Class gpibEnetClass = [gpibEnetBundle principalClass];
    
    if (gpibEnetClass) {
        gpibEnetInstance = [[gpibEnetClass alloc] init];
        if ( ! [gpibEnetInstance isLoaded] ) {
            /* The class failed to load, no NI488 framework exists. */
            [gpibEnetInstance release];
            gpibEnetInstance = nil;
            NSLogColor([NSColor redColor],@"*** Unable To Locate NI488 drivers.  Please install from the NI disk. ***\n");
            noDriverAlarm = [[ORAlarm alloc] initWithName:@"NI GPIB-ENET drivers not found." severity:0];
            [noDriverAlarm setSticky:NO];
            [noDriverAlarm setAcknowledged:NO];
            [noDriverAlarm postAlarm];
            [noDriverAlarm setHelpStringFromFile:@"NoNI488DriversHelp"];
			
        }
    } 
	else {
        /* It's not here, let's make sure the user knows that. */
        NSLogColor([NSColor redColor],[NSString stringWithFormat:@"*** Unable To Locate %@. Please re-install Orca. ***\n",[ self pluginName ]]);
        noPluginAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Plugin %@ not Found",[self pluginName]] severity:0];
        [noPluginAlarm setSticky:NO];
        [noPluginAlarm setAcknowledged:NO];
        [noPluginAlarm postAlarm];
        [noPluginAlarm setHelpStringFromFile:@"NoNI488PluginHelp"];
		
        gpibEnetInstance = nil;
    }
	
    
}

- (id) init
{
    self = [ super init];
    
    [ self commonInit ];
    
    return self;   
}


- (void) dealloc
{
    [noDriverAlarm clearAlarm];
    [noDriverAlarm release];
    [noPluginAlarm clearAlarm];
    [noPluginAlarm release];
    [gpibEnetInstance release];
    [theHWLock release];
    [ mErrorMsg release ];
    [ super dealloc ];
}

- (NSString*) pluginName
{
    return @"EduWashingtonNplOrcaNi488PlugIn.plugin";
}


- (void) setUpImage
{
    NSImage* aCachedImage = [NSImage imageNamed:@"GpibEnetBox"];
    NSImage* i = [[[NSImage alloc] initWithSize:[aCachedImage size]]autorelease];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];    
    if(![self isEnabled]){
        NSBezierPath* path = [NSBezierPath bezierPath];
        [path moveToPoint:NSZeroPoint];
        [path lineToPoint:NSMakePoint([self frame].size.width,[self frame].size.height)];
        [path moveToPoint:NSMakePoint([self frame].size.width,0)];
        [path lineToPoint:NSMakePoint(0,[self frame].size.height)];
        [path setLineWidth:2];
        [[NSColor redColor] set];
        [path stroke];
    }
    [i unlockFocus];
    
    [ self setImage:i];
}

- (void) makeConnectors
{
	ORConnector* connectorObj = [[ ORConnector alloc ] 
								 initAt: NSMakePoint( [ self x ] + [ self frame ].size.width 
                                                     - kConnectorSize, [ self y ] )
								 withGuardian: self];
	[ connectorObj setConnectorType: 'GPI2' ];
	[ connectorObj addRestrictedConnectionType: 'GPI1' ]; //can only connect to gpib inputs
	[[ self connectors ] setObject: connectorObj forKey: ORGpibEnetConnection ];
	[ connectorObj release ];
}

- (void) makeMainController
{
    [self linkToController: @"ORGpibEnetController"];
}

- (NSString*) helpURL
{
	return @"GPIB/ENet_100.html";
}

#pragma mark ***Accessors
- (BOOL) isEnabled
{
    if ( gpibEnetInstance != nil ) {
        return [ gpibEnetInstance isLoaded ];
    }
    return NO;
}

- (short) boardIndex
{
    return( mBoardIndex );
}

- (void) setBoardIndex: (short) anIndex
{
    mBoardIndex = anIndex;
	
	[[ NSNotificationCenter defaultCenter ]
	 postNotificationName: ORGPIBBoardChangedNotification
	 object: self];
}


- (NSMutableString*) errorMsg
{
    return( mErrorMsg );
}

- (int) ibsta
{
    if ( [ self isEnabled ]) {
        return( [gpibEnetInstance ibsta] );
    }
    return 0;
}

- (int) iberr
{
    if ( [ self isEnabled ]) {
        return( [gpibEnetInstance iberr] );
    }
    return 0;
}

- (long) ibcntl
{
    if ( [ self isEnabled ]) {
        return( [gpibEnetInstance ibcntl] );
    }
    return 0;
}


#pragma mark ***Basic commands
- (void) changePrimaryAddress: (short) anOldPrimaryAddress newAddress: (short) aNewPrimaryAddress
{
    // Make sure that device is initialized and that new address is valid.
    if ( ! [ self isEnabled ]) return;
    @try {
        [theHWLock lock];   //-----begin critical section
        [ self checkDeviceThrow: anOldPrimaryAddress ];
        [ self checkDeviceThrow: aNewPrimaryAddress checkSetup: false ];
        
        [ gpibEnetInstance ibpad:mDeviceUnit[ anOldPrimaryAddress ] v:aNewPrimaryAddress ];
		
        if ( (int) [gpibEnetInstance ibsta] & (unsigned short) [gpibEnetInstance err] ) {
            [ mErrorMsg setString: @"***Error: ibpad" ];
            [ self GpibError: mErrorMsg ];
            
            [ NSException raise: OExceptionGpibError format: @"%@",mErrorMsg ];
        }
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
}


- (void) changeState: (short) aPrimaryAddress online: (BOOL) aState
{
    if ( ! [ self isEnabled ]) return;
    @try {
        [theHWLock lock];   //-----begin critical section
        short deviceState = 0;
        
        // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Change device state.
        if ( aState ) deviceState = 1;
        [gpibEnetInstance ibonl:mDeviceUnit[ aPrimaryAddress ] v:deviceState];
        if ([gpibEnetInstance ibsta] & [gpibEnetInstance err] ) {
            [ mErrorMsg setString:  @"***Error: ibonl" ];
            [ self GpibError: mErrorMsg ];
            
            [ NSException raise: OExceptionGpibError format: @"%@",mErrorMsg ];
        }
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
}


- (BOOL) checkAddress: (short) aPrimaryAddress
{
    BOOL  bRetVal = false;
    if ( ! [ self isEnabled ]) return bRetVal;
    @try {
        [theHWLock lock];   //-----begin critical section
        
        // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress checkSetup: false ];
        
        // Check if device has been setup.
        if ( mDeviceUnit[ aPrimaryAddress ] > kNotInitialized ){
            bRetVal = true;
        }
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
    return( bRetVal );    
}


- (void) deactivateAddress: (short) aPrimaryAddress
{
    if ( ! [ self isEnabled ]) return;
    @try {
        [ theHWLock lock ];   //-----begin critical section
		// Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Deactivate the device
        [gpibEnetInstance ibonl:mDeviceUnit[ aPrimaryAddress ] v:0 ];
        if ( [gpibEnetInstance ibsta] & [gpibEnetInstance err] )
        {
            [ mErrorMsg setString: @"***Error: ibonl (deactivate)" ];
            [ self GpibError: mErrorMsg ];
            [ NSException raise: OExceptionGpibError format: @"%@",mErrorMsg ];
        }    
        [ theHWLock unlock ];   //-----end critical section
    }
	@catch(NSException* localException) {
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    }
    
}

- (void) enableEOT:(short)aPrimaryAddress state: (BOOL) state
{
    if ( ! [ self isEnabled ]) return;
    // Make sure that device is initialized.
    @try {
        [ theHWLock lock ];   //-----begin critical section
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        [gpibEnetInstance ibeot:mDeviceUnit[ aPrimaryAddress ] v:state];
        if ( (int)[gpibEnetInstance ibsta] & (unsigned short)[gpibEnetInstance err] ){
            [ mErrorMsg setString: [NSString stringWithFormat:@"***Error: ibeot (%d)",state] ];
            [ self GpibError: mErrorMsg ];
            [ NSException raise: OExceptionGpibError format: @"%@",mErrorMsg ];
        } 
        [ theHWLock unlock ];   //-----end critical section
    }
	@catch(NSException* localException) {
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    }
    
}



- (void) resetDevice: (short) aPrimaryAddress
{
    if ( ! [ self isEnabled ]) return;
    @try {
        [theHWLock lock];   //-----begin critical section
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Clear device.
        [gpibEnetInstance ibclr:mDeviceUnit[ aPrimaryAddress ]];
        if ( [gpibEnetInstance ibsta] & [gpibEnetInstance err] ) {
            [ mErrorMsg setString: @"***Error: ibclr" ];
            [ self GpibError: mErrorMsg ];
            [ NSException raise: OExceptionGpibError format: @"%@",mErrorMsg ];
        }
        [ theHWLock unlock ];   //-----end critical section
    }
	@catch(NSException* localException) {
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    }
    
}

- (void) setGPIBMonitorRead: (bool) aMonitorRead
{
	mMonitorRead = aMonitorRead;
}
- (void) setGPIBMonitorWrite: (bool) aMonitorWrite
{
	mMonitorWrite = aMonitorWrite;
}

- (void) setupDevice: (short) aPrimaryAddress secondaryAddress: (short) aSecondaryAddress
{  
    if ( ! [ self isEnabled ]) return;
    @try {
        // Check device number.
        [theHWLock lock];   //-----begin critical section
        [ self checkDeviceThrow: aPrimaryAddress checkSetup: false ];
        
        mDeviceSecondaryAddress[ aPrimaryAddress ] = aSecondaryAddress;
	    
        // Perform the initialization.
        mDeviceUnit[ aPrimaryAddress ] = [gpibEnetInstance ibdev:mBoardIndex 		// (GPIB0, GPIB1, ... )
															 pad:aPrimaryAddress 
															 sad:aSecondaryAddress
															 tmo:[gpibEnetInstance t3s]   	// Timeout setting (Txs = x secs)
															 eot:1			// Assert EOI line at end of write.
															 eos:0];			// EOS termination mode.
        
        // Check for an error
        if ( [gpibEnetInstance ibsta] &  [gpibEnetInstance err] ) {
            [ mErrorMsg setString:  @"***Error: ibdev" ];
            [ self GpibError: mErrorMsg ]; 
            [ NSException raise: OExceptionGpibError format: @"%@",mErrorMsg ];
        }
        
        // Check that a device is actually present.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Clear the device.
        [ self resetDevice: aPrimaryAddress ];
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
}


- (long) readFromDevice: (short) aPrimaryAddress data: (char*) aData maxLength: (long) aMaxLength
{
    if ( ! [ self isEnabled ]) return -1;
    long	nReadBytes = -1;
    
    @try {
        // Make sure that device is initialized.
        [ theHWLock lock ];   //-----begin critical section
        [ self checkDeviceThrow: aPrimaryAddress ];
        
	    //double t0 = [NSDate timeIntervalSinceReferenceDate];
	    //while([NSDate timeIntervalSinceReferenceDate]-t0 < .01);
        
        // Perform the read.
        [ gpibEnetInstance ibrd:mDeviceUnit[ aPrimaryAddress ] 
							buf:aData
							cnt:aMaxLength ];
        if ( [ gpibEnetInstance ibsta ] & [ gpibEnetInstance err ] ) {
            [ mErrorMsg setString:  @"***Error: ibrd" ];
            [ self GpibError: mErrorMsg ]; 
            [ NSException raise: OExceptionGpibError format: @"%@",mErrorMsg ];
        }
        
        // Successful read.
        else
        {
            nReadBytes = [ gpibEnetInstance ibcntl ];
            
            // Allow monitoring of commands.
            if ( mMonitorRead )
            {
                NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];			
                NSString* dataStr = [[ NSString alloc ] initWithBytes: aData length: nReadBytes encoding: NSASCIIStringEncoding ];
                [ userInfo setObject: [ NSString stringWithFormat: @"Read - Address: %d length: %ld data: %@\n", 
									   aPrimaryAddress, nReadBytes, dataStr ] 
                              forKey: ORGpibMonitor ]; 
                
                [[ NSNotificationCenter defaultCenter ]
				 postNotificationName: ORGpibMonitorNotification
				 object: self
				 userInfo: userInfo ];
                [ dataStr release ];
            }
            
        }
        [ theHWLock unlock ];   //-----end critical section
    }
	@catch(NSException* localException) {
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    }
    
    return( nReadBytes );
}


- (void) writeToDevice: (short) aPrimaryAddress command: (NSString*) aCommand
{
    if ( ! [ self isEnabled ]) return;
    @try {
        [ theHWLock lock ];   //-----begin critical section
		// Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Allow monitoring of commands.
        if ( mMonitorWrite )
        {
            NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];
            [ userInfo setObject: [ NSString stringWithFormat: @"Write - Address: %d Comm: %s\n", aPrimaryAddress, [ aCommand cStringUsingEncoding:NSASCIIStringEncoding ]] 
                          forKey: ORGpibMonitor ]; 
            
            [[ NSNotificationCenter defaultCenter ]
			 postNotificationName: ORGpibMonitorNotification
			 object: self
			 userInfo: userInfo ];
        }
        
        //	printf( "Command %s\n", [ aCommand cString ] );
        
        // Write to device.
        [ gpibEnetInstance ibwrt:mDeviceUnit[ aPrimaryAddress ]
							 buf:(char *)[ aCommand cStringUsingEncoding:NSASCIIStringEncoding ]
							 cnt:[ aCommand length ] ];
        if ( [ gpibEnetInstance ibsta ] & [ gpibEnetInstance err ] ) {
            [ mErrorMsg setString:  @"***Error: ibwrt" ];
            [ self GpibError: mErrorMsg ]; 
            [ NSException raise: OExceptionGpibError format:@"%@", mErrorMsg ];
        }  
        [ theHWLock unlock ];   //-----end critical section
    }
	@catch(NSException* localException) {
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    }  
}


- (long) writeReadDevice: (short) aPrimaryAddress command: (NSString*) aCommand data: (char*) aData
               maxLength: (long) aMaxLength
{
    long retVal = 0;
    if ( ! [ self isEnabled ]) return -1;
    @try {
        
        [theHWLock lock];   //-----begin critical section
        [ self writeToDevice: aPrimaryAddress command: aCommand ];
        retVal = [ self readFromDevice: aPrimaryAddress data: aData maxLength: aMaxLength ];
        
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
    return( retVal );
}

- (void) wait: (short) aPrimaryAddress mask: (short) aWaitMask
{
    if ( ! [ self isEnabled ]) return;
    @try {
        [theHWLock lock];   //-----begin critical section
		// Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Wait for specified events.
        [ gpibEnetInstance ibwait:mDeviceUnit[ aPrimaryAddress ] mask:aWaitMask ];
        if ( [ gpibEnetInstance ibsta ] & [ gpibEnetInstance err ] ) {
            [ mErrorMsg setString:  @"***Error: ibwait" ];
            [ self GpibError: mErrorMsg ]; 
            [ NSException raise: OExceptionGpibError format: @"%@",mErrorMsg ];
        }
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
}


#pragma mark ***Support Methods
- (NSString*) boardNames: (short) anIndex
{
    if ( anIndex > -1 && anIndex < kNumBoards )
        return mBoardNames[ anIndex ];
    
    return( mBoardNames[ 0 ] );
}


- (void) checkDeviceThrow: (short) aPrimaryAddress
{
    [ self checkDeviceThrow: aPrimaryAddress checkSetup: true ];
}


- (void) checkDeviceThrow: (short) aPrimaryAddress checkSetup: (BOOL) aState
{
    if ( ! [ self isEnabled ]) return;
    @try {
        [theHWLock lock];   //-----begin critical section
        if ( aPrimaryAddress < 0 || aPrimaryAddress > kMaxGpibAddresses ){
            [ mErrorMsg setString: [ NSString stringWithFormat: @"***Error: Bad GPIB Address %d\n", aPrimaryAddress ]];
            [ NSException raise: OExceptionGpibError format: @"%@",mErrorMsg ];
        }
        else if ( aState ){
            if ( mDeviceUnit[ aPrimaryAddress ] == kNotInitialized ){
                [ mErrorMsg setString: [ NSString stringWithFormat: 
										@"***Error: Device at address %d not found.\n", aPrimaryAddress ]];
                [ NSException raise: OExceptionGpibError format: @"%@",mErrorMsg ];
            }
            
            // Now test if device is actually present.
            else {
                short		listen;
                
                [ gpibEnetInstance ibln:mDeviceUnit[ aPrimaryAddress ] 
									pad:aPrimaryAddress 
									sad:mDeviceSecondaryAddress[ aPrimaryAddress ] 
								 listen:&listen ];
                
                // Deviced is not present so throw error.
                if ( !listen ) {
                    [ mErrorMsg setString: [ NSString stringWithFormat:
											@"***Error: No device present at address %d\n", aPrimaryAddress ]];
                    [ NSException raise: OExceptionGpibError format: @"%@",mErrorMsg ];
                }
            }
        }
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
}


- (id) getGpibController
{
	return self;
}


- (void) GpibError: (NSMutableString*) aMsg
{
    if ( ! [ self isEnabled ]) return;
    @try {
        // Handle the master error register and extract error.
        [theHWLock lock];   //-----begin critical section
        [ aMsg appendString: [ NSString stringWithFormat:  @" ibsta = 0x%x < ", [ gpibEnetInstance ibsta ] ]];
        
        NSMutableString *errorType = [[ NSMutableString alloc ] initWithFormat: @"" ];
        
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance err ] )  [ errorType appendString: @" ERR " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance timo ])  [ errorType appendString: @" TIMO " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance end ] )  [ errorType appendString: @" END " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance srqi ])  [ errorType appendString: @" SRQI " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance rqs ] )  [ errorType appendString: @" RQS " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance cmpl ])  [ errorType appendString: @" CMPL " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance lok ] )  [ errorType appendString: @" LOK " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance rem ] )  [ errorType appendString: @" REM " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance cic ] )  [ errorType appendString: @" CIC " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance atn ] )  [ errorType appendString: @" ATN " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance tacs ])  [ errorType appendString: @" TACS " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance lacs ])  [ errorType appendString: @" LACS " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance dtas ])  [ errorType appendString: @" DTAS " ];
        if ([ gpibEnetInstance ibsta ] & [ gpibEnetInstance dcas ])  [ errorType appendString: @" DCAS " ];
        
        [ aMsg appendString: errorType ];
        [ errorType release ];
        
        // Handle the actual error message.  This message expands on what ibsta found.  Only
        // valid if ibsta & ERR is true.
        [ aMsg appendString: [ NSString stringWithFormat: @"\niberr = %d", (int) [ gpibEnetInstance iberr ] ]];
        
        NSMutableString *errorMsg = [[ NSMutableString alloc ] initWithFormat: @"" ];
        
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance edvr ]) [ errorMsg appendString: @" EDVR <DOS Error>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance ecic ]) [ errorMsg appendString: @" ECIC <Not Controller-In-Charge>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance enol ]) [ errorMsg appendString: @" ENOL <No Listener>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance eadr ]) [ errorMsg appendString: @" EADR <Address error>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance earg ]) [ errorMsg appendString: @" EARG <Invalid argument>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance esac ]) [ errorMsg appendString: @" ESAC <Not System Controller>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance eabo ]) [ errorMsg appendString: @" EABO <Operation aborted>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance eneb ]) [ errorMsg appendString: @" ENEB <No GPIB board>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance eoip ]) [ errorMsg appendString: @" EOIP <Async I/O in progress>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance ecap ]) [ errorMsg appendString: @" ECAP <No capability>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance efso ]) [ errorMsg appendString: @" EFSO <File system error>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance ebus ]) [ errorMsg appendString: @" EBUS <Command error>\n" ];
        if ((int)[ gpibEnetInstance iberr ] == (unsigned short)[ gpibEnetInstance estb ]) [ errorMsg appendString: @" ESTB <Status byte lost>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance esrq ]) [ errorMsg appendString: @" ESRQ <SRQ stuck on>\n" ];
        if ([ gpibEnetInstance iberr ] == [ gpibEnetInstance etab ]) [ errorMsg appendString: @" ETAB <Table Overflow>\n" ];
        
        [ aMsg appendString: errorMsg ];
        //	printf( "4th Message: %s\n", [ mErrorMsg cString ] );
        
        [ errorMsg release ];
        
        [ aMsg appendString: [ NSString stringWithFormat: @"ibcntl = %ld\n", [ gpibEnetInstance ibcntl ]]];
        
        [theHWLock unlock];   //-----end critical section
		// Call ibonl to take the device and interface offline
		//    ibonl( Device, 0 );
		//    ibonl( BoardIndex, 0 );
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
}

#pragma mark ¥¥¥Archival
static NSString	*ORBoardIndex			= @"GPIB-ENET Board Index";

- (id) initWithCoder: (NSCoder*) decoder
{
    self = [ super initWithCoder: decoder ];
    
    [[ self undoManager ] disableUndoRegistration ];
    [ self commonInit ];
    [ self setBoardIndex: [ decoder decodeIntForKey: ORBoardIndex ]];
    
    [[ self undoManager ] enableUndoRegistration ];
    
    return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
    [ super encodeWithCoder: encoder ];
    [ encoder encodeInt: mBoardIndex forKey: ORBoardIndex ];
}


@end

