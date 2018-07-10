//--------------------------------------------------------------------------------
/*!\class	ORGpibDeviceModel
 * \brief	This class handles the setup and connections to the GPIB controller
 *			from the GPIB device.
 * \methods
 *			\li \b 	initWithWindowNibName		- Constructor - Opens correct nib
 *			\li \b 	dealloc						- Unregister messages, cleanup.
 *			\li \b	connect						- Connect device to GPIB.
 *			\li \b	primaryAddressChanged		- Respond when person changes address.
 *			\li \b	secondaryAddressChanged		- Respond when person changes address.
 * \private
 *			\li \b	populatePullDowns			- Populate pulldowns in GUI.
 * \note	
 *			
 * \author	Jan M. Wouters
 * \history	2003-02-16 (jmw) - Original.
 * \history 2003-12-02 (jmw) - Added convertStringToFloat method.
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

#pragma mark ¥¥¥Errors
#define OExceptionGPIBConnectionError	@"GPIBConnectionError"

#pragma mark ¥¥¥Class Definition
@interface ORGpibDeviceModel : OrcaObject {
	@protected
    short		mPrimaryAddress;
    short 		mSecondaryAddress;
    id			mController;			// Cached controller.
    short		mID;					// Constant for scope - specific to series.
    NSString*	mIdentifier;			// Model of GPIB device as returned by device.

    
    @private
    bool		mConnected;				// True if object connected to physical GPIB Device
}

#pragma mark ¥¥¥Initialization
- (void) 		makeConnectors;

#pragma mark ¥¥¥Accessors
- (NSString*)	gpibIdentifier;				// Model of GPIB device as string.
- (BOOL)		isConnected;
- (BOOL)		connected;
- (short)		primaryAddress;
- (void)		setPrimaryAddress: (short) aPrimaryAddress;
- (short)		secondaryAddress;
- (void)		setSecondaryAddress: (short) aSecondaryAddress;

#pragma mark ¥¥¥Actions
- (void)		clearStatusReg;
- (void) 		connect;
- (void)		getID;
- (long)		readFromGPIBDevice: (char*) aData maxLength: (long) aMaxLength;
- (void)		writeToGPIBDevice: (NSString*) aCommand;
- (long)		writeReadGPIBDevice: (NSString*) aCommand 
                               data: (char*) aData
                          maxLength: (long) aMaxLength;
- (void) 		enableEOT: (BOOL) state;
                       
#pragma mark ¥¥¥Support Functions
- (bool)		cacheTheController;
- (id)			getGpibController;
- (double) 		convertStringToDouble: (char*) aString withLength: (long) aLength;
- (float) 		convertStringToFloat: (char*) aString withLength: (long) aLength;
- (long) 		convertStringToLong: (char*) aString withLength: (long) aLength;
- (char*) 		findNumber: (char*) aString withLength: (long) aLength;
- (NSString*)   title;

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addObjectInfoToArray:(NSMutableArray*)anArray;

@end

#pragma mark ¥¥¥Extern Definitions
extern NSString* ORGpibPrimaryAddressChangedNotification;
extern NSString* ORGpibSecondaryAddressChangedNotification;
extern NSString* ORGpibDeviceConnectedNotification;

extern NSString* ORGpibConnection;
extern NSString* ORGpibConnectionToNextDevice;
extern NSString* ORGpibAddress;
extern NSString* ORGpibDeviceConnected;


