//
//  xml_backend.m
//  xmlrpc-testing
//
//  Created by Edward Leming on 10/02/2016.
//  Copyright (c) 2016 Edward Leming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "wpxmlrpc.h"
#import "XmlrpcClient.h"

@implementation XmlrpcClient

@synthesize host = _host;
@synthesize port = _port;

-(id)init
{
    self = [self initWithHostName:@"" withPort:@"-1"];
    return self;
}
- (void) dealloc
{
    [_host release];
    [_port release];
    [super dealloc];
}
-(id)initWithHostName:(NSString *)passedHost withPort:(NSString *)passedPort
{
    self = [super init];
    
    if(self){
        self.host = passedHost;
        self.port = passedPort;
        _timeout = 5; //5s default timeout
    }
    return self;
}

-(void)setTimeout:(float)timeout
{
    _timeout = timeout;
}

-(id)getResult
{
    if(_response == nil){
        NSLog(@"WARNING: XMLRPC response is nil");
    }
    return _response;
}

-(id)command:(NSString *)fmt
{
    return [self command:(NSString *)fmt withArgs:nil];
}

-(id)command:(NSString *)fmt withArgs:args
{
    /*
     * Encodes a command with the xmlrpc protocol and pipes it up to the
     * http://host:port address using the NSURLConnection class. The 
     * NSURLConnection communication can occur either syncronously or 
     * asyncronously, dependent on the BOOL asyncFlag property of
     * the class instance.
    */

    NSString *URLString = [NSString stringWithFormat:@"http://%@:%@", self.host, self.port];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:URL] autorelease];

    
    request.timeoutInterval = _timeout;
    [request setHTTPMethod:@"POST"];
    
    WPXMLRPCEncoder *encoder = [[[WPXMLRPCEncoder alloc] initWithMethod:fmt andParameters:args]autorelease];
    [request setHTTPBody:[encoder dataEncodedWithError:nil]];
    
    //Make sure private data variables are set to nil an make request.
    _responseData = nil;
    _response = nil;
    
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                            returningResponse:&response
                                                        error:&error];
    if(error){
        NSException *excep = [NSException exceptionWithName:@"XmlrpcClient"
                                                     reason:[error localizedDescription]
                                                   userInfo:nil];
        [excep raise];
    }

    WPXMLRPCDecoder *decoder = [[[WPXMLRPCDecoder alloc] initWithData:data] autorelease];
    
    if ([decoder isFault]) {
        NSException *excep = [NSException exceptionWithName:@"XmlrpcClient"
                                                     reason:[decoder faultString]
                                                   userInfo: nil];
        [excep raise];
    } else {
        _response = [decoder object];
    }

    return _response;
}


#pragma mark NSURLConnection Delegate Methods
//NSURLConnection Delegate methods - For asynchronous requests.
// Implementing the async stuff was taking too long so never fully implemented
// this option in the command function.

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the
    // instance var you created so that we can append data to it in the
    // didReceiveData method. Furthermore, this method is called each time
    // there is a redirect so reinitializing it also serves to clear it.
    _responseData = [[NSMutableData alloc] init];
    _response = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    WPXMLRPCDecoder *decoder = [[[WPXMLRPCDecoder alloc] initWithData:data]autorelease];
    NSMutableString* returnString = [NSMutableString stringWithFormat:@"%@",[decoder object]];
    NSLog(@"XML-RPC response: %@\n", returnString);
    _response = [decoder object];
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response
    // for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"Error with xmlrpc client request");
    NSLog(@"Domain: %@\n", error.domain);
    NSLog(@"Error Code: %ld\n", (long)error.code);
    NSLog(@"Description: %@\n", [error localizedDescription]);
    NSLog(@"Reason: %@\n", [error localizedFailureReason]);
}

@end
