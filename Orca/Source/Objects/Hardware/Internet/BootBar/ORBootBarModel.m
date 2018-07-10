//
//  ORBootBarModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORBootBarModel.h"
#import "NetSocket.h"

#define kBootBarPort 9100

NSString* ORBootBarModelPasswordChanged		 = @"ORBootBarModelPasswordChanged";
NSString* ORBootBarModelLock				 = @"ORBootBarModelLock";
NSString* BootBarIPNumberChanged			 = @"BootBarIPNumberChanged";
NSString* ORBootBarModelIsConnectedChanged	 = @"ORBootBarModelIsConnectedChanged";
NSString* ORBootBarModelStatusChanged		 = @"ORBootBarModelStatusChanged";
NSString* ORBootBarModelBusyChanged			 = @"ORBootBarModelBusyChanged";
NSString* ORBootBarModelOutletNameChanged	 = @"ORBootBarModelOutletNameChanged";

@interface ORBootBarModel (private)
- (void) sendCmd;
- (void) setPendingCmd:(NSString*)aCmd;
- (void) timeout;
- (void) setupOutletNames;
- (void) postCouchDBRecord;
@end

@implementation ORBootBarModel

- (void) dealloc
{
	[pendingCmd release];
    [password release];
	[socket close];
    [socket setDelegate:nil];
	[socket release];
 	[connectionHistory release];
    [IPNumber release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:17];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super sleep];
}


#pragma mark •••Initialization
- (void) makeMainController
{
    [self linkToController:@"ORBootBarController"];
}

- (void) setUpImage
{
	//---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"BootBar"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
	
    int chan;
	int xOffset = 0;
    for(chan=1;chan<9;chan++){
		if(chan>4)xOffset = 24;
		NSBezierPath* circle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(xOffset+26+chan*9, 5,7,7)];
		if(outletStatus[chan]) [[NSColor colorWithCalibratedRed:0. green:1.0 blue:0. alpha:1.0] set];
		else			       [[NSColor colorWithCalibratedRed:1.0 green:0. blue:0. alpha:.8] set];
		[circle fill];
    }
	
	NSDictionary* attDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont labelFontOfSize:12],NSFontAttributeName, [NSColor whiteColor],NSForegroundColorAttributeName,nil];
	NSAttributedString* n = [[NSAttributedString alloc] 
							 initWithString:[NSString stringWithFormat:@"%lu",[self uniqueIdNumber]]
							 attributes:attDict];
	

	[n drawInRect:NSMakeRect(3,-8,[i size].width,[i size].height)];
	[n release];
	
    [i unlockFocus];		
    [self setImage:i];
    [i release];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OROrcaObjectImageChanged object:self];
	
}

- (void) initConnectionHistory
{
	ipNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.IPNumberIndex",[self className]]];
	if(!connectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey: [NSString stringWithFormat:@"orca.%@.ConnectionHistory",[self className]]];
		connectionHistory = [his mutableCopy];
	}
	if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
}

#pragma mark ***Accessors

- (NSString*) outletName:(int)index
{
	if(index<1)index = 1;
	else if(index>=8)index=8;
	if(!outletNames)[self setupOutletNames];
	return [outletNames objectAtIndex:index];
}

- (void) setOutlet:(int)index name:(NSString*)aName
{
	if(!outletNames)[self setupOutletNames];
    if([aName length]==0)aName = [NSString stringWithFormat:@"Outlet %d",index];
	[[[self undoManager] prepareWithInvocationTarget:self] setOutlet:index name:[self outletName:index]];
	[outletNames replaceObjectAtIndex:index withObject:aName];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBootBarModelOutletNameChanged object:self];
}

- (NSString*) password
{
	if(!password)return @"";
    else return password;
}

- (void) setPassword:(NSString*)aPassword
{
	if(!aPassword)aPassword= @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
    
    [password autorelease];
    password = [aPassword copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORBootBarModelPasswordChanged object:self];
}

- (void) clearHistory
{
	[connectionHistory release];
	connectionHistory = nil;
	
	[self setIPNumber:[self IPNumber]];
}

- (NSUInteger) connectionHistoryCount
{
	return [connectionHistory count];
}

- (id) connectionHistoryItem:(NSUInteger)index
{
	if(connectionHistory && index<[connectionHistory count])return [connectionHistory objectAtIndex:index];
	else return nil;
}

- (NSUInteger) ipNumberIndex
{
	return ipNumberIndex;
}

- (NSString*) IPNumber
{
	if(!IPNumber)return @"";
    return IPNumber;
}

- (void) setIPNumber:(NSString*)aIPNumber
{
	if([aIPNumber length]){
		
		[[[self undoManager] prepareWithInvocationTarget:self] setIPNumber:IPNumber];
		
		[IPNumber autorelease];
		IPNumber = [aIPNumber copy];    
		
		if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
		if(![connectionHistory containsObject:IPNumber]){
			[connectionHistory addObject:IPNumber];
		}
		ipNumberIndex = [connectionHistory indexOfObject:aIPNumber];
		
		[[NSUserDefaults standardUserDefaults] setObject:connectionHistory forKey:[NSString stringWithFormat:@"orca.%@.ConnectionHistory",[self className]]];
		[[NSUserDefaults standardUserDefaults] setInteger:ipNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.IPNumberIndex",[self className]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:BootBarIPNumberChanged object:self];
	}
}

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
	if(![self isBusy])[self getStatus];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:37];
    [self postCouchDBRecord];
}

- (NetSocket*) socket
{
	return socket;
}

- (void) setSocket:(NetSocket*)aSocket
{
	if(aSocket != socket)[socket close];
	[aSocket retain];
	[socket release];
	socket = aSocket;
    [socket setDelegate:self];
}

- (void) setIsConnected:(BOOL)aFlag
{
    isConnected = aFlag;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBootBarModelIsConnectedChanged object:self];
}

- (void) connect
{
	if(!isConnected && [IPNumber length]){
		[self setSocket:[NetSocket netsocketConnectedToHost:IPNumber port:kBootBarPort]];	
        [self setIsConnected:[socket isConnected]];
	}
	else {
		[self setSocket:nil];	
        [self setIsConnected:[socket isConnected]];
	}
}

- (BOOL) isConnected
{
	return isConnected;
}

- (void) turnOnOutlet:(int) i
{
	if([password length]){
		NSString* cmd = [NSString stringWithFormat:@"%c%@%dON\r",0x1B,password,i];
		[self setPendingCmd:cmd];
		NSLog(@"BootBar %d: %@ turned ON\n",[self uniqueIdNumber],[self outletName:i]);
	}
}

- (void) turnOffOutlet:(int) i
{
	if([password length]){
		NSString* cmd = [NSString stringWithFormat:@"%c%@%dOFF\r",0x1B,password,i];
		[self setPendingCmd:cmd];
		NSLog(@"BootBar %d: %@ turned OFF\n",[self uniqueIdNumber],[self outletName:i]);
	}
}

- (void) getStatus
{
	if([password length]){
		NSString* cmd = [NSString stringWithFormat:@"%c%@?\r",0x1B,password];
		[self setPendingCmd:cmd];
	}
}

- (BOOL) outletStatus:(int)i
{
	if(i>=1 && i<=8)return outletStatus[i];
	else return NO;
}

- (void) setOutlet:(int)i status:(BOOL)aValue
{
	if(i>=1 && i<=8){
		BOOL changed = NO;
		if(aValue != outletStatus[i])changed = YES;
		outletStatus[i] = aValue;
		if(changed){
			[self setUpImage];
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"Channel"];
			[[NSNotificationCenter defaultCenter] postNotificationName:ORBootBarModelStatusChanged object:self userInfo:userInfo];
		}
	}
}

#pragma mark ***Delegate Methods
/*
 The boot bar communication sequence is rather strange. Once a connection is made a command must be sent before some short timeout has expired. Once a command is sent, no other commands will be accepted and the socket will close after a timeout. If two commands are sent while the socket is open, the device will hang and have to be rebooted via telenet. To prevent this from happening, we close the socket immediatelhy after receiving a command response. While the socke is open we do not allow any other commands from being sent. 
 
 The sequence is:
 - set pending command
 - open socket
 - sent the command
 - receive the response
 - clear the pending command
 - close the socket.
 
 If a pending command exists the system is assumed to be 'busy' and new commands are ignored.
 */
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
		[self sendCmd];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    if(inNetSocket == socket){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connect) object:nil];
		NSString* theString = [[[[NSString alloc] initWithData:[inNetSocket readData] encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
		NSArray* lines = [theString componentsSeparatedByString:@"\n\r"];
		for(NSString* anOutlet in lines){
			if([anOutlet length] >= 4){
				NSArray* parts = [anOutlet componentsSeparatedByString:@" "];
				if([parts count]>=2){
					int index = [[parts objectAtIndex:0] intValue];
					if([[parts objectAtIndex:1] isEqualToString:@"ON"]){
						[self setOutlet:index status:YES];
					}
					else if([[parts objectAtIndex:1] isEqualToString:@"OFF"]){
						[self setOutlet:index status:NO];
					}
				}
			}
		}
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	}
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
		
		[self setIsConnected:NO];
        [socket setDelegate:nil];
		[socket autorelease];
		socket = nil;
		[self setPendingCmd:nil];
    }
}

- (BOOL) isBusy
{
	return pendingCmd != nil;
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self setPassword:			[decoder decodeObjectForKey:@"password"]];
	[self setIPNumber:			[decoder decodeObjectForKey:@"IPNumber"]];
	outletNames = [[decoder decodeObjectForKey:@"outletNames"]retain];
	[self initConnectionHistory];

	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
 	[encoder encodeObject:password		forKey:@"password"];
 	[encoder encodeObject:IPNumber		forKey:@"IPNumber"];
	[encoder encodeObject:outletNames  forKey:@"outletNames"];
}

@end

@implementation ORBootBarModel (private)
- (void) postCouchDBRecord
{
    if([IPNumber length] && [password length]){
        NSMutableDictionary* values = [NSMutableDictionary dictionary];
        NSMutableArray* statesAndNames = [NSMutableArray array];
        int i;
        for(i=0;i<9;i++){
            [statesAndNames addObject:
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt:i],@"index",
                    [outletNames objectAtIndex:i],@"name",
                    [NSNumber numberWithBool:outletStatus[i]],@"state",
                     nil]];
        }
        [values setObject:statesAndNames forKey:@"states"];
        [values setObject:IPNumber forKey:@"ipNumber"];
        [values setObject:[NSNumber numberWithInt:30] forKey:@"pollTime"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
    }
}
- (void) sendCmd
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
    if([pendingCmd length]){
        const char* bytes = [pendingCmd cStringUsingEncoding:NSASCIIStringEncoding];
        [socket write:bytes length:[pendingCmd length]];
    }
    [self performSelector:@selector(timeout) withObject:nil afterDelay:3];

}

- (void) timeout
{
    [self setPendingCmd:nil];
}
		 
- (void) setPendingCmd:(NSString*)aCmd
{
	if(!aCmd){
		[pendingCmd release];
		pendingCmd = nil;
	}
	else if(![self isBusy]){
		[pendingCmd release];
		pendingCmd = [aCmd copy];
		[self connect];
	}
	else NSLog(@"Boot Bar cmd ignored -- busy\n");
	[[NSNotificationCenter defaultCenter] postNotificationName:ORBootBarModelBusyChanged object:self];
}

- (void) setupOutletNames
{
	outletNames = [[NSMutableArray array] retain];
	int i;
	for(i=0;i<9;i++)[outletNames addObject:[NSString stringWithFormat:@"Outlet %d",i]];	
}



@end

