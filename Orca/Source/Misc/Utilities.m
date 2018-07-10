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


#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
#import <objc/objc-class.h>
#import <objc/Protocol.h>
#else
#import "objc/runtime.h"
#endif
#include <IOKit/IOKitLib.h>
#include <IOKit/network/IOEthernetInterface.h>
#include <IOKit/network/IONetworkInterface.h>
#include <IOKit/network/IOEthernetController.h>
#import <SystemConfiguration/SystemConfiguration.h>

NSString* fullVersion()
{
	CFBundleRef localInfoBundle = CFBundleGetMainBundle();
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    
    CFBundleGetLocalInfoDictionary( localInfoBundle );
	
	NSString* versionString = [infoDictionary objectForKey:@"CFBundleVersion"];
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* svnVersionPath = [[NSBundle mainBundle] pathForResource:@"svnversion"ofType:nil];
	NSMutableString* svnVersion = [NSMutableString stringWithString:@""];
	if([fm fileExistsAtPath:svnVersionPath]){
		svnVersion = [NSMutableString stringWithContentsOfFile:svnVersionPath encoding:NSASCIIStringEncoding error:nil];
		if([svnVersion hasSuffix:@"\n"]){
			[svnVersion replaceCharactersInRange:NSMakeRange([svnVersion length]-1, 1) withString:@""];
		}
	}
	return [NSString stringWithFormat:@"%@%@%@",versionString,[svnVersion length]?@":":@"",[svnVersion length]?svnVersion:@""];
}

NSString* appPath()
{
	NSArray* args = [[NSProcessInfo processInfo] arguments];
	if([args count]){
		NSString* appPath = [args objectAtIndex:0];
		NSRange r = [appPath rangeOfString:@".app"];
		if(r.location != NSNotFound){
			return [appPath substringToIndex:r.location];
		}
		else return nil;
	}
	else return nil;
}

NSString* launchPath()
{
	NSArray* args = [[NSProcessInfo processInfo] arguments];
	if([args count]){
		return [args objectAtIndex:0];
	}
	else return nil;
}

//-----------------------------------------------------------------------------
/*!\func	convertTimeCharToLong
 * \brief	Converts a date/time string in standard format to a long.
 * \param	aTime			- Pointer to char holding time as characters
 * \note 	Long is assumed to use time_t format. aTime is assumed to be in the format
 *          yyyy/mm/dd hh:mm:ss given mm: 1-12, dd: 1-31, and hh as 0-24.
 *  		asTime has to be 20 chars wide.
 */
//-----------------------------------------------------------------------------
long 	convertTimeCharToLong( char* aTime )
{
// set the tm structure using the character format
    NSString*	timeStr;
	struct tm	timeStruct;
    char		tmpStorage[ 16 ];
    
    timeStr = [ NSString stringWithCString: aTime  encoding:NSASCIIStringEncoding];
	
	[[timeStr substringWithRange:NSMakeRange( 0, 4 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
	timeStruct.tm_year = atoi( tmpStorage ) - 1900;
    
	[[timeStr substringWithRange:NSMakeRange( 5,2 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
	timeStruct.tm_mon = atoi( tmpStorage );
    
	[[timeStr substringWithRange:NSMakeRange( 8,2 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
    timeStruct.tm_mday = atoi( tmpStorage );

	[[timeStr substringWithRange:NSMakeRange( 11,2 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
	timeStruct.tm_hour = atoi( tmpStorage );

	[[timeStr substringWithRange:NSMakeRange( 14,2 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
	timeStruct.tm_min = atoi( tmpStorage );

	[[timeStr substringWithRange:NSMakeRange( 17,2 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
	timeStruct.tm_sec = atoi( tmpStorage );	
	
	return( mktime( &timeStruct ) );	

}

//-----------------------------------------------------------------------------
/*!\func 	convertTimeLongToChar
 * \brief	Convert a standard unix time to the standard char format.
 * \note 	Long is assumed to use time_t format.  psTime will be in the format
 *        	yyyy/mm/dd hh:mm:ss given mm: 1-12, dd: 1-31, and hh as 0-24.
 *		  	psTime has to be 20 chars wide.
 */
//-----------------------------------------------------------------------------
void convertTimeLongToChar( time_t anTime, char *asTime )
{
	struct tm *timeStruct = localtime( &anTime );
	strftime( asTime, 20, "%Y/%m/%d %H:%M:%S", timeStruct ); 
}

//-----------------------------------------------------------------------------
/*!\func 	ORKeyFromId
 * \brief	Returns an NSNumber that contains an Objects pointer value. Useful 
 *			when storing an obj keyed to itself in a dictionary.
 */
//-----------------------------------------------------------------------------
id		ORKeyFromId(id anObj)
{
	return [NSNumber numberWithLong:(long)anObj];
}

int random_range(int lowest_number, int highest_number)
{
    if(lowest_number > highest_number){
		int temp = lowest_number;
		lowest_number = highest_number;
		highest_number = temp;
	}

    int range = highest_number - lowest_number + 1;
	return rand() % range + lowest_number;
   // return lowest_number + (int)(range * rand()/(RAND_MAX + 1.0));
}

//-----------------------------------------------------------------------------
/*!\func 	rootService
 * \brief	Returns the service associated with the master IO port.
 */
//-----------------------------------------------------------------------------
io_service_t rootService()
{
	static io_service_t gRootService = 0 ;

	if (!gRootService)
	{
		// get registry root
		mach_port_t		masterPort ;
		IOReturn		err = IOMasterPort( MACH_PORT_NULL, & masterPort ) ;
		if ( err )
			[ NSException raise:@"" format:@"%s %u: couldn't get master port", __FILE__, __LINE__ ] ;

		gRootService 	= IORegistryGetRootEntry( masterPort );
	}

	return gRootService ;
}

NSString* listMethods(Class aClass)
{
	return listMethodWithOptions(aClass,YES,YES); 
}

NSString* listMethodWithOptions(Class aClass,BOOL verbose,BOOL includeSuperClass)
{
    return listMethodWithExtendedOptions(aClass,verbose,includeSuperClass,YES);
}

NSString* listMethodWithExtendedOptions(Class aClass,BOOL verbose,BOOL includeSuperClass,BOOL sort)
{
    NSMutableString* resultString = [NSMutableString stringWithString:@""];

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
    struct objc_class *class = aClass;
	if(!aClass)return @"Class Not Found!\n";
    const char *name = class->name;
    int k;
    void *iterator = 0;
    struct objc_method_list *mlist;
    
	if(verbose){
		[resultString appendFormat: @"Deconstructing class %s, version %d\n",name, class->version];
		[resultString appendFormat: @"%s size: %d\n", name,class->instance_size];
		if (class->ivars == nil) [resultString appendFormat: @"%s has no instance variables\n", name];
		else {
			[resultString appendFormat: @"%s has %d ivar%c\n", name, class->ivars->ivar_count, ((class->ivars->ivar_count == 1)?' ':'s')];
			for (k = 0; k < class->ivars->ivar_count; k++){
				[resultString appendFormat: @"%s ivar #%d: %s\n", name, k, class->ivars->ivar_list[k].ivar_name];
			}
		}
	}
    mlist = class_nextMethodList(aClass, &iterator);
    if (mlist == nil && verbose) [resultString appendFormat: @"%s has no methods\n", name];
    else do {
        for (k = 0; k < mlist->method_count; k++){
			if(verbose) [resultString appendFormat: @"%s implements %@\n", name, NSStringFromSelector(mlist->method_list[k].method_name)];
			else [resultString appendFormat: @"%@\n", NSStringFromSelector(mlist->method_list[k].method_name)];
        }
    } while ( mlist = class_nextMethodList(aClass, &iterator) );
    
	if(includeSuperClass){
		if (class->super_class == nil && verbose) [resultString appendFormat: @"%s has no superclass\n", name];
		else {
			if(verbose)[resultString appendFormat: @"\n%s superclass: %s\n", name, class->super_class->name];
			[resultString appendString: listMethodWithOptions( class->super_class,verbose,includeSuperClass)];
		}
	 }

 #else
	const char *name = class_getName(aClass);
	if(!name)return @"Class Not Found!\n";
	unsigned int methodCount=0;
	Method* methods = class_copyMethodList(aClass, &methodCount);
	int i;
	NSMutableArray* methodNames = [NSMutableArray array];
	for(i=0;i<methodCount;i++){
		NSString* aName = NSStringFromSelector(method_getName(methods[i]));
		NSArray* parts = [aName componentsSeparatedByString:@":"];
		NSMethodSignature* sig = [aClass instanceMethodSignatureForSelector:method_getName(methods[i])];
		int n = [sig numberOfArguments];
		int j;
		NSString* finalName = @"";
		if(n==2){
			finalName = [finalName stringByAppendingFormat:@"%@",[parts objectAtIndex:0]];
		}
		else {
			for(j=0;j<n-2;j++){
				const char* theType = decodeType([sig getArgumentTypeAtIndex:j+2]);
				finalName = [finalName stringByAppendingFormat:@"%@:(%s) ",[parts objectAtIndex:j],theType];
			}
		}
		if([finalName length] > 1)[methodNames addObject:finalName];
	}
	free(methods);
	if(sort)[methodNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
	[resultString appendString:[methodNames componentsJoinedByString:@"\n"]];
	if(includeSuperClass){
		Class superClass = class_getSuperclass(aClass);
		NSString* superClassName = [NSString stringWithUTF8String:class_getName(superClass)];
		if (superClass == nil && verbose) {
			[resultString appendFormat: @"%s has no superclass\n", name];
		}
		else {
			if(![superClassName hasPrefix:@"NS"]){
				if(verbose)[resultString appendFormat: @"\n-------------------\n%s superclass: %@\n", name, superClassName];
					[resultString appendString: listMethodWithOptions( superClass,verbose,includeSuperClass)];
				}
		}
	 }

#endif

	return resultString;
}

NSString* methodsInCommonSection(id anObj)
{
    NSString* allAsString = listMethodWithExtendedOptions([anObj class], NO, NO, NO);
    NSArray* listArray = [allAsString componentsSeparatedByString:@"\n"];
 	NSMutableArray* methodNames = [NSMutableArray array];
    BOOL inCommonSection = NO;
//MAC_OS_X_VERSION_10_8 is for e.g. 10.6 not defined ... -tb-
#ifndef MAC_OS_X_VERSION_10_8
    for (id aMethod in [listArray reverseObjectEnumerator]){
#else
  #if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8
    for (id aMethod in [listArray objectEnumerator]){
  #else
    for (id aMethod in [listArray reverseObjectEnumerator]){
  #endif
#endif
    
        if( [aMethod hasPrefix: @"commonScriptMethodSectionBegin"] ){
            inCommonSection = YES;
            continue;
        }
        else if( [aMethod hasPrefix: @"commonScriptMethodSectionEnd"] )break;
        else if( inCommonSection){
            [methodNames addObject:aMethod];
        }
    }
    return [methodNames componentsJoinedByString:@"\n"];
}


NSString* hexToString(unsigned long aHexValue)
{
	return [NSString stringWithFormat:@"%lx",aHexValue];
}

const char* decodeType(const char* aType)
{
	if(!strcmp(aType,"@"))return "id";
	else if(!strcmp(aType,"c"))return "char";
	else if(!strcmp(aType,"i"))return "int";
	else if(!strcmp(aType,"s"))return "short";
	else if(!strcmp(aType,"l"))return "long";
	else if(!strcmp(aType,"q"))return "long long";
	else if(!strcmp(aType,"C"))return "unsigned char";
	else if(!strcmp(aType,"I"))return "unsigned int";
	else if(!strcmp(aType,"S"))return "unsigned short";
	else if(!strcmp(aType,"L"))return "unsigned long";
	else if(!strcmp(aType,"Q"))return "unsigned long long";
	else if(!strcmp(aType,"f"))return "float";
	else if(!strcmp(aType,"d"))return "double";
	else if(!strcmp(aType,"B"))return "bool";
	else if(!strcmp(aType,"v"))return "void";
	else if(!strcmp(aType,"*"))return "char *";
	else if(!strcmp(aType,"#"))return "Class";
	else if(!strcmp(aType,":"))return "SEL";
	else return aType;
	
}

NSString* commonScriptMethodsByClass(Class aClass,BOOL includeSuperClass)
{
	return commonScriptMethodsByObj([[[aClass alloc] init] autorelease],includeSuperClass);
	
}	

NSString* commonScriptMethodsByObj(id anObj,BOOL includeSuperClass)
{
	NSMutableString* resultString = [NSMutableString stringWithString:@""];
	if([anObj respondsToSelector:@selector(commonScriptMethods)]){
		NSString* list = [[[anObj commonScriptMethods] copy] autorelease];
		[resultString appendString:list];
	}
	else [resultString appendString:@"No common methods defined\n"];
	
	if(includeSuperClass){
		if ([anObj superclass]==nil) [resultString appendFormat: @"%@ has no superclass\n", [anObj className]];
		else {
            id theSuperClass = [anObj superclass];
			NSString* superClassName = [theSuperClass className];
			if(![superClassName hasPrefix:@"NS"]){
				[resultString appendFormat: @"\n-------------------\n%@ superclass: %@\n", [anObj className], [anObj superclass]];
				[resultString appendString: commonScriptMethodsByObj( [anObj superclass],includeSuperClass)];
			}
		}
	}
	
	return resultString;
}


NSString* computerName()
{
	//return  [(NSString*)CSCopyMachineName() autorelease];
    CFStringRef temp = SCDynamicStoreCopyComputerName(NULL,NULL);
    NSString*   name = [NSString stringWithString:(NSString *)temp];
    CFRelease(temp);
    return name;
}

NSString* macAddress()
{
	kern_return_t	kernResult = KERN_SUCCESS; // on PowerPC this is an int (4 bytes)
	/*
	 *	error number layout as follows (see mach/error.h and IOKit/IOReturn.h):
	 *
	 *	hi		 		       lo
	 *	| system(6) | subsystem(12) | code(14) |
	 */
	
	io_iterator_t	intfIterator;
	UInt8			MACAddress[kIOEthernetAddressSize];
	
	kernResult = findEthernetInterfaces(&intfIterator);
	NSString* theResult = @"";
	if (KERN_SUCCESS != kernResult) {
		NSLog(@"FindEthernetInterfaces returned 0x%08x\n", kernResult);
	}
	else {
		kernResult = getMACAddress(intfIterator, MACAddress, sizeof(MACAddress));
		
		if (KERN_SUCCESS != kernResult) {
			NSLog(@"GetMACAddress returned 0x%08x\n", kernResult);
		}
		else {
			//NSLog(@"This system's built-in MAC address is %02x:%02x:%02x:%02x:%02x:%02x.\n",
			//	   MACAddress[0], MACAddress[1], MACAddress[2], MACAddress[3], MACAddress[4], MACAddress[5]);
			theResult = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",
						 MACAddress[0], MACAddress[1], MACAddress[2], MACAddress[3], MACAddress[4], MACAddress[5]];
		}
	}
	
	(void) IOObjectRelease(intfIterator);	// Release the iterator.
	return theResult;
}


#pragma mark ***private
// Given an iterator across a set of Ethernet interfaces, return the MAC address of the last one.
// If no interfaces are found the MAC address is set to an empty string.
// In this sample the iterator should contain just the primary interface.
kern_return_t getMACAddress(io_iterator_t intfIterator, UInt8 *MACAddress, UInt8 bufferSize)
{
    io_object_t		intfService;
    io_object_t		controllerService;
    kern_return_t	kernResult = KERN_FAILURE;
    
    // Make sure the caller provided enough buffer space. Protect against buffer overflow problems.
	if (bufferSize < kIOEthernetAddressSize) {
		return kernResult;
	}
	
	// Initialize the returned address
    bzero(MACAddress, bufferSize);
    
    // IOIteratorNext retains the returned object, so release it when we're done with it.
    while ((intfService = IOIteratorNext(intfIterator)))
    {
        CFTypeRef	MACAddressAsCFData;        
		
        // IONetworkControllers can't be found directly by the IOServiceGetMatchingServices call, 
        // since they are hardware nubs and do not participate in driver matching. In other words,
        // registerService() is never called on them. So we've found the IONetworkInterface and will 
        // get its parent controller by asking for it specifically.
        
        // IORegistryEntryGetParentEntry retains the returned object, so release it when we're done with it.
        kernResult = IORegistryEntryGetParentEntry(intfService,
												   kIOServicePlane,
												   &controllerService);
		
        if (KERN_SUCCESS != kernResult) {
            NSLog(@"IORegistryEntryGetParentEntry returned 0x%08x\n", kernResult);
        }
        else {
            // Retrieve the MAC address property from the I/O Registry in the form of a CFData
            MACAddressAsCFData = IORegistryEntryCreateCFProperty(controllerService,
																 CFSTR(kIOMACAddress),
																 kCFAllocatorDefault,
																 0);
            if (MACAddressAsCFData) {
                //CFShow(MACAddressAsCFData); // for display purposes only; output goes to stderr
                
                // Get the raw bytes of the MAC address from the CFData
                CFDataGetBytes(MACAddressAsCFData, CFRangeMake(0, kIOEthernetAddressSize), MACAddress);
                CFRelease(MACAddressAsCFData);
            }
			
            // Done with the parent Ethernet controller object so we release it.
            (void) IOObjectRelease(controllerService);
        }
        
        // Done with the Ethernet interface object so we release it.
        (void) IOObjectRelease(intfService);
    }
	
    return kernResult;
}


kern_return_t findEthernetInterfaces(io_iterator_t *matchingServices)
{
    kern_return_t		kernResult; 
    CFMutableDictionaryRef	matchingDict;
    CFMutableDictionaryRef	propertyMatchDict;
    
    // Ethernet interfaces are instances of class kIOEthernetInterfaceClass. 
    // IOServiceMatching is a convenience function to create a dictionary with the key kIOProviderClassKey and 
    // the specified value.
    matchingDict = IOServiceMatching(kIOEthernetInterfaceClass);
	
    // Note that another option here would be:
    // matchingDict = IOBSDMatching("en0");
	
    if (NULL == matchingDict) {
        NSLog(@"IOServiceMatching returned a NULL dictionary.\n");
    }
    else {
        // Each IONetworkInterface object has a Boolean property with the key kIOPrimaryInterface. Only the
        // primary (built-in) interface has this property set to TRUE.
        
        // IOServiceGetMatchingServices uses the default matching criteria defined by IOService. This considers
        // only the following properties plus any family-specific matching in this order of precedence 
        // (see IOService::passiveMatch):
        //
        // kIOProviderClassKey (IOServiceMatching)
        // kIONameMatchKey (IOServiceNameMatching)
        // kIOPropertyMatchKey
        // kIOPathMatchKey
        // kIOMatchedServiceCountKey
        // family-specific matching
        // kIOBSDNameKey (IOBSDNameMatching)
        // kIOLocationMatchKey
        
        // The IONetworkingFamily does not define any family-specific matching. This means that in            
        // order to have IOServiceGetMatchingServices consider the kIOPrimaryInterface property, we must
        // add that property to a separate dictionary and then add that to our matching dictionary
        // specifying kIOPropertyMatchKey.
		
        propertyMatchDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
													  &kCFTypeDictionaryKeyCallBacks,
													  &kCFTypeDictionaryValueCallBacks);
		
        if (NULL == propertyMatchDict) {
            NSLog(@"CFDictionaryCreateMutable returned a NULL dictionary.\n");
        }
        else {
            // Set the value in the dictionary of the property with the given key, or add the key 
            // to the dictionary if it doesn't exist. This call retains the value object passed in.
            CFDictionarySetValue(propertyMatchDict, CFSTR(kIOPrimaryInterface), kCFBooleanTrue); 
            
            // Now add the dictionary containing the matching value for kIOPrimaryInterface to our main
            // matching dictionary. This call will retain propertyMatchDict, so we can release our reference 
            // on propertyMatchDict after adding it to matchingDict.
            CFDictionarySetValue(matchingDict, CFSTR(kIOPropertyMatchKey), propertyMatchDict);
            CFRelease(propertyMatchDict);
        }
    }
    
    // IOServiceGetMatchingServices retains the returned iterator, so release the iterator when we're done with it.
    // IOServiceGetMatchingServices also consumes a reference on the matching dictionary so we don't need to release
    // the dictionary explicitly.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, matchingServices);    
    if (KERN_SUCCESS != kernResult) {
        NSLog(@"IOServiceGetMatchingServices returned 0x%08x\n", kernResult);
    }
	
    return kernResult;
}
static BOOL reportedOnce;
BOOL ORRunAlertPanel(NSString* mainMessage, NSString* msg, NSString* defaultButtonTitle, NSString* alternateButtonTitle,NSString* otherButtonTitle, ...)
{
    if(![NSThread isMainThread] ){
        if(!reportedOnce){
            //Just report this once in case we are in a loop. Programmers can work thru these errors one-by-one
            NSLogColor([NSColor redColor],@"Programmer error: ORRunAlertPanel called from non-main thread\n");
            reportedOnce = YES;
        }
        return NO;
    }
    
    va_list ap;
    va_start(ap, otherButtonTitle);
    BOOL result;
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 //    10.10-specific

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    if(mainMessage)[alert setMessageText:mainMessage];
    [alert setInformativeText:[NSString stringWithFormat:msg parameters:ap]];
    if(defaultButtonTitle)  [alert addButtonWithTitle:defaultButtonTitle];
    if(alternateButtonTitle)[alert addButtonWithTitle:alternateButtonTitle];
    if(otherButtonTitle)    [alert addButtonWithTitle:otherButtonTitle];
    int choice = [alert runModal];
    if(choice == NSAlertFirstButtonReturn)  result = YES;
    else                                    result = NO;
#else
    NSString* s = [NSString stringWithFormat:msg parameters:ap];
    int choice = NSRunAlertPanel(mainMessage,@"%@",defaultButtonTitle,alternateButtonTitle,otherButtonTitle,s);
    if(choice == NSAlertDefaultReturn) result = YES;
    else                               result = NO;
#endif
 
     va_end(ap);
    return result;
}
        
