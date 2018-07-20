//
//  SNOConnection.m
//  Orca
//
//  Created by Hok Seum  Wan Chan Tseung on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SNOConnection.h"

@implementation SNOConnection

@synthesize receivedData;
@synthesize key;

- init {
    self = [super init];
    return self;
}

- (void)dealloc {
    [receivedData release];
    [key release];
    [super dealloc];
}


- (void)setDelegate:(id)val
{
    delegate = val;
}

- (id)delegate
{
    return delegate;
}

- (void)get: (NSString *)urlString {
 	
 	//NSLog ( @"GET: %@", urlString ); 
    
    NSURLRequest *request = [[NSURLRequest alloc]
 							 initWithURL: [NSURL URLWithString:urlString]
 							 cachePolicy: NSURLRequestReloadIgnoringLocalCacheData
 							 timeoutInterval: 5
 							 ];
    
    NSURLConnection *connection = [[NSURLConnection alloc]
 								   initWithRequest:request
 								   delegate:self
 								   startImmediately:YES];
 	
    [connection release];
    [request release];
}


- (void)put: (NSData *)postBody atURL:(NSString *)urlString{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [request setValue:@"application/json" forHTTPHeaderField: @"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%u", (int)[postBody length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:postBody];
    
    NSURLConnection *connection = [[NSURLConnection alloc]
 								   initWithRequest:request
 								   delegate:self
                                   startImmediately:YES];
 	
    [connection release];
    [request release];
}	

- (void)post: (NSData *)postBody atURL:(NSString *)urlString{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [request setValue:@"application/json" forHTTPHeaderField: @"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%u", (int)[postBody length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postBody];
    
    NSURLConnection *connection = [[NSURLConnection alloc]
 								   initWithRequest:request
 								   delegate:self
 								   startImmediately:YES];
 	
    [connection release];
    [request release];
}

- (void) setDelegateAction:(NSString *)aString{
    [aString retain];
    [action release];
    action = aString;
}

- (void) getSlowControlMap:(NSString *)aStr{
}

- (void) getXL3State:(NSString *)aStr{
}

- (void) getXL3Rates:(NSString *)aStr{    
}

- (void) getCableDocument:(NSString *)aStr{
}

- (void) getIOS:(NSString *)aStr{
}

- (void) getIOSCards:(NSString *)aStr{
}

- (void) getAllChannelValues:(NSString *)aStr withKey:(NSString*)aKey{
}

- (void) getAllConfig:(NSString *)aStr withKey:(NSString *)aKey{
}

- (void) updateIOSChannelThresholds:(NSString *)aStr ofChannel:(NSString *)aKey{
}

// ====================
// Callbacks
// ====================
/*
- (NSURLRequest *)connection:(NSURLConnection *)connection
 			 willSendRequest:(NSURLRequest *)request
 			redirectResponse:(NSURLResponse *)redirectResponse {
 	NSLog(@"Connection received data, retain count");
    return request;
}
*/

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
 	//NSLog(@"Received response: %@", response);	
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
 	//NSLog(@"Received %d bytes of data", [data length]);  
    if (receivedData == nil){
        receivedData = [[NSMutableData alloc] initWithData:data];
    }else{
        [receivedData appendData:data];
    }
 	//NSLog(@"Received data is now %d bytes", [receivedData length]); 
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
 	//NSLog(@"Error receiving response: %@", error);
    [receivedData release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Once this method is invoked, "responseData" contains the complete result
 	//NSLog(@"Succeeded! Received %d bytes of data", [receivedData length]); 
 	
 	NSString *dataStr=[[NSString alloc] initWithData:receivedData encoding:NSASCIIStringEncoding];
 	//NSLog(@"Succeeded! Received %@ bytes of data", dataStr); 

 	if ([action isEqualToString:@"getSlowControlMap"] && [delegate respondsToSelector:@selector(getSlowControlMap:)]) {
 		[delegate performSelector:@selector(getSlowControlMap:) withObject: dataStr];
 	}else if([action isEqualToString:@"getCableDocument"] && [delegate respondsToSelector:@selector(getCableDocument:)]){
        [delegate performSelector:@selector(getCableDocument:) withObject: dataStr];
    }else if([action isEqualToString:@"getXL3State"] && [delegate respondsToSelector:@selector(getXL3State:)]) {
 		//NSString* dataAsString = [[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] autorelease];
 		[delegate performSelector:@selector(getXL3State:) withObject: dataStr];
 	}else if ([action isEqualToString:@"getXL3Rates"] && [delegate respondsToSelector:@selector(getXL3Rates:)]){
        [delegate performSelector:@selector(getXL3Rates:) withObject: dataStr];
    }else if([action isEqualToString:@"getIOS"] && [delegate respondsToSelector:@selector(getIOS:)]){
        [delegate performSelector:@selector(getIOS:) withObject: dataStr];
    }else if([action isEqualToString:@"getIOSCards"] && [delegate respondsToSelector:@selector(getIOSCards:)]){
        [delegate performSelector:@selector(getIOSCards:) withObject: dataStr];
    }else if([action isEqualToString:@"getAllChannelValues"] && [delegate respondsToSelector:@selector(getAllChannelValues:withKey:)]){
        [delegate performSelector:@selector(getAllChannelValues:withKey:) withObject: dataStr withObject:key];
    }else if([action isEqualToString:@"getAllConfig"] && [delegate respondsToSelector:@selector(getAllConfig:withKey:)]){
        [delegate performSelector:@selector(getAllConfig:withKey:) withObject: dataStr withObject:key]; 
    }else if([action isEqualToString:@"updateIOSChannelThresholds"] && [delegate respondsToSelector:@selector(updateIOSChannelThresholds:ofChannel:)]){
        [delegate performSelector:@selector(updateIOSChannelThresholds:ofChannel:) withObject: dataStr withObject:key]; 
    }

    [dataStr release]; dataStr=nil;
    [receivedData release]; receivedData=nil;
    //[connection release]; connection=nil;
}

@end
