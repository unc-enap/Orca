//
//  ORVXI11HardwareFinder.m
//  Orca
//
//  Created by Michael Marino on 6 Nov 2011
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
/*
 * This code contains modifications to clnt_broadcast available in the
 * rpc.subproj/pmap_rmt.c.  A summary of modifications:
 *
 *  1.  Allow blocking time to be set by the user, the previous hard-coded
 *  times were not general enough. 
 *  2.  Calls PORTMAP_GETPORT to determine if there's a service that satisfies
 *  the input specifications 
 *  3.  The clnt_broadcast has been renamed to clnt_find_services.
 *
 *  M. Marino November 2011
 *
 */
/*
 * Copyright (c) 1999 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * Portions Copyright (c) 1999 Apple Computer, Inc.  All Rights
 * Reserved.  This file contains Original Code and/or Modifications of
 * Original Code as defined in and that are subject to the Apple Public
 * Source License Version 1.1 (the "License").  You may not use this file
 * except in compliance with the License.  Please obtain a copy of the
 * License at http://www.apple.com/publicsource and read it before using
 * this file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */
/*
 * Sun RPC is a product of Sun Microsystems, Inc. and is provided for
 * unrestricted use provided that this legend is included on all tape
 * media and as a part of the software program in whole or part.  Users
 * may copy or modify Sun RPC without charge, but are not authorized
 * to license or distribute it to anyone else except as part of a product or
 * program developed by the user.
 * 
 * SUN RPC IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING THE
 * WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
 * 
 * Sun RPC is provided with no support and without any obligation on the
 * part of Sun Microsystems, Inc. to assist in its use, correction,
 * modification or enhancement.
 * 
 * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
 * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY SUN RPC
 * OR ANY PART THEREOF.
 * 
 * In no event will Sun Microsystems, Inc. be liable for any lost revenue
 * or profits or other special, indirect and consequential damages, even if
 * Sun has been advised of the possibility of such damages.
 * 
 * Sun Microsystems, Inc.
 * 2550 Garcia Avenue
 * Mountain View, California  94043
 */

#import "ORVXI11HardwareFinder.h"
#import "SynthesizeSingleton.h"
#import <rpc/rpc.h>
#import <rpc/xdr.h>
#import <arpa/inet.h>
#import <rpc/pmap_rmt.h>
#import <rpc/pmap_prot.h>
#import <unistd.h>
#import <sys/socket.h>
#import <sys/fcntl.h>
#import <stdio.h>
#import <string.h>
#import <errno.h>
#import <net/if.h>
#import <sys/ioctl.h>
#import "vxi11_user.h"

NSString* ORHardwareFinderAvailableHardwareChanged = @"ORHardwareFinderAvailableHardwareChanged";

@interface ORVXI11HardwareFinder (private)


#if (defined __LP64__)
- (NSMutableArray*) findServicesForProgram:(uint32_t)prog version:(uint32_t)vers process:(uint32_t)proc
#else
- (NSMutableArray*) findServicesForProgram:(u_long)prog version:(u_long)vers process:(u_long)proc 
#endif
withTimeOut:(struct timeval *)t;
- (NSMutableArray*) broadcastNetsForSocket:(int) sock;
- (void) setAvailableHardware:(NSMutableDictionary*)adict;
- (void) refreshDeferred;
@end

@implementation ORVXI11HardwareFinder

SYNTHESIZE_SINGLETON_FOR_ORCLASS(VXI11HardwareFinder);

- (void) dealloc
{
	//should never get here ... we are a singleton!
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [availableHardware release];
    [super dealloc];
}


#pragma mark •••Accessors
- (NSMutableArray*) broadcastNetsForSocket:(int) sock
{
    // Returns an array of NSData-wrapped if_addr's.
    NSMutableArray* retArray = [NSMutableArray array];
	struct ifconf ifc;
    struct ifreq ifreq, *ifr;
	struct sockaddr_in *sin;
    char *cp, *cplim;
    char buf[UDPMSGSIZE];
    struct in_addr output;
    
    ifc.ifc_len = UDPMSGSIZE;
    ifc.ifc_buf = buf;
    if (ioctl(sock, SIOCGIFCONF, (char *)&ifc) < 0) {
        NSLog(@"broadcast: ioctl (get interface configuration)");
        return (0);
    }
#if defined __APPLE__ /* This should really be BSD */
#define max(a, b) (a > b ? a : b)
#define size(p)	max((p).sa_len, sizeof(p))
#endif
	cplim = buf + ifc.ifc_len; /*skip over if's with big ifr_addr's */
	for (cp = buf; cp < cplim;
#if defined __APPLE__ /* This should really be BSD */
         cp += sizeof (ifr->ifr_name) + size(ifr->ifr_addr)) {
#else
        cp += sizeof (*ifr)) {
#endif
            ifr = (struct ifreq *)cp;
            if (ifr->ifr_addr.sa_family != AF_INET)
                continue;
            ifreq = *ifr;
            if (ioctl(sock, SIOCGIFFLAGS, (char *)&ifreq) < 0) {
                NSLog(@"broadcast: ioctl (get interface flags)");
                continue;
            }
            if ((ifreq.ifr_flags & IFF_BROADCAST) &&
                (ifreq.ifr_flags & IFF_UP)) {
                sin = (struct sockaddr_in *)&ifr->ifr_addr;
                if (ioctl(sock, SIOCGIFBRDADDR, (char *)&ifreq) < 0) {
                    output =
				    inet_makeaddr(inet_netof(sin->sin_addr),
                                  INADDR_ANY);
                } else {
                    output = ((struct sockaddr_in *)&ifreq.ifr_addr)->sin_addr;
                }
                // Add it to the array
                [retArray addObject:[NSData dataWithBytes:&output length:sizeof(output)]];
            }
        }
        return retArray;
}

#define MAX_BROADCAST_SIZE 1400
#if (defined __LP64__)
- (NSMutableArray*) findServicesForProgram:(uint32_t)prog version:(uint32_t)vers process:(uint32_t)proc
#else
- (NSMutableArray*) findServicesForProgram:(u_long)prog version:(u_long)vers process:(u_long)proc 
#endif
    withTimeOut:(struct timeval *)t
{
    XDR xdr_stream;
    register XDR *xdrs = &xdr_stream;
    ssize_t outlen, inlen;
    unsigned int fromlen;
    register int sock;
    int on = 1;
    fd_set mask;
    fd_set readfds;
    register int i;
    uint32_t xid;
#if (defined __LP64__) && (defined __APPLE__)
    unsigned int port;
#else
    uint32_t port;
#endif

    struct sockaddr_in baddr, raddr; /* broadcast and response addresses */
    struct rmtcallargs a;
    struct rmtcallres r;
    struct rpc_msg msg;
    char outbuf[MAX_BROADCAST_SIZE], inbuf[UDPMSGSIZE];
    int rfd;
    NSMutableArray* retArray = [NSMutableArray array];    
        
    /*
     * initialization: create a socket, a broadcast address, and
     * preserialize the arguments into a send buffer.
     */
    if ((sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
        NSLog(@"Cannot create socket for broadcast rpc");
        goto done_broad;
    }
#ifdef SO_BROADCAST
    if (setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &on, sizeof (on)) < 0) {
        NSLog(@"Cannot set socket option SO_BROADCAST");
        goto done_broad;
    }
#endif /* def SO_BROADCAST */
    FD_ZERO(&mask);
    FD_SET(sock, &mask);
    memset((char *)&baddr, 0, sizeof (baddr));
    baddr.sin_family = AF_INET;
    baddr.sin_port = htons(PMAPPORT);
    baddr.sin_addr.s_addr = htonl(INADDR_ANY);
    /*	baddr.sin_addr.S_un.S_addr = htonl(INADDR_ANY); */
    
    rfd = open("/dev/random", O_RDONLY, 0);
    if ((rfd < 0) || (read(rfd, &xid, sizeof(xid)) != sizeof(xid)))
    {
        gettimeofday(t, (struct timezone *)0);
        xid = (uint32_t)(getpid() ^ t->tv_sec ^ t->tv_usec);
    }
    if (rfd > 0) close(rfd);
    
    msg.rm_xid = xid;
    msg.rm_direction = CALL;
    msg.rm_call.cb_rpcvers = RPC_MSG_VERSION;
    msg.rm_call.cb_prog = PMAPPROG;
    msg.rm_call.cb_vers = PMAPVERS;
    msg.rm_call.cb_proc = PMAPPROC_GETPORT;
    msg.rm_call.cb_cred = _null_auth;
    msg.rm_call.cb_verf = _null_auth;
    a.prog = prog;
    a.vers = vers;
    a.proc = proc;
    a.xdr_args = (xdrproc_t)xdr_void;
    a.args_ptr = NULL;
    a.arglen = 0;
    r.port_ptr = &port;
    r.xdr_results = (xdrproc_t)xdr_void;
    r.results_ptr = NULL;
    r.resultslen = 0;
    xdrmem_create(xdrs, outbuf, MAX_BROADCAST_SIZE, XDR_ENCODE);
    if ((! xdr_callmsg(xdrs, &msg)) || (! xdr_rmtcall_args(xdrs, &a))) goto done_broad;
    outlen = (int)xdr_getpos(xdrs);
    xdr_destroy(xdrs);
    /*
     * Basic loop: broadcast a packet and wait a while for response(s).
     * The response timeout grows larger per iteration.
     */
    NSMutableArray *availNets = [self broadcastNetsForSocket:sock];
    for (i = 0; i < [availNets count]; i++) {
        baddr.sin_addr = *(struct in_addr *)[[availNets objectAtIndex:i] bytes];
        if (sendto(sock, outbuf, outlen, 0,
                   (struct sockaddr *)&baddr,
                   sizeof (struct sockaddr)) != outlen) {
            NSLog(@"Cannot send broadcast packet");
            goto done_broad;
        }
    }
recv_again:
    msg.acpted_rply.ar_verf = _null_auth;
    msg.acpted_rply.ar_results.where = (caddr_t)&r;
    msg.acpted_rply.ar_results.proc = (xdrproc_t)xdr_void;
    port = 0;
    readfds = mask;
    switch (select(sock+1, &readfds, NULL, NULL, t)) {
            
        case 0:  /* timed out */
            goto done_broad;
            
        case -1:  /* some kind of error */
            if (errno == EINTR) goto recv_again;
            NSLog(@"Broadcast select problem");
            goto done_broad;
            
    }  /* end of select results switch */
try_again:
    fromlen = sizeof(struct sockaddr);
    inlen = recvfrom(sock, inbuf, UDPMSGSIZE, 0, (struct sockaddr *)&raddr, &fromlen);
    if (inlen < 0) {
        if (errno == EINTR)
            goto try_again;
        fprintf(stderr,"Cannot receive reply to broadcast: %s",strerror(errno));
        goto done_broad;
    }
#if (defined __LP64__) && (defined __APPLE__)
    if (inlen < (int)sizeof(uint32_t)) goto recv_again;
#else
    if (inlen < (int)sizeof(u_long)) goto recv_again;
#endif
    /*
     * see if reply transaction id matches sent id.
     * If so, decode the results.
     */
    xdrmem_create(xdrs, inbuf, (u_int)inlen, XDR_DECODE);
    if (xdr_replymsg(xdrs, &msg) && 
        xdr_u_long(xdrs, &port)  && 
        port != 0) {
        if ((msg.rm_xid == xid) &&
            (msg.rm_reply.rp_stat == MSG_ACCEPTED) &&
            (msg.acpted_rply.ar_stat == SUCCESS)) {
            raddr.sin_port = htons((u_short)port);
            [retArray addObject:[NSData dataWithBytes:&raddr length:sizeof(raddr)]];
        }
        /* otherwise, we just ignore the errors ... */
    } else {
#ifdef notdef
        /* some kind of deserialization problem ... */
        if (msg.rm_xid == xid) NSLog(@"Broadcast deserialization problem");
        /* otherwise, just random garbage */
#endif
    }
    xdrs->x_op = XDR_FREE;
    msg.acpted_rply.ar_results.proc = (xdrproc_t)xdr_void;
    xdr_replymsg(xdrs, &msg);
    xdr_destroy(xdrs);
    goto recv_again;
done_broad:
    close(sock);
    return retArray;
}

- (NSMutableDictionary *) findVXI11Devices
{
    NSMutableDictionary* retDict = [NSMutableDictionary dictionary];
    struct timeval t;
    const size_t MAXSIZE = 100;
    char rcv[MAXSIZE];    
    char str[INET_ADDRSTRLEN];    
    t.tv_sec = 1;
    t.tv_usec = 0;
    // Why 6 for the protocol for the VXI-11 devices?  Not sure, but the devices
    // will otherwise not respond. 
    NSMutableArray* devs = [self findServicesForProgram:DEVICE_CORE version:DEVICE_CORE_VERSION process:6 withTimeOut:&t];
    int i;
    for (i=0; i < [devs count]; i++) {
        struct sockaddr_in* addr = (struct sockaddr_in*)[[devs objectAtIndex:i] bytes];
        const char* an_addr = inet_ntop(AF_INET, &(addr->sin_addr), str, INET_ADDRSTRLEN);
        CLINK vxi_link;
        if ( vxi11_open_device(an_addr, &vxi_link, "inst0") < 0 ) continue;        
        int32_t found = vxi11_send_and_receive(&vxi_link, "*IDN?", rcv, MAXSIZE, 10);
        if (found > 0) {
            if (found == MAXSIZE - 1) found--;
            rcv[found] = '\0';
            NSString* theStr = [NSString stringWithCString:an_addr encoding:NSASCIIStringEncoding];   
            ORVXI11IPDevice* dev = [ORVXI11IPDevice deviceForString:[NSString stringWithCString:rcv encoding:NSASCIIStringEncoding]];
            [dev setIpAddress:theStr];
            [retDict setObject:dev forKey:[dev ipAddress]];            
        }
        vxi11_close_device(an_addr, &vxi_link);
    }
    return retDict;
}

- (void) refresh
{
    [self performSelector:@selector(refreshDeferred) withObject:nil afterDelay:0.5];
}

- (void) refreshDeferred
{
    [self setAvailableHardware:[self findVXI11Devices]];
}    
- (void) setAvailableHardware:(NSMutableDictionary *)adict
{
    [adict retain];
    [availableHardware release];
    availableHardware = adict;
    
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:ORHardwareFinderAvailableHardwareChanged 
     object:self]; 
}

- (NSDictionary*) availableHardware
{
    return availableHardware;
}
    
@end
    
@implementation ORVXI11IPDevice

@synthesize manufacturer;
@synthesize model;
@synthesize serialNumber;
@synthesize version;    
@synthesize ipAddress;

+ (id) deviceForString:(NSString*) astr 
{
    return [ORVXI11IPDevice deviceForString:astr withSeparationWithString:@","];
}
    
+ (id) deviceForString:(NSString*) astr withSeparationWithString:(NSString *)sep
{
    id retVal = [[[ORVXI11IPDevice alloc] init] autorelease];
    if (retVal == nil) return retVal;
    NSArray* components = [astr componentsSeparatedByString:sep];
    if ([components count] != 4) return retVal;
    NSCharacterSet* trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    [retVal setManufacturer:[[components objectAtIndex:0] stringByTrimmingCharactersInSet:trimSet]];
    [retVal setModel:[[components objectAtIndex:1] stringByTrimmingCharactersInSet:trimSet]];
    [retVal setSerialNumber:[[components objectAtIndex:2] stringByTrimmingCharactersInSet:trimSet]];
    [retVal setVersion:[[components objectAtIndex:3] stringByTrimmingCharactersInSet:trimSet]];    
    return retVal;
}
    
- (void) dealloc
{
    [manufacturer release];
    [model release];
    [serialNumber release];
    [ipAddress release];
    [version release];
    [super dealloc];
}
    
@end
