//
//  ORSocketClient.m
//  Orca
//
//  Created by Mark Howe on 11/10/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORSocketClient.h"

#import "NetSocket.h"

@implementation ORSocketClient
- (id)initWithNetSocket:(NetSocket*)insocket
{
	self=[super init];
	
	socket = [insocket retain];
	
	// Setup socket for use
	[socket open];
	[socket scheduleOnCurrentRunLoop];
	[socket setDelegate:self];
	
	[self setName:[insocket remoteHost]];
	
	return self;
}
- (void)dealloc
{
	[socket setDelegate:nil];
    [timeConnected release];
    [name release];
	[socket release];
	[super dealloc];
}

- (id) delegate
{
	return delegate;
}
- (void) setDelegate:(id)newDelegate
{
	delegate = newDelegate; //don't retain a delegate!
}
- (NSString*) name
{
	return name;
}

- (void) setName:(NSString*)newName
{
	[name autorelease];
	name=[newName copy];
		
	if([delegate respondsToSelector:@selector(clientChanged:)]){
		[delegate clientChanged:self];
	}
}

- (unsigned long long)totalSent
{
    return totalSent;
}

- (void)setTotalSent:(unsigned long long)aTotalSent
{
    totalSent = aTotalSent;
    if([delegate respondsToSelector:@selector(clientDataChanged:)]){
	    [delegate clientDataChanged:self];
    }
}

- (NetSocket*)socket
{
	return socket;
}

- (NSDate*) timeConnected
{
	return timeConnected;
}
- (void) setTimeConnected:(NSDate*)newTimeConnected
{
	[timeConnected autorelease];
	timeConnected=[newTimeConnected retain];
	
	if([delegate respondsToSelector:@selector(clientChanged:)]){
		[delegate clientChanged:self];
	}
}

- (unsigned long)amountInBuffer 
{
    return amountInBuffer;
}


- (void)setAmountInBuffer:(unsigned long)anAmountInBuffer 
{
    amountInBuffer = anAmountInBuffer;
    if([delegate respondsToSelector:@selector(clientDataChanged:)]){
	    [delegate clientDataChanged:self];
    }
}

- (void)writeData:(NSData*)inData
{
    [socket writeData:inData];
}

- (int) socketStatus
{
    return socketStatus;
}

- (void)netsocketDisconnected:(NetSocket*)insocket
{	
	if([delegate respondsToSelector:@selector(clientDisconnected:)]){
        //NSLog(@"%@ disconnected from %@.\n",name,[self className]);
		//the disconnect process will destroy this object so we put
		//it into the autorelease pool temporarily.
		[[self retain] autorelease];
		[delegate clientDisconnected:self];
	}
}


- (void) netsocketDataInOutgoingBuffer:(NetSocket*)insocket length:(unsigned long)length
{
    [self setAmountInBuffer:length];
}

- (void) netsocket:(NetSocket*)inNetSocket status:(int)status
{
    socketStatus = status;
    if([delegate respondsToSelector:@selector(clientDataChanged:)]){
	    [delegate clientDataChanged:self];
    }   
}
- (BOOL) isConnected
{
	return [socket isConnected];
}

- (void) clearCounts
{
    [self setTotalSent:0];
    [self setAmountInBuffer:0];
}

- (void)netsocketDataSent:(NetSocket*)insocket length:(unsigned long)length
{
    [self setTotalSent:[self totalSent]+length];
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
	NSData* data = [inNetSocket readData:inAmount];
	NSLog(@"received data: %d bytes\n",[data length]);
}

@end
