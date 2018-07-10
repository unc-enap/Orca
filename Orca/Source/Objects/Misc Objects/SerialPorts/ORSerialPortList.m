//
//  ORSerialPortList.m
//  ORCA
//
//  Created by Mark Howe on Mon Feb 10 2003.
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

//  Modified from ORSerialPortList.m by Andreas Mayer


#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORStandardEnumerator.h"

#include <termios.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#import "SynthesizeSingleton.h"

NSString* ORSerialPortListChanged = @"ORSerialPortListChanged";

@implementation ORSerialPortList

SYNTHESIZE_SINGLETON_FOR_ORCLASS(SerialPortList);

+ (NSEnumerator*) portEnumerator
{
	return [[[ORStandardEnumerator alloc] initWithCollection:[ORSerialPortList sharedSerialPortList] countSelector:@selector(count) objectAtIndexSelector:@selector(objectAtIndex:)] autorelease];
}

-(kern_return_t)findSerialPorts:(io_iterator_t*) matchingServices
{
    
    mach_port_t			masterPort;

    kern_return_t kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult){
        //printf("IOMasterPort returned %d\n", kernResult);
    }
        
    // Serial devices are instances of class IOSerialBSDClient
    CFMutableDictionaryRef classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch == NULL){
        //printf("IOServiceMatching returned a NULL dictionary.\n");
    }
    else
        CFDictionarySetValue(classesToMatch,
                            CFSTR(kIOSerialBSDTypeKey),
                            CFSTR(kIOSerialBSDAllTypes));
    
    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, matchingServices);    
    if (KERN_SUCCESS != kernResult){
        //printf("IOServiceGetMatchingServices returned %d\n", kernResult);
    }
        
    return kernResult;
}


- (ORSerialPort*) getNextSerialPort:(io_iterator_t)serialPortIterator
{
    io_object_t		serialService;
    ORSerialPort*   aSerialPort = nil;
    
    if ((serialService = IOIteratorNext(serialPortIterator))){
		
        CFTypeRef modemNameAsCFString = IORegistryEntryCreateCFProperty(serialService,
                                                              CFSTR(kIOTTYDeviceKey),
                                                              kCFAllocatorDefault,
                                                              0);
        CFTypeRef bsdPathAsCFString = IORegistryEntryCreateCFProperty(serialService,
                                                            CFSTR(kIOCalloutDeviceKey),
                                                            kCFAllocatorDefault,
                                                            0);
        if (modemNameAsCFString && bsdPathAsCFString) {
			aSerialPort = [[[ORSerialPort alloc] init:(NSString*) bsdPathAsCFString withName:(NSString*) modemNameAsCFString] autorelease];
		}

        if (modemNameAsCFString)CFRelease(modemNameAsCFString);

        if (bsdPathAsCFString)CFRelease(bsdPathAsCFString);
    
        (void) IOObjectRelease(serialService);
        // We have sucked this service dry of information so release it now.
        return aSerialPort;
    }
    else return NULL;
}

- (id)init
{
 	self = [super init];
    [self updatePortList];
    return self;
}

- (void) updatePortList
{
    if(!portList)    portList = [[NSMutableArray array] retain];
    io_iterator_t    serialPortIterator;
    [self findSerialPorts:&serialPortIterator];
    ORSerialPort* serialPort;
    NSMutableArray* newList = [NSMutableArray array];

    do {
        serialPort = [self getNextSerialPort:serialPortIterator];
        if (serialPort != NULL) {
            if( [[serialPort name] rangeOfString:@"Bluetooth"].location == NSNotFound &&
                [[serialPort name] rangeOfString:@"KeySerial"].location == NSNotFound ){
                [newList addObject:serialPort];
            }
        }
    } while (serialPort != NULL);
    IOObjectRelease(serialPortIterator);    // Release the iterator.
    
    BOOL anyChanges = NO;
    //add any new ports to the old list
    for(ORSerialPort* portNew in newList){
        NSString* nameNew = [portNew name];
        BOOL inList = NO;
        for(ORSerialPort* portOld in portList ){
            NSString* nameOld = [portOld name];
            if([nameOld isEqualToString:nameNew]){
                inList = YES;
                break;
            }
        }
        if(!inList){
            [portList addObject:portNew];
            anyChanges = YES;
        }
    }
    
    //anything in the old list that is missing from the new list, remove it
    NSMutableArray* portsToDelete = [NSMutableArray array];
    for(ORSerialPort* portOld in portList ){
        NSString* nameOld = [portOld name];
        BOOL inList = NO;
        for(ORSerialPort* portNew in newList){
            NSString* nameNew = [portNew name];
            if([nameOld isEqualToString:nameNew]){
                inList = YES;
            }
        }
        if(!inList){
            [portsToDelete addObject:portOld];
            anyChanges = YES;
        }
    }
    [portList removeObjectsInArray:portsToDelete];
    if(anyChanges){
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSerialPortListChanged object:self userInfo:nil];
    }
}

- (NSArray*) portList;
{
    [self updatePortList];
    return [[portList copy] autorelease]; //return copy, since the list could change at anytime
}

- (NSUInteger) count
{
    return [portList count];
}

- (ORSerialPort*) objectAtIndex:(NSUInteger)index
{
    if(index<[portList count]) return [portList objectAtIndex:index];
    else return nil;
}

- (ORSerialPort*) objectWithName:(NSString*) name
{
	for (ORSerialPort* aPort in portList){
        if ([[aPort name] isEqualToString:name]){
            return aPort;
		}
    }
	return nil;
}

- (NSInteger) indexOfObjectWithName:(NSString*) name
{
    NSUInteger i = 0;
    for (ORSerialPort* aPort in portList){
        if ([[aPort name] isEqualToString:name]){
            return i;
        }
        else i++;
    }
    return -1;
}

#pragma mark ¥¥¥Port Aliases
- (NSString*) aliaseForPort:(ORSerialPort*)aPort
{
	return [self aliaseForPortName:[aPort name]];
}

- (NSString*) aliaseForPortName:(NSString*)aPortName
{
	if(!aliaseDictionary)return aPortName;
	NSString* theAliase = [aliaseDictionary objectForKey:aPortName];
	if(!theAliase)return aPortName;
	else return theAliase;
}

- (void) assignAliase:(NSString*)anAliase forPort:(ORSerialPort*)aPort
{
	if(!aliaseDictionary)aliaseDictionary = [[NSMutableDictionary dictionary] retain];
	NSString* thePortName = [aPort name];
	[aliaseDictionary setObject:anAliase forKey:thePortName];
}

@end
