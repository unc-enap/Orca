//
//  ORTDS2024Model.m
//  Orca
//  Created by Mark Howe on Mon, May 9, 2018.
//  Copyright (c) 2018 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
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
#import "ORTDS2024Model.h"
#import "ORUSBInterface.h"
#import "ThreadWorker.h"

#define kMaxNumberOfPoints33220 0xFFFF

NSString* ORTDS2024SerialNumberChanged     = @"ORTDS2024SerialNumberChanged";
NSString* ORTDS2024USBInConnection         = @"ORTDS2024USBInConnection";
NSString* ORTDS2024USBNextConnection       = @"ORTDS2024USBNextConnection";
NSString* ORTDS2024USBInterfaceChanged     = @"ORTDS2024USBInterfaceChanged";
NSString* ORTDS2024Lock                    = @"ORTDS2024Lock";
NSString* ORTDS2024IsValidChanged		   = @"ORTDS2024IsValidChanged";
NSString* ORTDS2024PollTimeChanged         = @"ORTDS2024PollTimeChanged";
NSString* ORTDS2024ChanEnabledMaskChanged  = @"ORTDS2024ChanEnabledMaskChanged";
NSString* ORTDS2024BusyChanged             = @"ORTDS2024BusyChanged";
NSString* ORWaveFormDataChanged            = @"ORWaveFormDataChanged";

@interface ORTDS2024Model (private)
- (int32_t) writeReadFromDevice: (NSString*) aCommand data: (char*) aData
                   maxLength: (int32_t) aMaxLength;
- (id) threadToGetCurves:(NSDictionary*)userInfo thread:tw;
@end

@implementation ORTDS2024Model

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [curvesThread markAsCancelled];
    [curvesThread release];
    curvesThread = nil;
    
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [serialNumber release];
     [super dealloc];
}

- (void) sleep
{
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
	noUSBAlarm = nil;
	[super sleep];
}

- (void) wakeUp 
{
    if([self aWake])return;
	[super wakeUp];
	[self checkNoUsbAlarm];
}

- (void) makeConnectors
{
    ORConnector* connectorObj1 = [[ ORConnector alloc ]
                                  initAt: NSMakePoint( 0, 0 )
                                  withGuardian: self];
    [[ self connectors ] setObject: connectorObj1 forKey: ORTDS2024USBInConnection ];
    [ connectorObj1 setConnectorType: 'USBI' ];
    [ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to gpib outputs
    [connectorObj1 setOffColor:[NSColor yellowColor]];
    [ connectorObj1 release ];

    ORConnector* connectorObj2 = [[ ORConnector alloc ]
                                  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, 0 )
                                  withGuardian: self];
    [[ self connectors ] setObject: connectorObj2 forKey: ORTDS2024USBNextConnection ];
    [ connectorObj2 setConnectorType: 'USBO' ];
    [ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to gpib inputs
    [connectorObj2 setOffColor:[NSColor yellowColor]];
    [ connectorObj2 release ];
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	[self checkNoUsbAlarm];
}


- (void) makeMainController
{
    [self linkToController:@"ORTDS2024Controller"];
}

//- (NSString*) helpURL
//{
//	return @"GPIB/Aglient_33220a.html";
//}


- (void) awakeAfterDocumentLoaded
{
	@try {
		okToCheckUSB = YES;
		[self connectionChanged];
	}
	@catch(NSException* localException) {
	}
}

- (void) connectionChanged
{
	NSArray* interfaces = [[self getUSBController] interfacesForVenders:[self vendorIDs] products:[self productIDs]];
	NSString* sn = serialNumber;
	if([interfaces count] == 1 && ![sn length]){
		sn = [[interfaces objectAtIndex:0] serialNumber];
	}
	[self setSerialNumber:sn]; //to force usbinterface at doc startup
	[self checkNoUsbAlarm];	
	[[self objectConnectedTo:ORTDS2024USBNextConnection] connectionChanged];
	[self setUpImage];
}


-(void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"TDS2024"];
	
    NSSize theIconSize = [aCachedImage size];
    NSPoint theOffset = NSZeroPoint;
    
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];

    [aCachedImage drawAtPoint:theOffset fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];	
    if(!usbInterface || ![self getUSBController]){
        NSBezierPath* path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(20,2)];
        [path lineToPoint:NSMakePoint(40,22)];
        [path moveToPoint:NSMakePoint(40,2)];
        [path lineToPoint:NSMakePoint(20,22)];
        [path setLineWidth:3];
        [[NSColor redColor] set];
        [path stroke];
    }    
	
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
}

- (id)  dialogLock
{
	return @"ORTDS2024Lock";
}

- (NSString*) title 
{
   return [NSString stringWithFormat:@"TDS2024 (Serial# %@)",[usbInterface serialNumber]];
}

- (NSArray*) vendorIDs
{
	return @[@0x0699,@0x0699];
}

- (NSArray*) productIDs
{
	return @[@0x036a,@0x03a2];
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORTDS2024USBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
	return [super acceptsGuardian:aGuardian] ||
    [aGuardian isMemberOfClass:NSClassFromString(@"ORMJDVacuumModel")];
}

#pragma mark ***Accessors

- (unsigned short) chanEnabledMask { return chanEnabledMask; }
- (void) setChanEnabledMask:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChanEnabledMask:chanEnabledMask];
    chanEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTDS2024ChanEnabledMaskChanged object:self];
}
- (void) setChanEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChanEnabled:aChan withValue:(chanEnabledMask>>aChan)&0x1];
    if(aState) chanEnabledMask |= (1L<<aChan);
    else chanEnabledMask &= ~(1L<<aChan);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTDS2024ChanEnabledMaskChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
	[self pollHardware];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTDS2024PollTimeChanged object:self];
}

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(pollTime==0)return;
    [self getCurves];
    [self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (NSString*) serialNumber
{
    return serialNumber;
}

- (void) setSerialNumber:(NSString*)aSerialNumber
{
	if(!aSerialNumber)aSerialNumber = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setSerialNumber:serialNumber];
    
    [serialNumber autorelease];
    serialNumber = [aSerialNumber copy];    
	
	if(!serialNumber){
		[[self getUSBController] releaseInterfaceFor:self];
	}
	else [[self getUSBController] claimInterfaceWithSerialNumber:serialNumber for:self];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTDS2024SerialNumberChanged object:self];
}

- (ORUSBInterface*) usbInterface
{
	return usbInterface;
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{
    [usbInterface release];
    usbInterface = anInterface;
    [usbInterface retain];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName: ORTDS2024USBInterfaceChanged
     object: self];
    
    [self setUpImage];
}

- (void) interfaceAdded:(NSNotification*)aNote
{
    [[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
    [self checkNoUsbAlarm];
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
    ORUSBInterface* theInterfaceRemoved = [[aNote userInfo] objectForKey:@"USBInterface"];
    if((usbInterface == theInterfaceRemoved) && serialNumber){
        [self setUsbInterface:nil];
        [self checkNoUsbAlarm];
    }
}

- (void) checkNoUsbAlarm
{
	if(!okToCheckUSB) return;
	if((usbInterface && [self getUSBController]) || !guardian){
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(guardian && [self aWake]){
			if(!noUSBAlarm){
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for TD2024"] severity:kHardwareAlarm];
				[noUSBAlarm setHelpString:@"\n\nThe USB interface is no longer available for this object. This could mean the cable is disconnected or the power is off"];
				[noUSBAlarm setSticky:YES];		
			}
			[noUSBAlarm setAcknowledged:NO];
			[noUSBAlarm postAlarm];
		}
	}
	[self setUpImage];
}

- (NSArray*) usbInterfaces
{
    return [[self getUSBController]  interfacesForVenders:[self vendorIDs] products:[self productIDs]];
}

- (NSString*) usbInterfaceDescription
{
	if(usbInterface)return [usbInterface description];
	else return @"?";
}

- (void) registerWithUSB:(id)usb
{
	[usb registerForUSBNotifications:self];
}

- (NSString*) hwName
{
	if(usbInterface)return [usbInterface deviceName];
	else return @"?";
}

- (void) logSystemResponse
{
}

#pragma mark •••Hardware Access

- (void) writeCommand:(NSString*)aCmd
{
    if([aCmd rangeOfString:@"?"].location != NSNotFound){
        char  reply[256];
        int32_t n = [self writeReadFromDevice: aCmd
                                      data: reply
                                 maxLength: 256 ];
        n = MIN(256,n);
        reply[n] = '\n';
        NSString* s =  [NSString stringWithCString:reply encoding:NSASCIIStringEncoding];
        NSInteger nlPos = [s rangeOfString:@"\n"].location;
        if(nlPos != NSNotFound){
            s = [s substringWithRange:NSMakeRange(0,nlPos)];
            NSLog(@"%@\n",s);
        }
    }
    else {
        [self writeToDevice: aCmd];
    }
}

- (void) readWaveformPreamble
{
    char  reply[256];
    int32_t n = [self writeReadFromDevice: @"WFMPre?"
                                  data: reply
                             maxLength: 256 ];
    reply[n] = '\n';
    NSString* s =  [NSString stringWithCString:reply encoding:NSASCIIStringEncoding];
    NSInteger nlPos = [s rangeOfString:@"\n"].location;
    if(nlPos != NSNotFound){
        s = [s substringWithRange:NSMakeRange(0,nlPos)];
        NSLog(@"%@\n",s);
    }
}
- (void) readDataInfo
{
    char  reply[256];
    int32_t n = [self writeReadFromDevice: @"DAT?"
                                  data: reply
                             maxLength: 256 ];
    reply[n] = '\n';
    NSString* s =  [NSString stringWithCString:reply encoding:NSASCIIStringEncoding];
    NSInteger nlPos = [s rangeOfString:@"\n"].location;
    if(nlPos != NSNotFound){
        s = [s substringWithRange:NSMakeRange(0,nlPos)];
        NSLog(@"%@\n",s);
    }
}
- (void) readIDString
{
    char  reply[256];
    int32_t n = [self writeReadFromDevice: @"*IDN?"
                                  data: reply
                             maxLength: 256 ];
    reply[n] = '\n';
    NSString* s =  [NSString stringWithCString:reply encoding:NSASCIIStringEncoding];
    NSInteger nlPos = [s rangeOfString:@"\n"].location;
    if(nlPos != NSNotFound){
        s = [s substringWithRange:NSMakeRange(0,nlPos)];
        NSLog(@"%@\n",s);
    }
}

- (void) getCurves
{
    if(!curvesThread){
        int i,chan;
        for(chan=0;chan<4;chan++){
            for(i=0;i<2500;i++)waveForm[chan][i] = 0;
            wfmPre[chan][0] = '\0';
        }

        curvesThread = [[ThreadWorker workOn:self
                                withSelector:@selector(threadToGetCurves:thread:)
                                         withObject:nil
                                     didEndSelector:@selector(curvesThreadFinished:)] retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORTDS2024BusyChanged object: self];
    }
}

- (void) curvesThreadFinished:(NSDictionary*)userInfo
{

    [curvesThread release];
    curvesThread = nil;
    [[NSNotificationCenter defaultCenter]  postNotificationName:ORWaveFormDataChanged object:self];
    [self postCouchDB];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTDS2024BusyChanged object: self];
}

- (void) postCouchDB
{
    int curve;
    for(curve = 0;curve<4;curve++){
        curveStr[curve] = [NSMutableString stringWithCapacity:2500];
        int i;
        if(chanEnabledMask & (0x1<<curve)){
            for(i=6;i<2500-6;i++){
                [curveStr[curve] appendFormat:@"%d,",[self dataSet:curve valueAtChannel:i]];
                
            }
        }
        else {
            [curveStr[curve] appendString:@"0"];
        }
    }
    NSDictionary* values = [NSDictionary dictionaryWithObjectsAndKeys:
                                [self fullID],   @"name",
                                [NSArray arrayWithObjects:
                                 curveStr[0],
                                 curveStr[1],
                                 curveStr[2],
                                 curveStr[3],
                                 nil], @"waveforms",
                            [NSArray arrayWithObjects:
                             [NSString stringWithCString:wfmPre[0] encoding:NSASCIIStringEncoding],
                             [NSString stringWithCString:wfmPre[1] encoding:NSASCIIStringEncoding],
                             [NSString stringWithCString:wfmPre[2] encoding:NSASCIIStringEncoding],
                             [NSString stringWithCString:wfmPre[3] encoding:NSASCIIStringEncoding],
                             nil], @"wfmPre",
                                [NSNumber numberWithInt:    chanEnabledMask], @"enabledMask",
                                
                                nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];

}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setSerialNumber:          [decoder decodeObjectForKey:    @"serialNumber"]];
    [self setPollTime:              [decoder decodeIntForKey:       @"pollTime"]];
    [self setChanEnabledMask:       [decoder decodeIntegerForKey:       @"chanEnabledMask"]];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:serialNumber      forKey:@"serialNumber"];
    [encoder encodeInteger:pollTime             forKey:@"pollTime"];
    [encoder encodeInteger:chanEnabledMask      forKey:@"chanEnabledMask"];
}

#pragma mark ***Comm methods
- (int32_t) readFromDevice: (char*) aData maxLength: (uint32_t) aMaxLength
{
    if(usbInterface && [self getUSBController]){
        @try {
            return [usbInterface readUSB488:aData length:(uint32_t)aMaxLength];;
        }
        @catch(NSException* e){
        }
    }
    else {
        NSString *errorMsg = @"Must establish connection prior to issuing command\n";
        [NSException raise: @"TDS2024 Error" format: @"%@",errorMsg];
    }
    return 0;
}

- (void) writeToDevice: (NSString*) aCommand
{
    if(usbInterface && [self getUSBController]){
        aCommand = [aCommand stringByAppendingString:@"\n"];
        [usbInterface writeUSB488Command:aCommand eom:YES];
    }
    else {
        NSString *errorMsg = @"Must establish connection prior to issuing command\n";
        [NSException raise: @"TDS2024 Error" format:@"%@", errorMsg];
    }
}

- (void) makeUSBClaim:(NSString*)aSerialNumber
{
    NSLog(@"claimed\n");
}

- (int) numPoints:(int)chan
{
    return numPoints[chan]-6;
}

- (int32_t) dataSet:(int)chan valueAtChannel:(int)x
{
    return waveForm[chan][x+6]; //first 6 bytes are '#42500'
}

- (BOOL) curveIsBusy
{
    return curvesThread!=nil;
}

@end

@implementation ORTDS2024Model (private)

- (id) threadToGetCurves:(NSDictionary*)userInfo thread:tw

{
    int chan;
    for(chan=0;chan<4;chan++){
        if([tw cancelled])break;

        int i;
        if(!(chanEnabledMask & (0x1<<chan))){
            continue;
        }

        @try {
            [self writeToDevice:[NSString stringWithFormat:@"DAT:SOU CH%d",chan+1]];
            [self writeToDevice:@"DATa:ENCdg RPBINARY"];
            [self writeToDevice:@"DATa:WIDth 1"];

            [self writeToDevice:@"DATa:START 1"];
            [self writeToDevice:@"DATa:STOP 2500"];
            
            int32_t numBtyes = [self writeReadFromDevice: @"WFMPre?"
                                      data: wfmPre[chan]
                                 maxLength: 256];
            wfmPre[chan][numBtyes] = '\0';
            
            unsigned char  reply[2600];
            int32_t n1 = 0;
            int32_t n2 = 0;
            int32_t n3 = 0;
            n1 = [self writeReadFromDevice: @"CURVE?"
                                      data: (char*)reply
                                 maxLength: 2500];
            n1 = MIN(1024,n1);
            if([tw cancelled])break;

            if(n1!=0){
                for(i=0;i<n1;i++)waveForm[chan][i] = reply[i];
                
                n2 = [self readFromDevice: (char*)reply maxLength:2500];
                n2 = MIN(1024,n2);
                if([tw cancelled])break;

                if(n2!=0){
                    for(i=0;i<n2;i++) waveForm[chan][i+n1] = reply[i];
                    n3 = [self readFromDevice: (char*)reply maxLength:2500 ];
                    n3 = MIN(452,n3);
                    if([tw cancelled])break;

                    for(i=0;i<n3;i++)waveForm[chan][i+n1+n2] = reply[i];
                }
            }
            int32_t total = n1+n2+n3;
            if(total > 2500)total = 2500;
            numPoints[chan] = (int)total;
        }
        @catch(NSException* e){
        }
    }
    return @"done";
}

- (int32_t) writeReadFromDevice: (NSString*) aCommand data: (char*) aData
                   maxLength: (int32_t) aMaxLength
{
    [self writeToDevice: aCommand];
    return [self readFromDevice: aData maxLength: aMaxLength];
}

@end
