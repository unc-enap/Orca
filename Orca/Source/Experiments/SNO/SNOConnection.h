//
//  SNOConnection.h
//  Orca
//
//  Created by Hok Seum  Wan Chan Tseung on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@interface SNOConnection : NSObject{
    id delegate;
    NSMutableData *receivedData;
    NSURL *url;
    NSString *action;
    NSString *key;
}
@property (nonatomic,retain) NSMutableData *receivedData;
@property (retain) id delegate;
@property (nonatomic,retain) NSString *key;

- (void) get: (NSString *)urlString;
- (void) post: (NSData *) postBody atURL:(NSString *)urlString;
- (void) put: (NSData *) postBody atURL:(NSString *)urlString;
- (void) setDelegateAction: (NSString *)aString;
- (void) getSlowControlMap: (NSString *) aStr;
- (void) getXL3State: (NSString *) aStr;
- (void) getXL3Rates: (NSString *) aStr;
- (void) getCableDocument: (NSString *) aStr;
- (void) getIOSCards: (NSString *) aStr;
- (void) getIOS: (NSString *) aStr;
- (void) getAllChannelValues:(NSString *) aStr withKey:(NSString *) aKey;
- (void) getAllConfig: (NSString *) aStr withKey:(NSString *) aKey;
- (void) updateIOSChannelThresholds: (NSString *) aStr ofChannel:(NSString *) aKey;
//-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;

@end
