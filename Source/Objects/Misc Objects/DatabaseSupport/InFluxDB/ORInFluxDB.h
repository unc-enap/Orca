/*
 * Influx C (ic) client for data capture header file
 * Developer: Nigel Griffiths.
 * (C) Copyright 2021 Nigel Griffiths
 */
#define DEBUG   if(debug)
#define MEGABYTE ( 1024 * 1024 ) /* USed as the default buffer sizes */

@interface ORInFluxDB : NSObject {
        int debug; /* 0=off, 1=on basic, 2=trace like output */
        char influx_hostname[1024 + 1];/* details of the influxdb server or telegraf */
        char influx_ip[16 + 1];
        long influx_port;

        char influx_database[256+1];    /* the influxdb database  */
        char influx_username[64+1];        /* optional for influxdb access */
        char influx_password[64+1];        /* optional for influxdb access */

        char *output; /* all the stats must fit in this buffer */
        long output_size;
        long output_char;

        char *influx_tags; /* saved tags for every influxdb line protocol mesurement */

        int  subended;        /* stop ic_subend and ic_measureend both enig the measure */
        int  first_sub;        /* need to remove the ic_measure measure before adding ic_sub measure */
        char saved_section[64];
        char saved_sub[64];
        int  sockfd;            /* file desciptor for socket connection */
    }
    -(void) ic_influxHost:(char*)host port:(long) port dataBase:(char*) db;
    -(void) ic_User:(char*)user pw:(char*)pw;
    -(void) ic_tags:(char*)tags;

    -(void) ic_measureSection:(char*)section;
    -(void) ic_measureend;

    -(void) ic_sub:(char*)sub_name;
    -(void) ic_subend;

    -(void) ic_long:(char*)name value:(long long) value;
    -(void) ic_double:(char*)name value:(double) value;
    -(void) ic_string:(char*)name, char *value;

    -(void) ic_push;
    -(void) ic_debug:(int) level;
@end
//a thin wrapper around NSOperationQueue to make a shared queue for InFlux access
@interface ORInFluxDBQueue : NSObject {
    NSOperationQueue* queue;
    NSOperationQueue* lowPriorityQueue;
}
+ (ORInFluxDBQueue*) sharedInFluxDBQueue;
+ (void) addOperation:(NSOperation*)anOp;
+ (void) addLowPriorityOperation:(NSOperation*)anOp;
+ (NSOperationQueue*) queue;
+ (NSOperationQueue*) lowPriorityQueue;
+ (NSUInteger) operationCount;
+ (void) cancelAllOperations;
- (void) addOperation:(NSOperation*)anOp;
- (void) addLowPriorityOperation:(NSOperation*)anOp;
- (NSOperationQueue*) queue;
- (NSOperationQueue*) lowPriorityQueue;
- (void) cancelAllOperations;
- (NSInteger) operationCount;
- (NSInteger) lowPriorityOperationCount;
@end
