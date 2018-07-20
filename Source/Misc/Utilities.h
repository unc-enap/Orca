//--------------------------------------------------------------------------------
/*!\file	Utilities
 * \brief	This class contains useful functions 
 * \functions
 *			\li \b 	convertTimeLongToChar		- Convert standard UNIX time to standard 
 *												  time string.
 *			\li \b	convertTimeCharToLong		- Convert standard time string to UNIX
 *												  time.
 *			\li \b	ORKeyFromId					- convert an obj pointer value into an NSNumber.
 * \note	
 *			
 * \author	Jan M. Wouters
 * \history	2003-05-08 (jmw) - Original.
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

#import <IOKit/IOKitLib.h>

int32_t 	convertTimeCharToLong( char* aTime );
void	convertTimeLongToChar( time_t aTime, char *pTime );
id		ORKeyFromId(id anObj);
int		random_range(int lowest_number, int highest_number);
io_service_t rootService(void);
NSString* commonScriptMethodsByClass(Class aClass,BOOL includeSuperClass);
NSString* commonScriptMethodsByObj(id anObj,BOOL includeSuperClass);
NSString* methodsInCommonSection(id anObj);
NSString* listMethods(Class aClass);
NSString* listMethodWithOptions(Class aClass,BOOL verbose,BOOL includeSuperClass);
NSString* listMethodWithExtendedOptions(Class aClass,BOOL verbose,BOOL includeSuperClass,BOOL sort);
NSString* hexToString(uint32_t aHexValue);
const char* decodeType(const char* aType);
NSString* macAddress(void);
NSString* computerName(void);
NSString* appPath(void);
NSString* launchPath(void);
NSString* fullVersion(void);

//alert panels for 10.10 and before
BOOL ORRunAlertPanel(NSString* mainMessage, NSString* informativeMessage, NSString* defaultButtonTitle, NSString* alternateButtonTitle, NSString* otherButtonTitle, ...);

#pragma mark ***private
kern_return_t findEthernetInterfaces(io_iterator_t *matchingServices);
kern_return_t getMACAddress(io_iterator_t intfIterator, uint8 *MACAddress, uint8 bufferSize);

@interface NSObject (scriptExtensions)
- (NSString*) commonScriptMethods;
@end
