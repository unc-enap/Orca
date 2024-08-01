//
//  ORSHT35Model.m
//  Orca
//
//  Created by Mark Howe on 08/1/2024.
//  Copyright 2024 University of North Carolina. All rights reserved.
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
#import "ORSHT35Model.h"
#import "ORTimeRate.h"

NSString* ORSHT35ModelI2CAddressChanged	    = @"ORSHT35ModelI2CAddressChanged";
NSString* ORSHT35ModelI2CInterfaceChanged	= @"ORSHT35ModelI2CInterfaceChanged";
NSString* ORSHT35ModelTemperatureChanged    = @"ORSHT35ModelTemperatureChanged";
NSString* ORSHT35ModelHumidityChanged       = @"ORSHT35ModelHumidityChanged";
NSString* ORSHT35ModelUpdateIntervalChanged = @"ORSHT35ModelUpdateIntervalChanged";
NSString* ORSHT35ModelRunningChanged        = @"ORSHT35ModelRunningChanged";
NSString* ORSHT35ModelLock					= @"ORSHT35ModelLock";

static NSString* ORSHT35I2CInConnection     = @"ORSHT35I2CInConnection";
static NSString* ORSHT35I2COutConnection    = @"ORSHT35I2COutConnection";

@implementation ORSHT35Model
- (void) makeConnectors
{
	ORConnector* aConnector = [[ ORConnector alloc ]
								  initAt: NSMakePoint( 0, [self frame].size.height/2 )
								  withGuardian: self];
	[[self connectors] setObject: aConnector forKey: ORSHT35I2CInConnection ];
	[aConnector setConnectorType: 'I2CI' ];
	[aConnector addRestrictedConnectionType: 'I2CO' ]; //can only connect to i2c outputs
	[aConnector setOffColor:[NSColor magentaColor]];
	[aConnector release ];
	
	aConnector = [[ ORConnector alloc ]
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, [self frame].size.height/2 )
								  withGuardian: self];
    
	[[self connectors] setObject: aConnector forKey: ORSHT35I2COutConnection ];
	[aConnector setConnectorType: 'I2CO' ];
	[aConnector addRestrictedConnectionType: 'I2CI' ]; //can only connect to ic2 inputs
	[aConnector setOffColor:[NSColor magentaColor]];
	[aConnector release ];
}

- (void) makeMainController
{
    [self linkToController:@"ORSHT35Controller"];
}

- (NSString*) helpURL
{
	return @"";
}


- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [(id)i2cMaster release];
    [temperatureRate release];
    [humidityRate release];
    [super dealloc];
}

- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [(id)i2cMaster release];
    i2cMaster = nil;
    [super sleep];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		[self connectionChanged];
	}
	@catch(NSException* localException) {
	}
}

- (void) connectionChanged
{
	[[self objectConnectedTo:ORSHT35I2COutConnection] connectionChanged];
    //get rid of the connected obj... will re-get if reconnected
    [(id)i2cMaster release];
    i2cMaster = nil;
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SHT35.tif"]];
}

- (NSString*) title 
{
    return [NSString stringWithFormat:@"SHT35 (I2C 0x%x)",(int)[self i2cAddress]];
}

#pragma mark ***Accessors
- (uint32_t) i2cAddress
{
    return i2cAddress;
}

- (void) setI2CAddress:(uint32_t)anAddress
{
    [[[self undoManager] prepareWithInvocationTarget:self] setI2CAddress:i2cAddress];
    
    i2cAddress = anAddress;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSHT35ModelI2CAddressChanged object:self];
}

- (int)   updateInterval
{
    return updateInterval;
}

- (void)  setUpdateInterval:(int)milliSecs
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUpdateInterval:updateInterval];
    //also a PU tag... see controller
    updateInterval = milliSecs;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSHT35ModelUpdateIntervalChanged object:self];
}

- (int)  temperature
{
    return temperature;
}

- (void) setTemperature:(int)aValue
{
    temperature = aValue;
    
    //the rate sampling is 30 seconds, change it as needed
    if(temperatureRate == nil) temperatureRate = [[ORTimeRate alloc] init];
    [temperatureRate addDataToTimeAverage:temperature];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSHT35ModelTemperatureChanged object:self];
}

- (int)  humidity
{
    return humidity;
}

- (void) setHumidity:(int)aValue
{
    humidity = aValue;
    
    if(humidityRate == nil) humidityRate = [[ORTimeRate alloc] init];
    [humidityRate addDataToTimeAverage:humidity];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSHT35ModelHumidityChanged object:self];
}

- (NSString*) hwName
{
	return @"?";
}

#pragma mark ***update methods
- (BOOL) running
{
    return running;
}

- (void) setRunning:(BOOL)aState
{
    running = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSHT35ModelRunningChanged object:self];
}

- (void) pollNow
{
    [self readI2C];
}

- (void) startStopPolling
{
    if(running){
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self setRunning:NO];
    }
    else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        if(updateInterval>0){
            [self performSelector:@selector(pollAfterDelay) withObject:nil afterDelay:1000./updateInterval];
        }
        else {
            [self performSelector:@selector(pollAfterDelay) withObject:nil afterDelay:.01];
        }
        [self setRunning:YES];

    }
}

- (void) pollAfterDelay
{
    [self readI2C];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readI2C) object:nil];
    float delay;
    if(updateInterval>0)delay = 1000./updateInterval;
    else                delay = .01;
    [self performSelector:@selector(pollAfterDelay) withObject:nil afterDelay:delay];
}

- (void) readI2C
{
    if(!i2cMaster){
        i2cMaster = [self getI2CMaster];
        [(id)i2cMaster retain];
    }
    //-----------------------------------------------------------------
    // do an I2C bus access via the Master
    id data = [i2cMaster readI2CData]; //change this to pass required I2C arguments
    [self decodeI2CData:data]; //decode raw data into temp and humidity
    //if(i2cMaster)NSLog(@"%@\n",data); //just for debugging
}

- (id) getI2CMaster
{
    //chain thru the connected objects to the Master
    id obj  = [self objectConnectedTo:ORSHT35I2CInConnection];
    id aMaster = [obj getI2CMaster];
    return aMaster;
}

- (void) decodeI2CData:(id)data
{
    //decode the raw data here
    [self setTemperature:[[data objectAtIndex:0]floatValue]];
    [self setHumidity:[[data objectAtIndex:1]floatValue]];

}

- (ORTimeRate*)temperatureRate
{
    return temperatureRate;
}

- (ORTimeRate*)humidityRate
{
    return humidityRate;
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setI2CAddress:(uint32_t)[decoder decodeInt32ForKey:    @"i2cAddress"]];
    [self setUpdateInterval:[decoder decodeInt32ForKey:          @"updateInterval"]];
    [self setRunning: [decoder decodeBoolForKey:@"running"]];
    [[self undoManager] enableUndoRegistration];
    if(running){
        [self pollAfterDelay];
    }
    temperatureRate = [[ORTimeRate alloc] init];
    humidityRate    = [[ORTimeRate alloc] init];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt32:(uint32_t)i2cAddress  forKey: @"i2cAddress"];
    [encoder encodeInt32:updateInterval        forKey: @"updateInterval"];
    [encoder encodeBool:running                forKey: @"running"];
}
@end
