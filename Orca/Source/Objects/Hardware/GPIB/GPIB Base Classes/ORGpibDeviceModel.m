// Author:	Jan M. Wouters
// History:	2003-02-14 (jmw)
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
#import "ORGpibDeviceModel.h"
#import "ORGpibEnetModel.h"


// Static string defining dictionary constants.
NSString* ORGpibConnection 				= @"GPIB Device Connector";
NSString* ORGpibConnectionToNextDevice 	= @"GPIB Device Connector To Next Device";
NSString* ORGpibAddress					= @"GPIB Device Address";
NSString* ORGpibDeviceConnected 		= @"GPIB Device Connected";

// Definitions.
#pragma mark ¥¥¥Definitions
#define kDefaultPrimaryAddress			0
#define kDefaultSecondaryAddress 		0

@implementation ORGpibDeviceModel

#pragma mark ¥¥¥Notification Strings
NSString*	ORGpibPrimaryAddressChangedNotification 	= @"GPIB Primary Address Changed";
NSString*	ORGpibSecondaryAddressChangedNotification 	= @"GPIB Secondary Address Changed";
NSString*   ORGpibDeviceConnectedNotification			= @"GPIB Device connected";

#pragma mark ¥¥¥Initalization
//--------------------------------------------------------------------------------
/*!\method  init
 * \brief	Called first time class is initialized.  Used to set basic
 *			default values first time object is created.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) init
{
    self = [ super init];
    
    [[ self undoManager ] disableUndoRegistration ];
    
    [ self setPrimaryAddress: kDefaultPrimaryAddress ];
    [ self setSecondaryAddress: kDefaultSecondaryAddress ];
    
	[[ self undoManager ] enableUndoRegistration ];
    
    mConnected = false;
    
    return self;
}


//--------------------------------------------------------------------------------
/*!\method  makeConnectors
 * \brief	Makes connection object to which device can be connected to controller.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) makeConnectors
{
	if(![[ self connectors ] objectForKey:ORGpibConnection]){
		
		// make the first connect object.
		ORConnector* connectorObj1 = [[ ORConnector alloc ] 
									  initAt: NSMakePoint( 2, 2 )
									  withGuardian: self];
		[[ self connectors ] setObject: connectorObj1 forKey: ORGpibConnection ];
		[ connectorObj1 setConnectorType: 'GPI1' ];
		[ connectorObj1 addRestrictedConnectionType: 'GPI2' ]; //can only connect to gpib outputs
		[ connectorObj1 release ];
	}
	
	if(![[ self connectors ] objectForKey:ORGpibConnectionToNextDevice]){
		// Make the second connector object.
		ORConnector* connectorObj2 = [[ ORConnector alloc ] 
									  initAt: NSMakePoint( [self frame].size.width-kConnectorSize-2, 2 )
									  withGuardian: self];
		[[ self connectors ] setObject: connectorObj2 forKey: ORGpibConnectionToNextDevice ];
		[ connectorObj2 setConnectorType: 'GPI2' ];
		[ connectorObj2 addRestrictedConnectionType: 'GPI1' ]; //can only connect to gpib inputs
		[ connectorObj2 release ];
	}
}


//--------------------------------------------------------------------------------
/*!\method  dealloc
 * \brief	Unregister notifications and do general cleanup.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) dealloc
{
    [ mIdentifier release ];
    
    [ super dealloc ];
}

#pragma mark ¥¥¥Accessors

- (NSString*) title 
{
	return [NSString stringWithFormat:@"(GPIB %d)",[self primaryAddress]];
}

//--------------------------------------------------------------------------------
/*!\method 	gpibIdentifier
 * \brief	Return string with self identification of GPIB device.
 * \return	The identifier.
 * \note	
 */
//--------------------------------------------------------------------------------
- (NSString *) gpibIdentifier
{
    return mIdentifier;
}

//--------------------------------------------------------------------------------
/*!\method 	isConnected
 * \brief	Determine if device is connected to GPIB.  If not connect the device.
 * \return	True - if connected, false - if not connected.
 * \note	
 */
//--------------------------------------------------------------------------------
- (BOOL) isConnected
{
    
    // Device is not connected so try to connect
    if ( !mConnected )
    {
        [ self connect ];
    }
    return( mConnected );
}

//--------------------------------------------------------------------------------
/*!\method 	connected
 * \brief	Determine if device is connected to GPIB. 
 * \return	True - if connected, false - if not connected.
 * \note	
 */
//--------------------------------------------------------------------------------
- (BOOL) connected
{
	return mConnected;
}


- (short) primaryAddress
{
    return mPrimaryAddress;
}

- (short) secondaryAddress
{
    return( mSecondaryAddress );
}

//--------------------------------------------------------------------------------
/*!\method  setPrimaryAddress  
 * \brief	Set the primary address for the GPIB device.  Send notification of change.
 * \param	aPrimaryAddress			- The new primary address.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) setPrimaryAddress: (short) aPrimaryAddress
{
    [[[ self undoManager ] prepareWithInvocationTarget: self ] 
	 setPrimaryAddress: [ self primaryAddress ]];                         
    
    mPrimaryAddress = aPrimaryAddress;
    
    [[ NSNotificationCenter defaultCenter ]
	 postNotificationName: ORGpibPrimaryAddressChangedNotification
	 object: self];
    
}

//--------------------------------------------------------------------------------
/*!\method  setSecondaryAddress  
 * \brief	Set the secondary address for the GPIB device.  Send notification of change.
 * \param	aPrimaryAddress			- The new primary address.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) setSecondaryAddress: (short) aSecondaryAddress
{
    [[[ self undoManager ] prepareWithInvocationTarget: self ] 
	 setSecondaryAddress: [ self secondaryAddress ]];                         
    
    mSecondaryAddress = aSecondaryAddress;
    [[ NSNotificationCenter defaultCenter ]
	 postNotificationName: ORGpibSecondaryAddressChangedNotification
	 object: self];
    
    
}

#pragma mark ¥¥¥Actions
//--------------------------------------------------------------------------------
/*!\method  clearStatusReg
 * \brief	Clears the status register of the device.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) clearStatusReg
{
    NSString *command = [ NSString stringWithFormat: @"*CLS" ];
    [ self writeToGPIBDevice: command ];
}

//--------------------------------------------------------------------------------
/*!\method  connect  
 * \brief	Attempt to connect to the actual hardware device.
 * \note
 * \history	2003-10-16 (jmw) - Added getting of device name immediately after 
 *								connection.	
 */
//--------------------------------------------------------------------------------
- (void) connect
{
    @try {
        [[ self getGpibController ] setupDevice: mPrimaryAddress 
                               secondaryAddress: mSecondaryAddress ];
        mConnected = true;
        
        // send notification that GPIB is connected
        // Create a dictionary object that stores a pointer to this object and the channel that was changed.
        NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];
        [ userInfo setObject: [ NSNumber numberWithInt: mPrimaryAddress ] forKey: ORGpibAddress ];
        [ userInfo setObject: [ NSNumber numberWithInt: 1 ] forKey: ORGpibDeviceConnected ];
        
        // Send out notification that the value has changed.  The dictionary object just created is sent
        // so that objects receiving the notification know what has happened.
        [[ NSNotificationCenter defaultCenter ]
		 postNotificationName: ORGpibDeviceConnectedNotification
		 object: self
		 userInfo: userInfo ];
        
        // Get the device name
        //[ self getID ];
        
        
    }
	@catch(NSException* localException) {
        mConnected = false;
        
        // Send notification that GPIB connection failed.
        // Create a dictionary object that stores a pointer to this object and the channel that was changed.
        NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];
        [ userInfo setObject: [ NSNumber numberWithInt: mPrimaryAddress ] forKey: ORGpibAddress ];
        [ userInfo setObject: [ NSNumber numberWithInt: 0 ] forKey: ORGpibDeviceConnected ];
        
        // Send out notification that the value has changed.  The dictionary object just created is sent
        // so that objects receiving the notification know what has happened.
        [[ NSNotificationCenter defaultCenter ]
		 postNotificationName: ORGpibDeviceConnectedNotification
		 object: self
		 userInfo: userInfo ];
        
        // Raise an exception.
        [ localException raise ];
    }
}


//--------------------------------------------------------------------------------
/*!\method  getID 
 * \brief	Gets the identification of the device in device specific format. 
 * \return	Return NSString with identification information.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) getID
{
    //    NSString*	identifier;
    char		tmpData[ 256 ];
    
    // Send identification command
    NSString* command = [ NSString stringWithFormat: @"*IDN?" ];
    [ self writeReadGPIBDevice: command
                          data: tmpData
                     maxLength: 256 ]; 
    
    // Store value internally.
    [ mIdentifier release ];
    mIdentifier = [[ NSString alloc ] initWithCString: &tmpData[ 0 ] encoding:NSASCIIStringEncoding];                         
}

//--------------------------------------------------------------------------------
/*!\method  readFromGPIBDevice 
 * \brief	Attempt to write command to GPIB device. 
 * \param	aCommand		- The command to issue.
 * \return	Length of string returned from GPIB device.
 * \note	
 */
//--------------------------------------------------------------------------------
- (long) readFromGPIBDevice: (char*) aData maxLength: (long) aMaxLength
{
    long		returnLength = 0;
    
    @try {
        if ( [ self isConnected ] )
        {            
            returnLength = [[self getGpibController] readFromDevice: mPrimaryAddress
                                                               data: aData
                                                          maxLength: aMaxLength ];
        }
        else
        {
            NSString *errorMsg = @"Must establish GPIB connection prior to reading from device.\n";
            [ NSException raise: OExceptionGPIBConnectionError format: @"%@",errorMsg ];
        }
	}
	@catch(NSException* localException) {
		
	}
	
	return( returnLength );
}

//--------------------------------------------------------------------------------
/*!\method  writeToGPIBDevice 
 * \brief	Attempt to write command to GPIB device. 
 * \param	aCommand		- The command to issue.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) writeToGPIBDevice: (NSString*) aCommand
{
    @try {
        if( [ self isConnected ] )
        {
            [[ self getGpibController ] writeToDevice: mPrimaryAddress
                                              command: aCommand ];
        }
        else
        {
            NSString *errorMsg = @"Must establish GPIB connection prior to issuing command\n";
            [ NSException raise: OExceptionGPIBConnectionError format: @"%@",errorMsg ];
        }
	}
	@catch(NSException* localException) {
		[ localException raise ];
	}
}


//--------------------------------------------------------------------------------
/*!\method  writeReadGPIBDevice 
 * \brief	Attempt to write command to GPIB device and then read response
 * \param	aCommand		- The command to issue.
 * \return	Number of bytes read in.  -1 indicates that nothing was r
 * \note	
 */
//--------------------------------------------------------------------------------
- (long) writeReadGPIBDevice: (NSString*) aCommand data: (char*) aData
                   maxLength: (long) aMaxLength
{
    [ self writeToGPIBDevice: aCommand ];
    return( [ self readFromGPIBDevice: aData maxLength: aMaxLength ] );
}

//--------------------------------------------------------------------------------
/*!\method  enableEOT 
 * \brief	Attempt to set the state of the device EOT. 
 * \param	state		- The new state of the EOT.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) enableEOT: (BOOL) state
{
    @try {
        if( mConnected )
        {
            [[ self getGpibController ] enableEOT: mPrimaryAddress
                                            state: state ];
        }
        else
        {
            NSString *errorMsg = @"Must establish GPIB connection prior to issuing command\n";
            [ NSException raise: OExceptionGPIBConnectionError format:@"%@", errorMsg ];
        }
	}
	@catch(NSException* localException) {
		[ localException raise ];
	}
}




#pragma mark ¥¥¥Support functions
//--------------------------------------------------------------------------------
/*!\method  cacheTheController 
 * \brief	Cache link to controller.  This cache is used to speed up acquisition.
 * \return	True - caching successful.
 * \note	
 */
//--------------------------------------------------------------------------------
- (bool) cacheTheController
{    
    mController = [ self getGpibController ];
    return mController != nil;
}

//--------------------------------------------------------------------------------
/*!\method  getGpibController 
 * \brief	This method searchs back up the connector chain and returns a gpib controller
 * \return	The gpib controller if found, else returns nil.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) getGpibController
{
	id obj = [self objectConnectedTo:ORGpibConnection];
	id cont =  [ obj getGpibController ];
	return cont;
}


//--------------------------------------------------------------------------------
/*!\method  convertStringToDouble 
 * \brief	This converts a number at the end of a returned string to a double.
 * \param	aString		- The string to search.
 * \param	aLength		- The length of the string.
 * \return	The number.
 * \note	
 */
//--------------------------------------------------------------------------------
- (double) convertStringToDouble: (char*) aString withLength: (long) aLength
{
	char 	*tmpString;
	double	retVal = 0.0;
	
	tmpString = [ self findNumber: aString withLength: aLength ];
	if ( tmpString )
	{
		sscanf( tmpString, "%le", &retVal );
	}
	return( retVal );
}

//--------------------------------------------------------------------------------
/*!\method  convertStringToFloat
 * \brief	This converts a number at the end of a returned string to a float.
 * \param	aString		- The string to search.
 * \param	aLength		- The length of the string.
 * \return	The number.
 * \note	
 */
//--------------------------------------------------------------------------------
- (float) convertStringToFloat: (char*) aString withLength: (long) aLength
{
	char 	*tmpString;
	float	retVal = 0.0;
	
	tmpString = [ self findNumber: aString withLength: aLength ];
	if ( tmpString )
	{
		sscanf( tmpString, "%e", &retVal );;	
	}
	return( retVal );
}

//--------------------------------------------------------------------------------
/*!\method  convertStringToLong 
 * \brief	This converts a number at the end of a returned string to a long.
 * \param	aString		- The string to search.
 * \param	aLength		- The length of the string.
 * \return	The number.
 * \note	
 */
//--------------------------------------------------------------------------------
- (long) convertStringToLong: (char*) aString withLength: (long) aLength
{
	char 	*tmpString;
	long	retVal = -32767;
	
	tmpString = [ self findNumber: aString withLength: aLength ];
	if ( tmpString )
	{
		retVal = atol( tmpString );	
	}
	return( retVal );
}

//--------------------------------------------------------------------------------
/*!\method  findNumber 
 * \brief	This routine searches for the number in a returned string from a GPIB
 *			device.
 * \param	aString		- The string to search.
 * \param	aLength		- The length of the string.
 * \return	Returns a pointer to the character in aString where number starts.
 * \note	This routine can handle a full return or just a number return.
 */
//--------------------------------------------------------------------------------
- (char*) findNumber: (char*) aString withLength: (long) aLength
{
	short i = 0;
	short j = 0;
	
    // First check if beginning character is a letter or punctuation.  In this
    // Case the number is at the end. 
	if ( isalpha( *aString ) || ispunct( *aString ) )
	{
		for( i = 0; i < aLength; i++ )
		{
			if ( isspace( aString[ i ] ) ) break;
		}
        
		for ( j = i; i < aLength; j++ )
		{
			if ( isdigit( aString[ j ] ) || aString[ j ] == '-' || aString[ j ] == '+' 
				|| aString[ j ] == '.' ) break;
		}
	}
    
    // If there was no number return 'null
	if ( j == aLength )
	{
		return ( ( char * )( 0 ) );
	}	
	return( &aString[ j ] );
}

//--------------------------------------------------------------------------------
/*!\method  identifier  
 * \brief	Returns a string that denotes an indentifier that can be used in some
 *			types of table displays.
 * \return	A string that contains the primary address.
 * \note	
 */
//--------------------------------------------------------------------------------
- (NSString*) identifier
{
	return [NSString stringWithFormat:@"GPIB %d",mPrimaryAddress];
}
#pragma mark ¥¥¥Archival
static NSString *ORGpibPrimaryAddress			= @"ORGpib Primary Address";
static NSString *ORGpibSecondaryAddress			= @"ORGpib Secondary Address";

//--------------------------------------------------------------------------------
/*!\method  initWithCoder  
 * \brief	Initialize object using archived settings.
 * \param	aDecoder			- Object used for getting archived internal parameters.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) initWithCoder: (NSCoder*) aDecoder
{
    self = [ super initWithCoder: aDecoder ];
    
    [[ self undoManager ] disableUndoRegistration ];
    
    [ self setPrimaryAddress: [ aDecoder decodeIntForKey: ORGpibPrimaryAddress ]]; 
    [ self setSecondaryAddress: [ aDecoder decodeIntForKey: ORGpibSecondaryAddress ]];
    
    [[ self undoManager ] enableUndoRegistration];
    
    // Attempt to connect the device.
    //    [ self connect ];
    return self;
}


//--------------------------------------------------------------------------------
/*!\method  encodeWithCoder  
 * \brief	Save the internal settings to the archive.
 * \param	anEncoder			- Object used for encoding.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) encodeWithCoder: (NSCoder*) anEncoder
{
    [ super encodeWithCoder: anEncoder ];
    [ anEncoder encodeInt: mPrimaryAddress forKey: ORGpibPrimaryAddress ];
    [ anEncoder encodeInt: mSecondaryAddress forKey: ORGpibSecondaryAddress ];
}

- (void) addObjectInfoToArray:(NSMutableArray*)anArray
{
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	if([self respondsToSelector:@selector(addParametersToDictionary:)]){
		[self addParametersToDictionary:dictionary];
	}
	if([dictionary count]){
		[anArray addObject:dictionary];
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithInt:mPrimaryAddress] forKey:@"primaryAddress"];
    [objDictionary setObject:[NSNumber numberWithInt:mSecondaryAddress] forKey:@"secondaryAddress"];
    [dictionary setObject:objDictionary forKey:[self identifier]];
    
    return objDictionary;
}

@end

