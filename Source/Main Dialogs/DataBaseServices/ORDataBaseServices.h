//----------------------------------------------------------
//  ORDataBaseServices.m
//
//  Created by Mark Howe on Wed Mar 29, 2006.
//  Copyright  © 2002 CENPA. All rights reserved.
//----------------------------------------------------------
#import <Cocoa/Cocoa.h>

@class ORSqlConnection;

@interface ORDataBaseServices : NSObject
{	
    NSNetServiceBrowser* browser;
    NSMutableArray*		 foundServices;
}

+ (id) sharedInstance;

- (id) init;
- (void) dealloc;

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥NetServiceBrowser Delegate Methods
- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
           didFindService:(NSNetService *)aNetService 
               moreComing:(BOOL)moreComing; 

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
         didRemoveService:(NSNetService *)aNetService 
               moreComing:(BOOL)moreComing;
			   
- (void) netServiceDidResolveAddress:(NSNetService *)aNetService ;
- (void) registerClient:(NSString*)aClientName to:(NSString*)aServiceName;
- (void) unregisterClient:(NSString*)aClientName from:(NSString*)aServiceName;

#pragma mark ¥¥¥DataSource
- (id) serviceAtIndex:(unsigned)index;
- (unsigned) servicesCount;
@end

extern NSString* ORDataBaseServicesChangedNotification;
