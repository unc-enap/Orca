//
//  RedisClient.h
//  Orca
//
//  Created by Eric Marzec on 1/15/16.
//
//

#import <Foundation/Foundation.h>
#import "hiredis.h"
@interface RedisClient : NSObject
{
    NSString *host;
    redisContext *context;
    int port;
    long timeout;
}
@property (nonatomic) int port;
@property (nonatomic,copy) NSString *host;
@property (nonatomic) long timeout;

- (id) init;
- (id) initWithHostName: (NSString*) _host withPort: (int) _port;
- (long) timeout;
- (void) setTimeout: (long) _timeout;
- (void) connect;
- (void) disconnect;
- (void) reconnect;
- (redisReply*) vcommand: (const char*) fmt args:(va_list) args;
- (redisReply*) command: (const char *) fmt, ...;
- (void) okCommand: (const char *) fmt, ...;
- (long long) intCommand: (const char *) fmt, ...;
@end
