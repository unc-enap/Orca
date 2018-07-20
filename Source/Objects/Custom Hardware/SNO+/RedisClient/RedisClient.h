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
    int32_t timeout;
}
@property (nonatomic) int port;
@property (nonatomic,copy) NSString *host;
@property (nonatomic) int32_t timeout;

- (id) init;
- (id) initWithHostName: (NSString*) _host withPort: (int) _port;
- (int32_t) timeout;
- (void) setTimeout: (int32_t) _timeout;
- (void) connect;
- (void) disconnect;
- (void) reconnect;
- (redisReply*) vcommand: (const char*) fmt args:(va_list) args;
- (redisReply*) command: (const char *) fmt, ...;
- (void) okCommand: (const char *) fmt, ...;
- (int64_t) intCommand: (const char *) fmt, ...;
@end
