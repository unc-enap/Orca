//
//  RedisClient.m
//  Orca
//
//  Created by Eric Marzec on 1/15/16.
//
//

#import "RedisClient.h"

#define DEFUALT_PORT -1
@implementation RedisClient

@synthesize port, host;

- (void) setTimeout: (long) _timeout
{
    /*
     Timeout should be specified in ms using a long unsigned integer
    */
    @synchronized(self) {
        timeout = _timeout;
        if (context) {
            struct timeval tv;
            tv.tv_sec = timeout/1000;
            tv.tv_usec = (timeout % 1000)*1000;
            redisSetTimeout(context, tv);
        }
    }
}

- (void) dealloc
{
    [self disconnect];
    [host release];
    [super dealloc];
}

- (long) timeout
{
    return timeout;
}

- (id) init
{
    self = [self initWithHostName: @"" withPort: -1];
    return self;
}

- (id) initWithHostName: (NSString*) _host withPort: (int) _port
{
    self = [super init];

    if (self) {
        [self setHost:_host];
        [self setPort:_port];
        timeout = 1000; // Initialize timeout to 1 second
    }

    return self;
}

- (void) connect
{
    @synchronized(self) {
        /* timeout for connect is 1 second */
        struct timeval tv = {1, 0};

        context = redisConnectWithTimeout([host UTF8String], port, tv);

        if (context == NULL) {
            NSException *excep = [NSException exceptionWithName:@"RedisClient"
                                  reason:@"Connection failed"
                                  userInfo: nil];
            [excep raise];
        } else if (context->err) {
            NSString *err = [NSString stringWithUTF8String:context->errstr];
            [self disconnect];
            NSException *excep = [NSException exceptionWithName:@"RedisClient"
                                  reason:err
                                  userInfo: nil];
            [excep raise];
        }

        /* successfully connected */
        /* set the timeout on the socket */
        tv.tv_sec = timeout/1000;
        tv.tv_usec = (timeout % 1000)*1000;
        redisSetTimeout(context, tv);
    }
}

- (void) disconnect
{
    @synchronized(self) {
        if(context) {
            redisFree(context);
            context = NULL;
        }
    }
}

- (void) reconnect
{
    @synchronized(self) {
        [self disconnect];
        [self connect];
    }
}

- (redisReply*) vcommand:(const char *)fmt args:(va_list)ap
{
    @synchronized(self) {
        if (context == NULL) [self connect];

        redisReply *r = redisvCommand(context,fmt,ap);

        if (r == NULL) {
            /* Try the command again in case the server was just restarted. */
            [self reconnect];

            r = redisvCommand(context,fmt,ap);

            if (r == NULL) {
                NSString *err = [NSString stringWithUTF8String:context->errstr];
                [self disconnect];
                NSException *excep = [NSException exceptionWithName:@"RedisClient"
                                      reason:err
                                      userInfo:nil];
                [excep raise];
            }
        }

        if(r->type == REDIS_REPLY_ERROR) {
            NSString *err = [NSString stringWithUTF8String:r->str];
            freeReplyObject(r);
            NSException *excep = [NSException exceptionWithName:@"RedisClient"
                                  reason:err
                                  userInfo:nil];
            [excep raise];
        }
        return r;
    }
}

- (redisReply*) command: (const char *) fmt, ... 
{
    /*
     *  Sends a command to host using the Redis protocol. 
     *  Takes a variable number of arguements with a similar format to printf().
     *
     *       e.g.
     *      redisReply *r = [self command:"mtcd_read 0x34"];
     *      freeReplyObject(r);
     *
     *  Replies should be freed by calling the freeReplyObject function.
     */
    va_list ap;
    va_start(ap,fmt);
    redisReply *r = [self vcommand:fmt args:ap];
    va_end(ap);
    return r;
}

- (void) okCommand: (const char *) fmt, ... 
{
    va_list ap;
    va_start(ap,fmt);
    redisReply *r = [self vcommand:fmt args:ap];
    va_end(ap);

    if (r->type != REDIS_REPLY_STATUS) {
        NSException *excep = [NSException exceptionWithName:@"RedisClient"
                              reason:@"unexpected response type" 
                              userInfo:nil];
        [excep raise];
    }

    freeReplyObject(r);
}

- (long long) intCommand: (const char *) fmt, ... 
{
    va_list ap;
    va_start(ap,fmt);
    redisReply *r = [self vcommand:fmt args:ap];
    va_end(ap);

    if (r->type != REDIS_REPLY_INTEGER) {
        NSException *excep = [NSException exceptionWithName:@"RedisClient"
                              reason:@"unexpected response type" 
                              userInfo:nil];
        [excep raise];
    }

    long long responseVal = r->integer;
    freeReplyObject(r);
    return responseVal;
}

@end
