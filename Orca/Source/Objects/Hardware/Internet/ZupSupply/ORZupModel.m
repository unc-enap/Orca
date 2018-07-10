//
//  ORZupModel.m
//  Orca
//
//  Created by Mark Howe on Monday March 16,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORZupModel.h"

#import "ORHVRampItem.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORSerialPortList.h"

NSString* ORZupModelActualVoltageChanged = @"ORZupModelActualVoltageChanged";
NSString* ORZupModelStatusEnableMaskChanged = @"ORZupModelStatusEnableMaskChanged";
NSString* ORZupModelFaultEnableMaskChanged = @"ORZupModelFaultEnableMaskChanged";
NSString* ORZupModelFaultRegisterChanged	= @"ORZupModelFaultRegisterChanged";
NSString* ORZupModelStatusRegisterChanged	= @"ORZupModelStatusRegisterChanged";
NSString* ORZupModelCurrentChanged			= @"ORZupModelCurrentChanged";
NSString* ORZupModelActualCurrentChanged	= @"ORZupModelActualCurrentChanged";
NSString* ORZupModelOutputStateChanged		= @"ORZupModelOutputStateChanged";
NSString* ORZupModelBoardAddressChanged		= @"ORZupModelBoardAddressChanged";
NSString* ORZupLock							= @"ORZupLock";
NSString* ORZupModelSerialPortChanged		= @"ORZupModelSerialPortChanged";
NSString* ORZupModelPortNameChanged			= @"ORZupModelPortNameChanged";
NSString* ORZupModelPortStateChanged		= @"ORZupModelPortStateChanged";

@interface ORZupModel (private)
- (void) timeout;
- (void) processOneCommandFromQueue;
@end

@implementation ORZupModel

- (void) makeMainController
{
    [self linkToController:@"ORZupController"];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [buffer release];
	[cmdQueue release];
	[lastRequest release];
    [portName release];
	[inComingData release];
    if([serialPort isOpen]){
        [serialPort close];
    }
	[serialPort setDelegate:nil];
    [serialPort release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"ZupIcon"]];
}

- (void) awakeAfterDocumentLoaded
{
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];
}

- (void) addRampItem
{
	ORHVRampItem* aRampItem = [[ORHVRampItem alloc] initWithOwner:self];
	[rampItems addObject:aRampItem];
	[aRampItem release];
}

- (void) ensureMinimumNumberOfRampItems
{
	if(!rampItems)[self setRampItems:[NSMutableArray array]];
	if([rampItems count] == 0){
		[[self undoManager] disableUndoRegistration];
		ORHVRampItem* aRampItem = [[ORHVRampItem alloc] initWithOwner:self];
		[aRampItem setTargetName:[self className]];
		[aRampItem setParameterName:@"Voltage"];
		[aRampItem loadParams:self];
		[rampItems addObject:aRampItem];
		[aRampItem release];
	
		[[self undoManager] enableUndoRegistration];
	}
}

#pragma mark ***Accessors

- (float) actualVoltage
{
    return actualVoltage;
}

- (void) setActualVoltage:(float)aActualVoltage
{
    actualVoltage = aActualVoltage;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelActualVoltageChanged object:self];
}

- (int) statusEnableMask
{
    return statusEnableMask;
}

- (void) setStatusEnableMask:(int)aStatusEnableMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStatusEnableMask:statusEnableMask];
    
    statusEnableMask = aStatusEnableMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelStatusEnableMaskChanged object:self];
}

- (int) faultEnableMask
{
    return faultEnableMask;
}

- (void) setFaultEnableMask:(int)aFaultEnableMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFaultEnableMask:faultEnableMask];
    
    faultEnableMask = aFaultEnableMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelFaultEnableMaskChanged object:self];
}

- (int) faultRegister
{
    return faultRegister;
}

- (void) setFaultRegister:(int)aFaultRegister
{
    faultRegister = aFaultRegister;
	NSLog(@"fault:0x%x\n",aFaultRegister);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelFaultRegisterChanged object:self];
}

- (int) statusRegister
{
    return statusRegister;
}

- (void) setStatusRegister:(int)aStatusRegister
{
    statusRegister = aStatusRegister;
	NSLog(@"status:0x%x\n",statusRegister);

    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelStatusRegisterChanged object:self];
}

- (float) current
{
    return current;
}

- (void) setCurrent:(float)aCurrent
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCurrent:current];
    
    current = aCurrent;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelCurrentChanged object:self];
}

- (float) actualCurrent
{
    return actualCurrent;
}

- (void) setActualCurrent:(float)aActualCurrent
{
    [[[self undoManager] prepareWithInvocationTarget:self] setActualCurrent:actualCurrent];
    
    actualCurrent = aActualCurrent;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelActualCurrentChanged object:self];
}
- (BOOL) sentAddress
{
	return sentAddress;
}

- (BOOL) outputState
{
    return outputState;
}

- (void) setOutputState:(BOOL)aOutputState
{
    outputState = aOutputState;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelOutputStateChanged object:self];
}

- (int) boardAddress
{
    return boardAddress;
}

- (void) setBoardAddress:(int)aBoardAddress
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBoardAddress:boardAddress];
    
    boardAddress = aBoardAddress;
	sentAddress = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelBoardAddressChanged object:self];
}

- (NSString*) lockName
{
	return ORZupLock;
}

//helper methods (useful for scripting)
- (void) setImmediatelyToVoltage:(float)aVoltage
{
	int dummy = 0;
	[self setVoltage:dummy withValue:aVoltage];
	[self loadDac:dummy];
}

- (void) setImmediatelyToCurrent:(float)aCurrent
{
	NSString* s = [NSString stringWithFormat:@"PC %f",aCurrent];
	[self sendCmd:s];
}


//these needed to interface with the ramper
- (float) voltage:(int)dummy
{
	return voltage;
}

- (void) setVoltage:(int)dummy withValue:(float)aValue
{
	voltage = aValue;	
}

//these are for convienence
- (void) setVoltage:(float)aValue
{
	voltage = aValue;	
}

- (float)voltage
{
	return voltage;
}

- (void) loadDac:(int)dummy
{
	if(![self outputState]){
		NSException* e = [NSException exceptionWithName:@"No Power" reason:@"Power must be on" userInfo:nil];
		[e raise];
	}
	[self sendCmd:@"MC?"];
	[self sendCmd:@"MV?"];
	NSString* s = [NSString stringWithFormat:@"PV %f",[self voltage:0]];
	[self sendCmd:s];
}

- (void) getStatus
{
	[self sendCmd:@"OUT?"];
	[self sendCmd:@"STT?"];
}

- (void) turnOff
{
	[self sendCmd:@"OUT 0"];
	[self sendCmd:@"OUT?"];
}

- (float) upperLimit
{
	return 300;
}

- (float) lowerLimit
{
	return 0;
}

- (void) stopRamping:(ORRampItem*)anItem turnOff:(BOOL)turnOff
{
	if([self outputState])[self loadDac:0];
	[super stopRamping:anItem turnOff:turnOff];
	if(turnOff)[self turnOff];
	[self getStatus];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setStatusEnableMask:[decoder decodeIntForKey:@"ORZupModelStatusEnableMask"]];
    [self setFaultEnableMask:[decoder decodeIntForKey:@"ORZupModelFaultEnableMask"]];
    [self setCurrent:[decoder decodeFloatForKey:@"ORZupModelCurrent"]];
    [self setActualCurrent:[decoder decodeFloatForKey:@"ORZupModelActualCurrent"]];
    [self setBoardAddress:	[decoder decodeIntForKey:	 @"boardAddress"]];
	[self setPortWasOpen:	[decoder decodeBoolForKey:	 @"portWasOpen"]];
    [self setPortName:		[decoder decodeObjectForKey: @"portName"]];
    [[self undoManager] enableUndoRegistration];    
    [self registerNotificationObservers];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:statusEnableMask forKey:@"ORZupModelStatusEnableMask"];
    [encoder encodeInt:faultEnableMask forKey:@"ORZupModelFaultEnableMask"];
    [encoder encodeFloat:current forKey:@"ORZupModelCurrent"];
    [encoder encodeFloat:actualCurrent forKey:@"ORZupModelActualCurrent"];
    [encoder encodeInt:boardAddress		forKey:@"boardAddress"];
    [encoder encodeBool:portWasOpen		forKey: @"portWasOpen"];
    [encoder encodeObject:portName		forKey: @"portName"];
}

- (void) sendCmd:(NSString*)aCommand value:(short)hexData
{
	if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
	if(!sentAddress){
		NSString* addressCmd = [NSString stringWithFormat:@"ADR %d\r",[self boardAddress]];
		[cmdQueue addObject:[addressCmd dataUsingEncoding:NSASCIIStringEncoding]];
	}
	NSMutableData* theCommand = [NSMutableData data];
	[theCommand appendData:[aCommand dataUsingEncoding:NSASCIIStringEncoding]];
	[theCommand appendData:[@" " dataUsingEncoding:NSASCIIStringEncoding]];
	[theCommand appendBytes:&hexData length:2];
	[theCommand appendData:[@"\r" dataUsingEncoding:NSASCIIStringEncoding]];
	
	[cmdQueue addObject:theCommand];
	if(!lastRequest)[self processOneCommandFromQueue];
	
}

- (void) sendCmd:(NSString*)aCommand
{	
	if(![aCommand hasSuffix:@"\r"])aCommand = [aCommand stringByAppendingString:@"\r"];
	if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
	if(!sentAddress){
		NSString* addressCmd = [NSString stringWithFormat:@"ADR %d\r",[self boardAddress]];
		[cmdQueue addObject:[addressCmd dataUsingEncoding:NSASCIIStringEncoding]];
	}
	
	[cmdQueue addObject:[aCommand dataUsingEncoding:NSASCIIStringEncoding]];
	if(!lastRequest)[self processOneCommandFromQueue];
}

- (SEL) getMethodSelector  { return @selector(voltage:); }
- (SEL) setMethodSelector  { return @selector(setVoltage:withValue:); }
- (SEL) initMethodSelector  { return @selector(initBoard); }

- (void) initBoard
{
}

- (int) numberOfChannels
{
    return 1;
}

- (NSData*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(NSData*)aRequest
{
	[aRequest retain];
	[lastRequest release];
	lastRequest = aRequest;    
}

- (BOOL) portWasOpen
{
    return portWasOpen;
}

- (void) setPortWasOpen:(BOOL)aPortWasOpen
{
    portWasOpen = aPortWasOpen;
}

- (NSString*) portName
{
    return portName;
}

- (void) setPortName:(NSString*)aPortName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortName:portName];
    
    if(![aPortName isEqualToString:portName]){
        [portName autorelease];
        portName = [aPortName copy];    
		
        BOOL valid = NO;
        NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
        ORSerialPort *aPort;
        while (aPort = [enumerator nextObject]) {
            if([portName isEqualToString:[aPort name]]){
                [self setSerialPort:aPort];
                if(portWasOpen){
                    [self openPort:YES];
				}
                valid = YES;
                break;
            }
        } 
        if(!valid){
            [self setSerialPort:nil];
        }       
    }
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelPortNameChanged object:self];
}

- (ORSerialPort*) serialPort
{
    return serialPort;
}

- (void) setSerialPort:(ORSerialPort*)aSerialPort
{
    [aSerialPort retain];
    [serialPort release];
    serialPort = aSerialPort;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelSerialPortChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
        [serialPort open];
		[serialPort setSpeed:9600];
		[serialPort setParityNone];
		[serialPort setStopBits2:NO];
		[serialPort setDataBits:8];
		[serialPort commitChanges];

		[serialPort setDelegate:self];
		sentAddress = NO;

	}
    else      [serialPort close];
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelPortStateChanged object:self];
    
}
- (void) dataReceived:(NSNotification*)note
{
	BOOL done = NO;
	if(!lastRequest)return;
	
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		if(!inComingData)inComingData = [[NSMutableData data] retain];
        [inComingData appendData:[[note userInfo] objectForKey:@"data"]];
		
		NSString* theLastCommand = [[[NSString alloc] initWithData:lastRequest 
														  encoding:NSASCIIStringEncoding] autorelease];
		theLastCommand = [theLastCommand uppercaseString];
		
		NSString* theResponse = [[[NSString alloc] initWithData:inComingData 
														  encoding:NSASCIIStringEncoding] autorelease];
		
		theLastCommand	= [theLastCommand uppercaseString];
		theResponse		= [theResponse uppercaseString];
		if([theResponse hasPrefix:@"I"]){
			NSString* hexString = [theResponse substringFromIndex:3];
			char s[255];
			[hexString getCString:s maxLength:255 encoding:NSASCIIStringEncoding];	// NO return if conversion not possible due to encoding errors or too small of a buffer. The buffer should include room for maxBufferCount bytes plus the NULL termination character, which this method adds. (So pass in one less than the size of the buffer.)
			int theValue = [[NSNumber numberWithLong:strtoul(s,0,16)] intValue];
			[self setStatusRegister:theValue];
		}
		else if([theResponse hasPrefix:@"OK"]){
			if([theLastCommand hasPrefix:@"ADR"]){
				sentAddress = YES;
			}
			done = YES;
		}
		else if([theLastCommand hasPrefix:@"C"]){
			NSLog(@"%@\n",theResponse);
			done = YES;
		}		
		else if([theLastCommand rangeOfString:@"?"].location != NSNotFound){
			if([theLastCommand hasPrefix:@"OUT"]){
				if([theResponse hasPrefix:@"ON"])		[self setOutputState:YES];
				else if([theResponse hasPrefix:@"OFF"])	[self setOutputState:NO];
				done = YES;
			}
			else if([theLastCommand hasPrefix:@"PV"]){
				float theVoltage = [theResponse floatValue];
				[self setVoltage:theVoltage];
				[[rampItems objectAtIndex:0] placeCurrentValue];
				done = YES;
			}
			else if([theLastCommand hasPrefix:@"MV"]){
				float theVoltage = [theResponse floatValue];
				[self setActualVoltage:theVoltage];
				done = YES;
			}
			else if([theLastCommand hasPrefix:@"MC"]){
				//float theCurrent = [theResponse floatValue];
				//[self actualCurrent:theCurrent];
				done = YES;
			}
			else if([theLastCommand hasPrefix:@"STT"]){
				NSArray* parts = [theResponse componentsSeparatedByString:@","];
				if([parts count]>=6){
					id part;
					NSEnumerator* e = [parts objectEnumerator];
					while(part = [e nextObject]){
						if([part hasPrefix:@"MV("]){
							float theValue = [[part substringFromIndex:3] floatValue];
							[self setActualVoltage:theValue];
						}
						else if([part hasPrefix:@"PV("]){
							float theValue = [[part substringFromIndex:3] floatValue];
							[self setVoltage:theValue];
							[[rampItems objectAtIndex:0] placeCurrentValue];
						}
						else if([part hasPrefix:@"MC("]){
							float theValue = [[part substringFromIndex:3] floatValue];
							[self setActualCurrent:theValue];
						}
						else if([part hasPrefix:@"PC("]){
							float theValue = [[part substringFromIndex:3] floatValue];
							[self setCurrent:theValue];
						}
						else if([part hasPrefix:@"SR("]){
							NSString* hexString = [part substringFromIndex:3];
							char s[255];
							[hexString getCString:s maxLength:255 encoding:NSASCIIStringEncoding];	// NO return if conversion not possible due to encoding errors or too small of a buffer. The buffer should include room for maxBufferCount bytes plus the NULL termination character, which this method adds. (So pass in one less than the size of the buffer.)
							int theValue = [[NSNumber numberWithLong:strtoul(s,0,16)] intValue];
							[self setStatusRegister:theValue];
						}
						else if([part hasPrefix:@"FR("]){
							NSString* hexString = [part substringFromIndex:3];
							char s[255];
							[hexString getCString:s maxLength:255 encoding:NSASCIIStringEncoding];	// NO return if conversion not possible due to encoding errors or too small of a buffer. The buffer should include room for maxBufferCount bytes plus the NULL termination character, which this method adds. (So pass in one less than the size of the buffer.)
							int theValue = [[NSNumber numberWithLong:strtoul(s,0,16)] intValue];
							[self setFaultRegister:theValue];
						}
					}
					done = YES;
				}
			}
		}	
		
		if(done){
			[inComingData release];
			inComingData = nil;
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
			[self setLastRequest:nil];			 //clear the last request
			[self processOneCommandFromQueue];	 //do the next command in the queue
		}
	}
}

- (void) togglePower
{
	NSString* s = [NSString stringWithFormat:@"OUT %d",![self outputState]];
	[self sendCmd:s];
	[self sendCmd:@"OUT?"];
}

- (void) sendFailEnableMask
{
	NSString* s = [NSString stringWithFormat:@"FENA %02x",[self faultEnableMask]];
	[self sendCmd:s];
}

- (void) sendStatusEnableMask
{
	NSString* s = [NSString stringWithFormat:@"SENA %02x",[self statusEnableMask]];
	[self sendCmd:s];
}

- (void) serialPortWriteProgress:(NSDictionary *)dataDictionary;
{
}

@end

@implementation ORZupModel (private)

- (void) timeout
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"command timeout",@"ZUP",nil);
	[self setLastRequest:nil];
	[cmdQueue removeAllObjects];
	sentAddress = NO;
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) processOneCommandFromQueue
{
	if([cmdQueue count] == 0) return;
	NSData* cmdData = [[[cmdQueue objectAtIndex:0] retain] autorelease];
	[cmdQueue removeObjectAtIndex:0];
	[self setLastRequest:cmdData];
	[serialPort writeDataInBackground:cmdData];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:1];
	
}

@end
