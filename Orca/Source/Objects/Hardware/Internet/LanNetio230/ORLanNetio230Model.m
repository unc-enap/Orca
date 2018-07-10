//
//  ORLanNetio230Model.m
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

//Description:
// commands:
// example:
/*
http://
192.168.1.101/tgi/control.tgi?login=p:admin:admin&p=10ui

192.168.1.101/tgi/control.tgi?login=p:admin:admin&p=1010
Antwort:
250 OK
(Fehler: 550 INVALID VALUE
etc)

Statusabfrage:
192.168.1.101/tgi/control.tgi?login=p:admin:admin&p=l
Antwort:zB.
1 0 1 1 
oder Error-Codes ...




...


Sorry, there is a lot of code from boot bar left, but I needed quickly a interface to the Lan NetIO230.
I failed using the COCOA HTTP request commands (like in ADEI object).
ALways the first request worked,
the second request failed ("connection lost"?) and the LanNetIO rebooted three times (sic!).

No clue, what went wrong.

Finally I used popen and called shell commands to read status and switch the outlets on/off (using "curl").
2013-10-24 Till.Bergmann@kit.edu
*/


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Imported Files
#import "ORLanNetio230Model.h"
#import "NetSocket.h"

#define kLanNetio230Port 9100

NSString* ORLanNetio230ModelPasswordChanged		 = @"ORLanNetio230ModelPasswordChanged";
NSString* ORLanNetio230ModelLock				 = @"ORLanNetio230ModelLock";
NSString* LanNetio230IPNumberChanged			 = @"LanNetio230IPNumberChanged";
NSString* ORLanNetio230ModelIsConnectedChanged	 = @"ORLanNetio230ModelIsConnectedChanged";
NSString* ORLanNetio230ModelStatusChanged		 = @"ORLanNetio230ModelStatusChanged";
NSString* ORLanNetio230ModelBusyChanged			 = @"ORLanNetio230ModelBusyChanged";
NSString* ORLanNetio230ModelOutletNameChanged	 = @"ORLanNetio230ModelOutletNameChanged";

@interface ORLanNetio230Model (private)
- (void) sendCmd;
- (void) setPendingCmd:(NSString*)aCmd;
- (void) timeout;
- (void) setupOutletNames;
- (void) postCouchDBRecord;
@end

@implementation ORLanNetio230Model

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
	//start polling manually ... [self performSelector:@selector(pollHardware) withObject:nil afterDelay:5];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super sleep];
}


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
- (void) makeMainController
{
    [self linkToController:@"ORLanNetio230Controller"];
}

- (void) setUpImage
{
    // this is drawing the image in the Experiment overview -tb- 2013-10
	//---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"LanNetio230"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
	
    int chan;
	int xOffset = 0;
    for(chan=1;chan<=kLanNetio230OutletNum;chan++){
		if(chan>4)xOffset = 24;
		NSBezierPath* circle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(xOffset+15+(chan-1)*19, 12,7,7)];
		if(outletStatus[chan]) [[NSColor colorWithCalibratedRed:0. green:1.0 blue:0. alpha:1.0] set];//green 0,1,0
		else			       [[NSColor colorWithCalibratedRed:1.0 green:0. blue:0. alpha:.8] set];//red 1,0,0
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
	else if(index>=kLanNetio230OutletNum)index=kLanNetio230OutletNum;
	if(!outletNames)[self setupOutletNames];
	return [outletNames objectAtIndex:index];
}

- (void) setOutlet:(int)index name:(NSString*)aName
{
	if(!outletNames)[self setupOutletNames];
    if([aName length]==0)aName = [NSString stringWithFormat:@"Outlet %d",index];
	[[[self undoManager] prepareWithInvocationTarget:self] setOutlet:index name:[self outletName:index]];
	[outletNames replaceObjectAtIndex:index withObject:aName];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLanNetio230ModelOutletNameChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLanNetio230ModelPasswordChanged object:self];
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
		[[NSNotificationCenter defaultCenter] postNotificationName:LanNetio230IPNumberChanged object:self];
	}
}

- (void) pollHardware
{
    //DEBUG OUTPUT:  	
    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-


	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
	if(![self isBusy])[self getStatus];//TODO: IMPLEMENT THIS -tb-
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:120 /*30*/];
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
	
    //-tb- original [[NSNotificationCenter defaultCenter] postNotificationName:ORLanNetio230ModelIsConnectedChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLanNetio230ModelBusyChanged object:self];
}

- (void) connect
{
    //DEBUG OUTPUT:  	    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-



//TODO: DEV
        [self setIsConnected:true];
        //these two lines were in netsocketConnected
        //[self setIsConnected:[socket isConnected]];
		[self sendCmd];

return;



	if(!isConnected && [IPNumber length]){
		[self setSocket:[NetSocket netsocketConnectedToHost:IPNumber port:kLanNetio230Port]];	
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


-(int) curlSetLanNetIOStatus:(int) i toState:(int) on
{
    NSString* host = [NSMutableString stringWithString: IPNumber];
    NSString *popenCurlString;
    
    if(on){
        popenCurlString = [NSString stringWithFormat: @"curl http://%@/tgi/control.tgi -d\"login=p:admin:admin&p=%c%c%c%c\" --connect-timeout 5",
           host, (i==1 ? '1':'u'), (i==2 ? '1':'u'), (i==3 ? '1':'u'),  (i==4 ? '1':'u') ];
    }else{
        popenCurlString = [NSString stringWithFormat: @"curl http://%@/tgi/control.tgi -d\"login=p:admin:admin&p=%c%c%c%c\" --connect-timeout 5",
           host, (i==1 ? '0':'u'), (i==2 ? '0':'u'), (i==3 ? '0':'u'),  (i==4 ? '0':'u') ];
    }
        NSLog(@"%@::%@: popenCurlString:%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd), popenCurlString);//TODO: DEBUG testing ...-tb-


    const char *pRequest = [popenCurlString cStringUsingEncoding:NSASCIIStringEncoding];

	int version = 0x8000;//error/parser/timeout flag
	FILE *p;
	p = popen(pRequest,"r");
	if(p==0){ fprintf(stderr, "could not start popen... -tb-\n"); return version; }
	pclose(p);
	//printf("version is: %i  0x%x\n",version,version);
	//NSLog(@"version  : %i   0x%x\n",version,version);
	return version;
}

- (void) turnOnOutlet:(int) i
{
		//NSString* cmd = [NSString stringWithFormat:@"%c%@%dON\r",0x1B,password,i];
		NSString* cmd = [NSString stringWithFormat:@"ON-CMD\n"];
		[self setPendingCmd:cmd];
		NSLog(@"LanNetio230 %d: %@ turned ON\n",[self uniqueIdNumber],[self outletName:i]);

        [self curlSetLanNetIOStatus: i toState:1];


//TODO: dev - fake the effect of a request -tb-
        [self setOutlet:i status:true];
return;



	if([password length]){
		NSString* cmd = [NSString stringWithFormat:@"%c%@%dON\r",0x1B,password,i];
		[self setPendingCmd:cmd];
		NSLog(@"LanNetio230 %d: %@ turned ON\n",[self uniqueIdNumber],[self outletName:i]);
	}
}

- (void) turnOffOutlet:(int) i
{
//TODO: dev
		//NSString* cmd = [NSString stringWithFormat:@"%c%@%dON\r",0x1B,password,i];
		NSString* cmd = [NSString stringWithFormat:@"OFF-CMD\n"];
		[self setPendingCmd:cmd];
		NSLog(@"LanNetio230 %d: %@ turned OFF\n",[self uniqueIdNumber],[self outletName:i]);

        [self curlSetLanNetIOStatus: i toState:0];

//TODO: dev - fake the effect of a request -tb-
        [self setOutlet:i status:false];
return;



	if([password length]){
		NSString* cmd = [NSString stringWithFormat:@"%c%@%dOFF\r",0x1B,password,i];
		[self setPendingCmd:cmd];
		NSLog(@"LanNetio230 %d: %@ turned OFF\n",[self uniqueIdNumber],[self outletName:i]);
	}
}

- (void) getStatus
{
    //DEBUG OUTPUT:  	
    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-


//TODO: IMPLEMENT THIS -tb-
//called from pollHardware ...



//TODO: dev READ BACK THE STATUS ...
//TODO: IMPLEMENT THIS -tb-

//[self ];
//outletStatus[0]=1;
//outletStatus[1]=1;
//outletStatus[2]=1;
return;



	if([password length]){
		NSString* cmd = [NSString stringWithFormat:@"%c%@?\r",0x1B,password];
		[self setPendingCmd:cmd];
	}
}

- (BOOL) outletStatus:(int)i
{
	if(i>=1 && i<=kLanNetio230OutletNum)return outletStatus[i];
	else return NO;
}

- (void) setOutlet:(int)i status:(BOOL)aValue
{
	if(i>=1 && i<=kLanNetio230OutletNum){
		BOOL changed = NO;
		if(aValue != outletStatus[i])changed = YES;
		outletStatus[i] = aValue;
		if(changed){
			[self setUpImage];
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"Channel"];
			[[NSNotificationCenter defaultCenter] postNotificationName:ORLanNetio230ModelStatusChanged object:self userInfo:userInfo];
		}
	}
}



#define HTMLPATTERN "<html>"

int curlGetLanNetIOStatus(const char * request)
{
	char buf[1024 * 4];
	char *cptr;
	FILE *p;
	int version = 0x8000;//error/parser/timeout flag
	p = popen(request,"r");
	if(p==0){ fprintf(stderr, "could not start popen... -tb-\n"); return version; }
	
	while (!feof(p)){
        fgets (buf , 1000 , p);//get full line
	    //fscanf(p,"%s",buf); //gets single characters
		     //NSLog(@"pattern  : %s\n",buf);
		if( (cptr=strstr(buf, HTMLPATTERN)) ){  // 
	         version = version & 0x7fff;
		     //NSLog(@"pattern found in line: %s\n",cptr);
		     //printf("pattern found in line: %s\n",cptr);
			 cptr = cptr + strlen(HTMLPATTERN);             // we expect e.g. <html>1 0 1 0</html>
		     //NSLog(@"pattern  : %s\n",cptr);
             if(atoi(cptr)) version |=0x1;
             //version = atoi(cptr);
		     //NSLog(@"pattern  parse: %s  version: %i atoi: %i\n",cptr,version,atoi(cptr));
		     //printf("pattern  parse: %s  version: %i atoi: %i\n",cptr,version,atoi(cptr));
             cptr=cptr+2;
             if(atoi(cptr)) version |=0x2;
             cptr++;cptr++;
			 if(atoi(cptr)) version |=0x4;
             cptr++;cptr++;
			 if(atoi(cptr)) version |=0x8;
			 //alternative: version = strtol(cptr, (char **) NULL, 10);
			 break;
		}
		if(feof(p)) break; //??? is this necessary??? -tb-
	};

	pclose(p);
	//printf("version is: %i  0x%x\n",version,version);
	//NSLog(@"version  : %i   0x%x\n",version,version);
	return version;
}




- (void) readStatus
{


		//NSString* host = [NSMutableString stringWithFormat: @"192.168.1.110"];
		NSString* host = [NSMutableString stringWithString: IPNumber];
		NSString* requestString = [NSMutableString stringWithFormat: @"http://%@/tgi/control.tgi", host];
		//NSString* requestString = [NSMutableString stringWithFormat: @"http://%@/tgi/control.tgi?login=p:admin:admin&p=l&q=q", host];
		//NSString* requestString = [NSMutableString stringWithFormat: @"http://%@/", host];
		//NSString* requestString = [NSMutableString stringWithFormat: @"http://%@/tgi/control.tgi?login=p:admin:admin&p=1111", host];

    //DEBUG OUTPUT:    NSLog(@"%@::%@: called with requestString:%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd), requestString);//TODO: DEBUG testing ...-tb-

    if([self isBusy]){
        //DEBUG OUTPUT:  	        NSLog(@"%@::%@: UNDER CONSTRUCTION! isBusy:%i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd), [self isBusy]);//TODO: DEBUG testing ...-tb-
    }
    
    
    
    NSString *popenCurlString = [NSString stringWithFormat: @"curl http://%@/tgi/control.tgi -d\"login=p:admin:admin&p=l\" --connect-timeout 5",host];
            //DEBUG OUTPUT:      NSLog(@"%@::%@: popenCurlString:%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd), popenCurlString);//TODO: DEBUG testing ...-tb-
    
    const char *pRequest = [popenCurlString cStringUsingEncoding:NSASCIIStringEncoding];
    int statusbits=curlGetLanNetIOStatus(pRequest);
    
    if(statusbits & 0x8000){//error/parser/timeout flag
	    NSLog(@"Error requesting LanNetIO status: got %i (  0x%x\n)\n",statusbits,statusbits);
        return;
    }
    
    //set the status bits
    [self setOutlet: 1 status: (statusbits & 0x1)];
    [self setOutlet: 2 status: (statusbits & 0x2)];
    [self setOutlet: 3 status: (statusbits & 0x4)];
    [self setOutlet: 4 status: (statusbits & 0x8)];
    
    
    
    return;
    //try to use the COCOA methods didn't work!
    requestType = kStatusRequest;
    [self sendRequestString: requestString];



}


- (void) sendRequestString:(NSString*)requestString
{
    //DEBUG OUTPUT:  	
    NSLog(@"%@::%@: UNDER CONSTRUCTION! (!) \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	//example: read status @"http://192.168.1.101/tgi/control.tgi?login=p:admin:admin&p=l"];
	//example: read status @"http://192.168.1.113/tgi/control.tgi?login=p:admin:admin&p=l"];
	//example: set states  @"http://192.168.1.101/tgi/control.tgi?login=p:admin:admin&p=10ui"];
	//example: set states  @"http://192.168.1.101/tgi/control.tgi?login=p:admin:admin&p=1011"];
    
    int showDebugOutput=1;
    
		if(requestString){
			NSURL* furl = [NSURL URLWithString: requestString];
            if(showDebugOutput) NSLog(@"Sending out request string: >>>%@<<<\n",requestString);//debugging
			NSMutableURLRequest* theRequest=[NSMutableURLRequest requestWithURL:furl  cachePolicy:NSURLRequestReloadIgnoringCacheData  timeoutInterval:kLanNetioTimeoutInterval];// make it configurable


    //NSString *postBody = @"foo=bar";   
    NSString *postBody = @"login=p:admin:admin&p=l";   

            if(showDebugOutput) NSLog(@"Sending http body: >>>%@<<<\n",postBody);//debugging

    NSData *postData = [postBody dataUsingEncoding:NSASCIIStringEncoding];

                [theRequest setHTTPMethod: @"POST"];
                //[theRequest setHTTPMethod: @"POST"];
    [theRequest setHTTPBody:postData];
    //[theRequest setValue:@"text/xml" forHTTPHeaderField:@"Accept"];
    //[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];  
    
    
    //[theRequest setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];  

            
            
            
            
			NSError        *error = nil;
            NSURLResponse  *urlResponse = nil;
NSData *response = 
            [NSURLConnection sendSynchronousRequest: theRequest returningResponse: &urlResponse error: &error];
            if(response)     NSLog(@"%@::%@: response: %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),response);//TODO: DEBUG testing ...-tb-
            else      NSLog(@"%@::%@: response: %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),@"is nil");
            if(error)     NSLog(@"%@::%@: error: %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),error);//TODO: DEBUG testing ...-tb-
            if(urlResponse)     NSLog(@"%@::%@: url response: %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),urlResponse);//TODO: DEBUG testing ...-tb-


            //   theURLConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
			//theURLConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
		}
}


#pragma mark ***Delegate Methods  for connection
/*
I left this (currently unused) code, I may reuse it later  - I would like to find out, why Cocoa HTTP requests didn't work ...

See my comment(s) at beginning of this file.
2013-10-24 Till.Bergmann@kit.edu
*/



- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //DEBUG OUTPUT:  	
    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //DEBUG OUTPUT:  	
    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	if(!receivedData)receivedData = [[NSMutableData data] retain];
	[receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection  didFailWithError:(NSError *)error
{	
    //DEBUG OUTPUT:  	
    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-


    int showDebugOutput=1;

    if(showDebugOutput) 
    NSLog(@"LanNetIO230 Loader::didFailWithError: Connection Failed :: descr. >>>%@<<<\n",[error localizedDescription]);//debugging timeouts

    if(connection==theURLConnection){
        // release the connection, and the data object
        [theURLConnection release];
		theURLConnection = nil;
        [receivedData release];
		receivedData = nil;
		NSLogError(@"LanNetIO230 Loader",@"Connection Failed",[error localizedDescription], nil);
        NSLog(@"ERROR:  ORLanNetio230Model::LanNetIO230 Loader-Connection Failed (%@)\n",[error localizedDescription]);
    }
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    //DEBUG OUTPUT:  	
    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-


    int showDebugOutput=1;
    
    
    if(showDebugOutput){//debug timeouts
        NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
        NSLogFont(aFont,@"Received data/string after URL request: BEGIN-%@-END\n",receivedData);
        //NSLogFont(aFont,@"Received data/string after URL request: BEGIN-%@-END\n",[receivedData description]);
    }
    //handle the request
	if(requestType == kStatusRequest){
        //DEBUG OUTPUT:  	
        NSLog(@"%@::%@: request was kStatusRequest \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
    }
	else if(requestType == kWriteRequest){
        //DEBUG OUTPUT:  	
        NSLog(@"%@::%@: request was kWriteRequest \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
    }
	else {
		NSLog(@"ORLanNetio230Model Loader: ERROR: unknown request Type %i!\n",requestType);
	}
    
    
	[receivedData release];
	receivedData = nil;
}




#pragma mark ***Delegate Methods
/*


See my comment(s) at beginning of this file.
2013-10-24 Till.Bergmann@kit.edu




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
    //DEBUG OUTPUT:  	
    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
return;


    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
		[self sendCmd];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    //DEBUG OUTPUT:  	
    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
return;


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
		[self disconnect];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	}
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    //DEBUG OUTPUT:  	
    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
return;


    if(inNetSocket == socket){
		
		[self setIsConnected:NO];
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

@implementation ORLanNetio230Model (private)
- (void) postCouchDBRecord
{
    //DEBUG OUTPUT:  	
    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
return;


    if([IPNumber length] && [password length]){
        NSMutableDictionary* values = [NSMutableDictionary dictionary];
        NSMutableArray* statesAndNames = [NSMutableArray array];
        int i;
        for(i=0;i<4;i++){
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
	//const char* bytes = [pendingCmd cStringUsingEncoding:NSASCIIStringEncoding];
    
    
    //DEBUG OUTPUT:  	    NSLog(@"%@::%@: UNDER CONSTRUCTION! pendingCmd:%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),pendingCmd);//TODO: DEBUG testing ...-tb-
    
    
    //TODO: dev - send http request from here ... -tb-
	//[socket write:bytes length:[pendingCmd length]];
    
	[self performSelector:@selector(timeout) withObject:nil afterDelay:0.5/*3*/];
}
		 
- (void) timeout
{
    //DEBUG OUTPUT:  	    NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-



	if([self isConnected]){
		//[self disconnect];
                [self setIsConnected:false];

	}
	else [self setPendingCmd:nil];
    
    
    
    
    //dev
    [self setPendingCmd:nil];
}
		 
- (void) setPendingCmd:(NSString*)aCmd
{
    //DEBUG OUTPUT:  	    NSLog(@"%@::%@: UNDER CONSTRUCTION! aCmd:%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aCmd);//TODO: DEBUG testing ...-tb-


	if(!aCmd){
		[pendingCmd release];
		pendingCmd = nil;
	}
	else if(![self isBusy]){
		[pendingCmd release];
		pendingCmd = [aCmd copy];
		[self connect];
	}
	else NSLog(@"LanNetIO230 cmd ignored -- busy\n");
	[[NSNotificationCenter defaultCenter] postNotificationName:ORLanNetio230ModelBusyChanged object:self];//busy:=isConnected
}

- (void) setupOutletNames
{
	outletNames = [[NSMutableArray array] retain];
	int i;
	for(i=0;i<kLanNetio230OutletNum+2;i++)[outletNames addObject:[NSString stringWithFormat:@"Outlet %d",i]];	
}



@end

