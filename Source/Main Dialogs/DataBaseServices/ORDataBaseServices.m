//----------------------------------------------------------
//  ORDataBaseServices.h
//
//  Created by Mark Howe on Wed Mar 29, 2006.
//  Copyright  © 2002 CENPA. All rights reserved.
//----------------------------------------------------------

#pragma mark ¥¥¥Imported Files
#import "ORDataBaseServices.h"
#import "StatusLog.h"
#import "ORSqlConnection.h"
#import "ORDbService.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "netinet6/in6.h"
#import "arpa/inet.h"

static ORDataBaseServices* netServices = nil;

NSString* ORDataBaseServicesChangedNotification = @"ORDataBaseServicesChangedNotification";

@implementation ORDataBaseServices

#pragma mark ¥¥¥Initialization

+ (id) sharedInstance
{
	if(!netServices){
		netServices = [[ORDataBaseServices alloc] init];
	}
	return netServices;
}

#pragma mark ¥¥¥Accessors
- (id) init
{
    self = [super init];
	
    foundServices		= [[NSMutableArray array] retain];
    browser				= [[NSNetServiceBrowser alloc] init];
    [browser setDelegate:self];
	NSLog(@"Browsing for data base services.\n");
    [browser searchForServicesOfType:@"_orcasqlserver._tcp" inDomain:@"local."];

    return self;
}


- (void) dealloc
{
	[browser stop];
	[browser release];
	[foundServices release];
	[super dealloc];
}

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥NetServiceBrowser Delegate Methods
- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
            didFindService:(NSNetService *)aNetService 
                moreComing:(BOOL)moreComing 
{
	NSLog(@"Service Found: %@\n",[aNetService name]);
    int serviceIndex=0;
    for (serviceIndex=[foundServices count]-1;serviceIndex>=0;serviceIndex--) {
        NSMutableDictionary *entryOfLoop=[foundServices objectAtIndex:serviceIndex];
        NSNetService   *netServiceOfLoop=[entryOfLoop objectForKey:@"service"];
        if (([netServiceOfLoop isEqualTo:aNetService])) {
            [entryOfLoop setObject:[NSNumber numberWithInt:[[entryOfLoop objectForKey:@"count"] intValue]+1] 
                            forKey:@"count"];
            break;
        }
    }
    
    // Did not find NetService in Array?
    if (serviceIndex<0) {
        [aNetService setDelegate:self];
		NSLog(@"Starting resolve process for %@\n",[aNetService name]);
        [aNetService resolveWithTimeout:30];
        // Only resolve for 30 seconds, to not harm the network more than necessary.
        // "Normally" you would resolve until you did connect and start resolving just 
        // before you want to connect, but as we only browse the
        // network without connecting, we limit the resolve time
    
        // Since we don't know if NSNetService is observable, 
        // we copy the values that we're displaying into the dictionary
        NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
        [dictionary setObject:aNetService                forKey:@"service"];
        [dictionary setObject:[aNetService name]         forKey:@"name"];
        [dictionary setObject:[aNetService type]         forKey:@"type"];
        [dictionary setObject:[aNetService domain]       forKey:@"domain"];
        [dictionary setObject:[NSNumber numberWithInt:1] forKey:@"count"];
    
        NSIndexSet *set=[NSIndexSet indexSetWithIndex:[foundServices count]];
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:set forKey:@"foundNetServices"];
        [foundServices addObject:dictionary];
        [self  didChange:NSKeyValueChangeInsertion valuesAtIndexes:set forKey:@"foundNetServices"];
    }
	
	if(!moreComing){
		[[NSNotificationCenter defaultCenter] postNotificationName:ORDataBaseServicesChangedNotification object:self];
	}
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
          didRemoveService:(NSNetService *)aNetService 
                moreComing:(BOOL)moreComing 
{
	int serviceIndex;
    for (serviceIndex=[foundServices count]-1; serviceIndex>=0; serviceIndex--) {
        NSMutableDictionary *entryOfLoop=[foundServices objectAtIndex:serviceIndex];
        NSNetService *netServiceOfLoop=[entryOfLoop objectForKey:@"service"];
        // Keep in mind that the NSNetService objects that we receive via the 
        // delegate methods of NSNetServiceBrowsers may be equal to each other
        // but never are identical / the same objects
        if (([netServiceOfLoop isEqualTo:aNetService])) {
            if ([[[foundServices objectAtIndex:serviceIndex] objectForKey:@"count"] intValue]==1) {
                // Keep in mind that you get potentially one NSNetService reported for every interface.
                // I.e. you should only remove the service in your application if your count is at zero again
                // otherwise you remove services that are still reachable.
                [netServiceOfLoop stop];
                NSIndexSet *set=[NSIndexSet indexSetWithIndex:serviceIndex];
                [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
				NSLog(@"Service %@ at:%@ removed.\n",[aNetService name],[[foundServices objectAtIndex:serviceIndex] objectForKey:@"hostName"]);
                [foundServices removeObjectAtIndex:serviceIndex];

                [self  didChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
            } 
			else {
                [entryOfLoop setObject:[NSNumber numberWithInt:[[entryOfLoop objectForKey:@"count"] intValue]-1] 
                                forKey:@"count"];
            }
            break;
        }
    }
	if(!moreComing){
		[[NSNotificationCenter defaultCenter] postNotificationName:ORDataBaseServicesChangedNotification object:self];
	}
}

#pragma mark ¥¥¥NSNetService delegate methods

- (void) netServiceDidResolveAddress:(NSNetService *)aNetService  
{
    int netServiceIndex;
    for (netServiceIndex=[foundServices count]-1; netServiceIndex>=0; netServiceIndex--) {
        NSMutableDictionary *entryOfLoop=[foundServices objectAtIndex:netServiceIndex];
        NSNetService   *netServiceOfLoop=[entryOfLoop objectForKey:@"service"];
        if (([netServiceOfLoop isEqualTo:aNetService])) {
            // Loop over the new addresses and translate them into strings
            NSArray *addresses=[aNetService addresses];
            int index=0;
            for (index=0;index<[addresses count];index++) {
                struct sockaddr *socketAddress=(struct sockaddr *)[[addresses objectAtIndex:index] bytes];
                // IPv6 Addresses are "FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF" at max, which is 40 bytes (0-terminated)
                // IPv4 Addresses are "255.255.255.255" at max which is smaller
                char stringBuffer[40];
                NSString *addressAsString=@"unresolved";
				struct	in_addr inAddr = ((struct sockaddr_in *)socketAddress)->sin_addr;
                if (socketAddress->sa_family == AF_INET) {
                    if (inet_ntop(AF_INET,&inAddr,stringBuffer,40)) {
                        addressAsString=[NSString stringWithUTF8String:stringBuffer];
                    } 
					else {
                        addressAsString=@"IPv4 un-ntopable";
                    }
                    int port = ((struct sockaddr_in *)socketAddress)->sin_port;
                    addressAsString=[addressAsString stringByAppendingFormat:@":%d",port];
					[entryOfLoop setObject:addressAsString forKey:@"hostName"];
					NSLog(@"Address of %@ resolved to:%@\n",[aNetService name],addressAsString);
                } 
            }
            // Note that the TXTRecordData is also a result of an resolve,
            // it is not available when you first get the NSNetService from the NSNetServiceBrowser
            if ([[aNetService TXTRecordData] length]>0) {
                NSDictionary* txtRecordDictionary =[NSNetService dictionaryFromTXTRecordData:[aNetService TXTRecordData]];
                [entryOfLoop setObject:txtRecordDictionary forKey:@"protocolSpecificInformation"];
            }
            break;
        }
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:ORDataBaseServicesChangedNotification object:self];
}

- (void) registerClient:(NSString*)aClientName to:(NSString*)aServiceName
{
    int netServiceIndex;
    for (netServiceIndex=[foundServices count]-1; netServiceIndex>=0; netServiceIndex--) {
        NSMutableDictionary* entryOfLoop	  = [foundServices objectAtIndex:netServiceIndex];
        NSNetService*		 netServiceOfLoop = [entryOfLoop objectForKey:@"service"];
		if([[netServiceOfLoop name] isEqualToString:aServiceName]){
			ORDbService* client = [[ORDbService alloc] initWithService:netServiceOfLoop];
			[entryOfLoop setObject:client forKey:@"client"];
			[entryOfLoop setObject:aClientName forKey:@"clientName"];
			[client release];
			break;
		}
	}
}

- (void) unregisterClient:(NSString*)aClientName from:(NSString*)aServiceName
{
    int netServiceIndex;
    for (netServiceIndex=[foundServices count]-1; netServiceIndex>=0; netServiceIndex--) {
        NSMutableDictionary* entryOfLoop	  = [foundServices objectAtIndex:netServiceIndex];
        NSNetService*		 netServiceOfLoop = [entryOfLoop objectForKey:@"service"];
		if([[netServiceOfLoop name] isEqualToString:aServiceName]){
			ORDbService* aClient = [entryOfLoop objectForKey:@"client"];
			NSString* theName = [entryOfLoop objectForKey:@"clientName"];
			if([theName isEqualToString: aClientName]){
				[aClient disconnect];
				[entryOfLoop removeObjectForKey:@"client"];
				[entryOfLoop removeObjectForKey:@"clientName"];
				break;
			}
		}
	}
}

#pragma mark ¥¥¥DataSource
- (id) serviceAtIndex:(unsigned)index
{
	return [foundServices objectAtIndex:index];
}
- (unsigned) servicesCount
{
	return [foundServices count];
}


@end
