//
//  ORTek220Model.m
//  test
//
//  Created by Mark Howe on Thurs Apr 2, 2009.
//  Copyright 2009 CENPA, University of Washington. All rights reserved.
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
#import "ORGpibEnetModel.h"
#import "ORGpibDeviceModel.h"
#import "ORTek220Model.h"
#import "ORDataTypeAssigner.h"

NSString* ORTek220Lock      = @"ORTek220Lock";
NSString* ORTek220GpibLock  = @"ORTek220GpibLock";


@implementation ORTek220Model

#pragma mark ***Initialization
- (id) init
{
    self = [super init];
	
	[[self undoManager] disableUndoRegistration];
    mRunInProgress = false;
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) dealloc
{
    short i;
    for ( i = 0; i < [self numberChannels]; i++ ){
        [mDataObj[i] release];
    } 	
	
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Tek220"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORTek220Controller"];
}

- (NSString*) helpURL
{
	return @"GPIB/TK220.html";
}

- (int)     numberChannels
{
	return 4;
}

#pragma mark ***Hardware - General
- (short) oscScopeId
{
    mScopeVersion = 0;
	
    [self getID];
    if ( [mIdentifier rangeOfString:@"220"].location != NSNotFound ){
        mID = ORTEK220;
        mScopeType = 220;
        mScopeVersion = 'A'; 
    }
	else mID = 0;
    
    return mID;
}

- (bool) oscBusy
{
    char	theDataOsc[5];
	
    // Write the command.
    int32_t lengthReturn = [mController writeReadDevice:mPrimaryAddress 
											  command:@"BUSY?"
												 data:theDataOsc
											maxLength:5];
	
    // Check the return value.
    if (lengthReturn > 0) {
        if (!strncmp( theDataOsc, "1", 1))		return true;
        else if (!strncmp( theDataOsc, "0", 1))	return false;
        else									return true;
    }
    else 
		return true;
}

- (int32_t) oscGetDateTime
{
	int32_t		returnLength = 0;
    int32_t		timeLong = 0;
	NSString*	dateStr = nil;
	NSString*  	timeStr =nil;
	NSString*	dateTime;
    char		timeBuffer[50];
    short 		i = 0;
	bool		haveDate = false;
	bool		haveTime = false;
	
	// Get date and time from oscilloscope.
	// Get the channel coupling option.
    returnLength = [self writeReadGPIBDevice:@"DATE?; TIME?"
                                         data:mReturnData
                                    maxLength:kMaxGPIBReturn];
	
	// Translate the date/time
	if ( returnLength > 0 ){
		// Extract date and time components from returned values.
		while( ( !haveDate ) && ( !haveTime ) ){
			if ( isdigit( mReturnData[i] ) && !haveDate ){
				haveDate = true;
				dateStr = [[[NSString alloc] initWithBytes:&mReturnData[i] length:10 encoding:NSASCIIStringEncoding] autorelease];
				i += 10;
			}
			
			if ( isdigit( mReturnData[i] ) && ( haveDate ) ){
				haveTime = true;
				timeStr = [[[NSString alloc] initWithBytes:&mReturnData[i] length:8 encoding:NSASCIIStringEncoding] autorelease];

			}
		}
		
		// Convert date time to int32_t.
		dateTime = [dateStr stringByAppendingString:@" "];
        dateTime = [dateTime stringByAppendingString:timeStr];
        
		[dateTime getCString:timeBuffer maxLength:50 encoding:NSASCIIStringEncoding];
		
		timeLong = convertTimeCharToLong( timeBuffer );		
	}
    
    return( timeLong );
}

- (void) oscResetOscilloscope
{
    NSTimeInterval t0;
    
    [self writeToGPIBDevice:@"FACTORY"];
    t0 = [NSDate timeIntervalSinceReferenceDate];
    while ( [NSDate timeIntervalSinceReferenceDate] - t0 < 15 );
    BOOL savedstate = [self doFullInit];
    [self setDoFullInit:YES];
    [self oscSetStandardSettings];
    [self setDoFullInit:savedstate];
}

- (void) oscSetDateTime:(time_t) aDateTime
{
	char		sDateTime[20];
	NSMutableString*	dateString;
	NSMutableString*	timeString;
	
	
	convertTimeLongToChar( aDateTime, sDateTime );
    
	// Have to separate the date and time plus modify format for oscilloscope.

	dateString = [[[NSMutableString alloc] initWithBytes:sDateTime length:10 encoding:NSASCIIStringEncoding] autorelease];
	timeString = [[[NSMutableString alloc] initWithBytes:&sDateTime[11] length:8 encoding:NSASCIIStringEncoding] autorelease];

	//dateString = [NSMutableString stringWithCString:sDateTime length:10];
	//timeString = [NSMutableString stringWithCString:&sDateTime[11] length:8];
	
	[dateString replaceCharactersInRange:NSMakeRange( 4, 1 ) withString:@"-"];
    [dateString replaceCharactersInRange:NSMakeRange( 7, 1 ) withString:@"-"];
    
	// Set date and time
    [self writeToGPIBDevice:[NSString stringWithFormat:@"TIME \"%s\"", [timeString cStringUsingEncoding:NSASCIIStringEncoding]]];
    [self writeToGPIBDevice:[NSString stringWithFormat:@"DATE \"%s\"", [dateString cStringUsingEncoding:NSASCIIStringEncoding]]];    
}

- (void) oscLockPanel:(bool) aFlag
{
    NSString*	command;
    
    if (aFlag) command = @"LOCK ALL";
	else	   command = @"UNLOCK ALL";
    
    [self writeToGPIBDevice:command];
}

- (void) oscSendTextMessage:(NSString*) aMsg
{
    [self writeToGPIBDevice:[NSString stringWithFormat:@"MESSAGE:SHOW '%s'", [aMsg cStringUsingEncoding:NSASCIIStringEncoding]]];
}


//--------------------------------------------------------------------------------
/*!\method  oscSetQueryFormat
 * \brief	Determine the format the oscilloscope will use to return all queries
 * \param	aFormat			- The format to use.
 * \error	Raises error if command fails.
 * \note	1) Possible options for format are:
 *				kNoLabel - Return does not include label, just response.
 *				kShortLabel - Return includes abbreviated version of query command.
 *				kLongLabel - Return includes full query command.
 */
//--------------------------------------------------------------------------------
-(void) oscSetQueryFormat:(short) aFormat
{
    switch ( aFormat){
			
        case kNoLabel:
            [self writeToGPIBDevice:@"HEADER OFF"];
			break;
			
        case kShortLabel:
            [self writeToGPIBDevice:@"HEADER ON;:VERB OFF"];
			break;
			
        case kLongLabel:
            [self writeToGPIBDevice:@"HEADER ON;:VERB ON"];
			break;
			
        default:
            [self writeToGPIBDevice:@"HEADER ON;:VERB ON"];
			break;
    }
	
    NSLog( @"T220:Data query format sent to T220.\n" );
}

//--------------------------------------------------------------------------------
/*!\method  oscSetScreenDisplay
 * \brief	Turn the oscilloscope display on or off.
 * \param	aDisplayOn			- True - turn display on, otherwise turn it off.
 * \error	Raises error if command fails.
 * \note	Turning display off speeds up acquisition.	
 */
//--------------------------------------------------------------------------------
- (void) oscSetScreenDisplay:(bool) aDisplayOn
{
    NSString *command;
    if ( aDisplayOn ) 	command = @"MESSAGE:STATE ON";
    else				command = @"MESSAGE:STATE OFF";
	
    [self writeToGPIBDevice:command];
}

#pragma mark ***Hardware - Channel
//--------------------------------------------------------------------------------
/*!\method  oscGetChnlAcquire
 * \brief	Checks if channel has been turned on.
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscGetChnlAcquire:(short) aChnl
{
    int32_t		returnLength;		// Length of string returned by oscilloscope.
    
	// Make sure that channel is valid
	if ( [self checkChnlNum:aChnl] )
	{
		returnLength = [self writeReadGPIBDevice:[NSString stringWithFormat:@"SELECT:CH%d?", aChnl + 1]
                                             data:mReturnData maxLength:kMaxGPIBReturn];
        
        if ( [self convertStringToLong:mReturnData withLength:returnLength] == 0 )
        {
            [self setChnlAcquire:aChnl setting:false];
        }
        else
        {
            [self setChnlAcquire:aChnl setting:true];
        }
    }
}

//--------------------------------------------------------------------------------
/*!\method  oscSetChnlAcquire
 * \brief	Turns on or off a particular channel
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscSetChnlAcquire
{
    int i;
    for ( i = 0; i < [self numberChannels]; i++ ) { // Select channels on display
        if ( [self checkChnlNum:i] ){
            if ( [self chnlAcquire:i] ){
				[self writeToGPIBDevice:[NSString stringWithFormat:@"SELECT:CH%d ON", i + 1]];
            }
            else {
                [self writeToGPIBDevice:[NSString stringWithFormat:@"SELECT:CH%d OFF", i + 1]];
            }
        }
    }
}

- (void) oscGetChnlCoupling:(short) aChnl
{
    NSString*	impedanceValue;
    NSString*	couplingValue;
	
	if ( [self checkChnlNum:aChnl] ){
		
		// Get the channel coupling option.
		int32_t returnLength = [self writeReadGPIBDevice:[NSString stringWithFormat:@"CH%d:COUPLING?", aChnl + 1]
                                             data:mReturnData
                                        maxLength:kMaxGPIBReturn];
        if ( returnLength > 0 ){
			couplingValue = [NSString stringWithCString:mReturnData encoding:NSASCIIStringEncoding];
			
			// Now get the impedance.
			[self writeReadGPIBDevice:[NSString stringWithFormat:@"CH%d:IMPEDANCE?", aChnl + 1]
                                                 data:mReturnData
                                            maxLength:kMaxGPIBReturn];
			
			impedanceValue = [NSString stringWithCString:mReturnData encoding:NSASCIIStringEncoding];
			
			// Based on coupling and impedance set the coupling option value appropriately.
            if( [couplingValue rangeOfString:@"AC"
									 options:NSBackwardsSearch].location  != NSNotFound )
				[self setChnlCoupling:aChnl coupling:kChnlCouplingACIndex];
			
			if ( [couplingValue rangeOfString:@"DC" 
									   options:NSBackwardsSearch].location != NSNotFound ){
				if ( [impedanceValue rangeOfString:@"MEG"
										   options:NSBackwardsSearch].location != NSNotFound )
                    [self setChnlCoupling:aChnl coupling:kChnlCouplingDCIndex];
				else
                    [self setChnlCoupling:aChnl coupling:kChnlCouplingDC50Index];
			}
			
			if ( [couplingValue rangeOfString:@"GND"
									  options:NSBackwardsSearch].location != NSNotFound )
                [self setChnlCoupling:aChnl coupling:kChnlCouplingGNDIndex];
			
		}
	}
}

- (void) oscSetChnlCoupling:(short) aChnl
{
    NSString*	command = nil;
	
    if ( [self checkChnlNum:aChnl] ){
        
        // Select the option
        switch ( [self chnlCoupling:aChnl] ){
            case kChnlCouplingACIndex:
                command = [NSString stringWithFormat:@"CH%d:COUPLING AC; IMPEDANCE MEG", aChnl + 1];
				break;
				
            case kChnlCouplingDCIndex:
                command = [NSString stringWithFormat:@"CH%d:COUPLING DC; IMPEDANCE MEG", aChnl + 1];
				break;
				
            case kChnlCouplingGNDIndex:
                command = [NSString stringWithFormat:@"CH%d:COUPLING GND; IMPEDANCE MEG", aChnl + 1];
				break;
				
            case kChnlCouplingDC50Index:
                command = [NSString stringWithFormat:@"CH%d:COUPLING DC; IMPEDANCE FIFTY", aChnl + 1];
				break;
        }
        
        // Write out the command
        [self writeToGPIBDevice:command];
    }
}

- (void) oscGetChnlPos:(short) aChnl
{
    int32_t	returnLength = 0;
    
	if ( [self checkChnlNum:aChnl] ){
		returnLength = [self writeReadGPIBDevice:[NSString stringWithFormat:@"CH%d:POSITION?", aChnl + 1]
                                             data:mReturnData
                                        maxLength:kMaxGPIBReturn];
		if ( returnLength > 0 )
		{
			[self setChnlPos:aChnl position:[self convertStringToFloat:mReturnData withLength:returnLength]];
		}
	}
}

- (void) oscSetChnlPos:(short) aChnl
{
	if ( [self checkChnlNum:aChnl] ){
		[self writeToGPIBDevice:[NSString stringWithFormat:@"CH%d:POSITION %e", aChnl + 1, [self chnlPos:aChnl]]];	
    }
}

- (void) oscGetChnlScale:(short) aChnl
{
    int32_t	returnLength = 0;
    
	if ( [self checkChnlNum:aChnl] ){
		returnLength = [self writeReadGPIBDevice:[NSString stringWithFormat:@"CH%d:SCALE?", aChnl + 1]
                                             data:mReturnData
                                        maxLength:kMaxGPIBReturn];
		if ( returnLength > 0 )
			[self setChnlScale:aChnl scale:[self convertStringToFloat:mReturnData withLength:returnLength]];
	}
}

- (void) oscSetChnlScale:(short) aChnl
{
	if ( [self checkChnlNum:aChnl] )
	{
		[self writeToGPIBDevice:[NSString stringWithFormat:@"CH%d:SCALE %e", aChnl + 1, [self chnlScale:aChnl]]];	
    }
}

#pragma mark ***Hardware - Horizontal settings

- (void) oscGetHorizontalPos
{
	int32_t	returnLength;
	
    returnLength = [self writeReadGPIBDevice:@"HORIZONTAL:POSITION?" 
                                         data:mReturnData
                                    maxLength:kMaxGPIBReturn];
    if ( returnLength > 0 ) {
        [self setHorizontalPos:[self convertStringToFloat:mReturnData withLength:returnLength]];
	}
}

- (void) oscSetHorizontalPos
{
    [self writeToGPIBDevice:[NSString stringWithFormat:@"HORIZONTAL:POSITION %e", [self horizontalPos]]];
}

- (void) oscGetHorizontalScale
{
	int32_t	returnLength;
	
    returnLength = [self writeReadGPIBDevice:@"HORIZONTAL:SCALE?" 
                                         data:mReturnData
                                    maxLength:kMaxGPIBReturn];
    if ( returnLength > 0 ) {
        [self setHorizontalScale:[self convertStringToFloat:mReturnData withLength:returnLength]]; 
	}
}

- (void) oscSetHorizontalScale
{
    [self writeToGPIBDevice:[NSString stringWithFormat:@"HORIZONTAL:SCALE %e", [self horizontalScale]]];
}

- (void) oscGetWaveformRecordLength
{
    int32_t		returnLength;
    
    returnLength = [self writeReadGPIBDevice:@"HORIZONTAL:RECORDLENGTH?"
                                         data:mReturnData
                                    maxLength:kMaxGPIBReturn];
    if ( returnLength > 0 ) {
		[self setWaveformLength:[self convertStringToLong:mReturnData withLength:returnLength]];;
	}
}

- (void) oscSetWaveformRecordLength
{
	[self writeToGPIBDevice:[NSString stringWithFormat:@"HORIZONTAL:RECORDLENGTH %u", [self waveformLength]]];	
}


#pragma mark ***Hardware - Trigger
- (void)	oscGetTriggerCoupling
{
    NSString*	couplingValue;
	int32_t		returnLength = 0;
	
	// Get coupling value.
	returnLength = [self writeReadGPIBDevice:@"TRIGGER:MAIN:EDGE:COUPLING?"
                                         data:mReturnData
                                    maxLength:kMaxGPIBReturn];
	
	// Convert coupling value to index
	if ( returnLength > 0 ){
        couplingValue = [NSString stringWithCString:mReturnData encoding:NSASCIIStringEncoding];
        
        if ( [couplingValue rangeOfString:@"AC"
								  options:NSBackwardsSearch].location != NSNotFound  ){
			[self setTriggerCoupling:kTriggerAC];
        }
		else if ( [couplingValue rangeOfString:@"DC"
									   options:NSBackwardsSearch].location != NSNotFound ){
			[self setTriggerCoupling:kTriggerDC];
		}
		else if ( [couplingValue rangeOfString:@"HFR"
									   options:NSBackwardsSearch].location != NSNotFound ){
			[self setTriggerCoupling:kTriggerHFRej];
		}
		else if ( [couplingValue rangeOfString:@"LFR"
									   options:NSBackwardsSearch].location != NSNotFound ){
			[self setTriggerCoupling:kTriggerLFRej];
		}
		else if ( [couplingValue rangeOfString:@"NOISER"
                                        options:NSBackwardsSearch].location != NSNotFound ){
			[self setTriggerCoupling:kTriggerNOISERej];
		}
    }
}

- (void) oscSetTriggerCoupling
{
    
	switch ( [self triggerCoupling] ){
		case kTriggerAC:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:COUPLING AC"];
		break;
			
		case kTriggerDC:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:COUPLING DC"];
		break;
			
		case kTriggerHFRej:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:COUPLING HFREJ"];
		break;
			
		case kTriggerLFRej:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:COUPLING LFREJ"];
		break;
			
		case kTriggerNOISERej:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:COUPLING NOISEREJ"];
		break;
			
		default:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:COUPLING AC"];
		break;	
	}
	
}

- (void)	oscGetTriggerLevel
{
	int32_t	returnLength = 0;
	
	// Get trigger level.
	returnLength = [self writeReadGPIBDevice:@"TRIGGER:MAIN:LEVEL?"
                                         data:mReturnData
                                    maxLength:kMaxGPIBReturn];
	
	// Save the trigger level.
	if ( returnLength > 0 ){
		[self setTriggerLevel:[self convertStringToFloat:mReturnData withLength:returnLength]];		
	}
}

- (void)	oscSetTriggerLevel
{
	[self writeToGPIBDevice:[NSString stringWithFormat:@"TRIGGER:MAIN:LEVEL %e", [self triggerLevel]]];	
}

- (void)	oscGetTriggerMode
{
    NSString*	triggerMode;
	int32_t		returnLength = 0;
	
	// Get trigger mode.
	returnLength = [self writeReadGPIBDevice:@"TRIGGER:MAIN:Mode?"
                                         data:mReturnData
                                    maxLength:kMaxGPIBReturn];
	
	// Convert trigger mode to index
	if ( returnLength > 0 ){
        triggerMode = [NSString stringWithCString:mReturnData encoding:NSASCIIStringEncoding];
        
        if ( [triggerMode rangeOfString:@"AUTO" 
								 options:NSBackwardsSearch].location != NSNotFound  ){
			[self setTriggerMode:kTriggerAuto];
		} 
        else if ( [triggerMode rangeOfString:@"NORM"
									  options:NSBackwardsSearch].location != NSNotFound ){
            [self setTriggerMode:kTriggerNormal];
        }
        else {
            [self setTriggerMode:kTriggerNormal];
        }
	}
}

- (void)	oscSetTriggerMode
{
    switch ( [self triggerMode] ){
			
        case kTriggerAuto:
            [self writeToGPIBDevice:@"TRIGGER:MAIN:MODE AUTO"];
		break;
			
        case kTriggerNormal:
        default:
            [self writeToGPIBDevice:@"TRIGGER:MAIN:MODE NORMAL"];
		break;						
    }
}

- (void) oscGetTriggerPos
{
    int32_t		returnLength = 0;
    
	// Get value
    returnLength = [self writeReadGPIBDevice:@"HORIZONTAL:TRIGGER:POSITION?"
                                         data:mReturnData
                                    maxLength:kMaxGPIBReturn];
	
	// Save the trigger position.
	if ( returnLength > 0 ){
		[self setTriggerPos:[self convertStringToFloat:mReturnData withLength:returnLength]];	
	}
}

- (void) oscSetTriggerPos
{
    [self writeToGPIBDevice: [NSString stringWithFormat:@"HORIZONTAL:TRIGGER:POSITION %e", [self triggerPos]]];
}

- (void) oscGetTriggerSlopeIsPos
{
    NSString*	slope;
    int32_t		returnLength = 0;
    
	// Get trigger slope.
	returnLength = [self writeReadGPIBDevice:@"TRIGGER:MAIN:EDGE:SLOPE?" 
                                         data:mReturnData
                                    maxLength:kMaxGPIBReturn];
	
	if ( returnLength > 0 ){
        slope = [NSString stringWithCString:mReturnData encoding:NSASCIIStringEncoding];
        
        if ( [slope rangeOfString:@"FALL"
						   options:NSBackwardsSearch].location != NSNotFound  ){
			[self setTriggerSlopeIsPos:false];
		}
        else if ( [slope rangeOfString:@"RIS"
								options:NSBackwardsSearch].location != NSNotFound  ){
            [self setTriggerSlopeIsPos:true];
        }
    }
}

- (void)	oscSetTriggerSlopeIsPos
{    
    if ( [self triggerSlopeIsPos] ){
        [self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:SLOPE RISE"];
    }
    else {
        [self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:SLOPE FALL"];
    }
}

- (void)	oscGetTriggerSource
{
    NSString*	triggerSource;
	int32_t		returnLength = 0;
	
	// Get trigger source.
	returnLength = [self writeReadGPIBDevice:@"TRIGGER:MAIN:EDGE:SOURCE?"
                                         data:mReturnData
                                    maxLength:kMaxGPIBReturn];
	
	// Convert response from oscilloscope to index.
	if ( returnLength > 0 ){
        triggerSource = [NSString stringWithCString:mReturnData encoding:NSASCIIStringEncoding];
        
        if ( [triggerSource rangeOfString:@"AUX"
                                   options:NSBackwardsSearch].location != NSNotFound  ){
            [self setTriggerSource:kTriggerAuxilary];
        }
        else if ( [triggerSource rangeOfString:@"LINE"
										options:NSBackwardsSearch].location != NSNotFound  ){
            [self setTriggerSource:kTriggerLine];
        }
        else if ( [triggerSource rangeOfString:@"CH1"
										options:NSBackwardsSearch].location != NSNotFound  ){
            [self setTriggerSource:kTriggerCH1];
        }
        else if ( [triggerSource rangeOfString:@"CH2"
										options:NSBackwardsSearch].location != NSNotFound  ){
            [self setTriggerSource:kTriggerCH2];
        }
        else if ( [triggerSource rangeOfString:@"CH3"
										options:NSBackwardsSearch].location != NSNotFound  ){
            [self setTriggerSource:kTriggerCH3];
        }
        else if ( [triggerSource rangeOfString:@"CH4"
										options:NSBackwardsSearch].location != NSNotFound  ){
            [self setTriggerSource:kTriggerCH4];
        }
	}
}

//-----------------------------------------------------------------------------
/*!\method	oscSetTriggerSource
 * \brief	Set the trigger source for the oscilloscope using model parameter. 
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void)	oscSetTriggerSource
{
	switch ( [self triggerSource] ){
		case kTriggerAuxilary:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:SOURCE AUX"];
		break;
			
		case kTriggerLine:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:SOURCE LINE"];
		break;
			
		case kTriggerCH1:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:SOURCE CH1"];
		break;
			
		case kTriggerCH2:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:SOURCE CH2"];
		break;
			
		case kTriggerCH3:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:SOURCE CH3"];
		break;
			
		case kTriggerCH4:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:SOURCE CH4"];
		break;
			
		default:
			[self writeToGPIBDevice:@"TRIGGER:MAIN:EDGE:SOURCE CH1"];
		break;			
	}
	
}


#pragma mark ***Hardware - Data Acquisition
- (void) oscArmScope
{
    [self writeToGPIBDevice:@"ACQUIRE:STATE ON"];
}

- (void) oscGetHeader
{
	char			*theHeader;
	//	size_t			theLength;
	int				i;
	
    @try {
        if( [self isConnected] ){
			
            for ( i = 0; i < [self numberChannels]; i++){
                if ( mChannels[i].chnlAcquire ){
					
                    theHeader = [mDataObj[i] rawHeader];
                    memset( theHeader, 0, kSizeTek220Header );
					
					[self writeToGPIBDevice: @"WFMP:NR_PT?"];
					int32_t len = [self readFromGPIBDevice:theHeader maxLength:kSizeTek220Header];
					if(len){
						theHeader[len-1] = ';';
						// Send command to retrieve header information.
						[self writeToGPIBDevice: [NSString stringWithFormat:@"WFMP:CH%d:YOFF?;YMUL?;XINC?;PT_O?;XUN?;YUN?",i+1]];
					
						// Read in header and place in data object
						len = [self readFromGPIBDevice:&theHeader[len] maxLength:kSizeTek220Header];
					}
					else {
						memset( theHeader, 0, kSizeTek220Header );
					}
                }
            }
        }
		
    }
	@catch(NSException* localException) {
    }
}


//--------------------------------------------------------------------------------
/*!\method  oscGetWaveform
 * \brief	This routine gets the actual data from the oscilloscope.
 * \error	Raises error if command fails.
 * \note	1) The Tektronix does not use a communication header that is read in
 *             as one item.  Instead it has 3 pieces, where the first describes
 *            the second and the second describes the third.  The structure
 *            of this header is as follows.
 * 
 *            #<x><yyy...><data><newline>
 *            x:number of bytes in y
 *            y:number of data in data.
 */
//--------------------------------------------------------------------------------
- (void) oscGetWaveform:(unsigned short) aMask
{
	char			*theData;			// Temporary pointer to data storage location.
	char			theHeaderInfo[8];					
	int				i;
	int32_t			numOfDataPoints;
	unsigned short  acqMask;
	
    @try {
        if( [self isConnected] ){
			// Get the data.
			acqMask = aMask & mChannelMask;
			[self oscSet220WaveformAcq:acqMask];								// This command sets which waveforms will be returned by CURVE?
            [mController writeToDevice:mPrimaryAddress command:@"CURVE?"];   // Get the data.
            
            // Read in all the data at once.
            for ( i = 0; i < [self numberChannels]; i++ ){
                if ( mChannels[i].chnlAcquire && ( aMask & ( 1 << i ) )) {
                    theData = [mDataObj[i] createDataStorage];
					
                    // Read header information
                    //[mController readFromDevice:mPrimaryAddress data:theHeaderInfo maxLength:1]; // skip the initial '#'
                    //[mController readFromDevice:mPrimaryAddress data:theHeaderInfo maxLength:1]; // <x> size of next element
                    //combine the reads mah 03/5/04
                    [mController readFromDevice:mPrimaryAddress data:theHeaderInfo maxLength:2]; // <x> size of next element
                    theHeaderInfo[2] = '\0';	
                    numOfDataPoints = atoi( &theHeaderInfo[1] );	// no characters in <yyy..> 
					
                    [mController readFromDevice:mPrimaryAddress data:theHeaderInfo maxLength:(short) numOfDataPoints]; 
					//<yyy...> number of chnls
                    theHeaderInfo[numOfDataPoints] = '\0';
                    numOfDataPoints = atoi( theHeaderInfo );							// length of pulse in chnls						
					
                    // read the actual data.
					int32_t maxToRead = [mDataObj[i] maxWaveformSize];
                    [mDataObj[i] setActualWaveformSize:( numOfDataPoints >= maxToRead ) ? maxToRead :numOfDataPoints];  // Read in the smaller size
					int32_t numToRead = [mDataObj[i] actualWaveformSize];
					
					int32_t actualNumRead = 0;
					int numChunks = ceil(numToRead/1024.);
					if(numChunks>1){
						int i;
						for(i=0;i<numChunks;i++){
							actualNumRead += [mController readFromDevice:mPrimaryAddress 
															   data:&theData[actualNumRead]
														  maxLength:1024];
						}
					}
					else {
						actualNumRead = [mController readFromDevice:mPrimaryAddress 
																	data:theData
															   maxLength:numToRead];
					}
					
					
					[mDataObj[i] setActualWaveformSize:actualNumRead];
					
                   // [mController readFromDevice:mPrimaryAddress data:theHeaderInfo maxLength:1];
                }
            }
        }
        
		// Bad connection so don't execute instruction
        else {
            NSString *errorMsg = @"Must establish GPIB connection prior to issuing command\n";
            [NSException raise:OExceptionGPIBConnectionError format:@"%@",errorMsg];
        }
        
    }
	@catch(NSException* localException) {
    }
	
}

//--------------------------------------------------------------------------------
/*!\method  oscGetWaveformTime
 * \brief	This routine gets the time associated with the waveform.
 * \param   aMask		- Not used.
 * \error	Raises error if command fails.
 * \note	1) The Tektronix must be in fastframe mode with the timestamp
 *				turned on for this routine to work.  Otherwise an error
 *				is returned.
 * \note	2) Time returned is in form:4 Apr 1998;08:47:24.123 456 789 111
 * \note	3) This routine currently assumes that fastframe:count is 1.
 * \note	4) Time is common to all channels.
 */
//--------------------------------------------------------------------------------
- (void) oscGetWaveformTime:(unsigned short) aMask
{
    uint64_t	timeInSecs;
	char				theTimeStr[128];			// Temporary storage for time stamp.
    bool				fNoTime = true;
    
	// Initialize memory.
    memset( &theTimeStr[0], '\0', 128 );
	    
	// Use computer time for 220 oscilloscope.
    if ( fNoTime ){
        NSString*		timeString;
        struct timeval	timeValue;
        struct timezone	timeZone;
		//        time_t		compTime;
        struct tm*		timeAsStruct;
        char		*month[12] = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug",
		"Sep", "Oct", "Nov", "Dec" };
        
		//        time( &compTime );
        gettimeofday( &timeValue, &timeZone );
        time_t tmpTime = timeValue.tv_sec;
        timeAsStruct = gmtime( &tmpTime );
        
        int32_t milliSecs = timeValue.tv_usec / 1000;
        int32_t microSecs = timeValue.tv_usec - 1000 * milliSecs;
        
		// Construct time in format needed by remainder of program.        
        timeString = [NSString stringWithFormat:@"%d %s %d %d:%d:%d.%03u %03u 000", 
					  timeAsStruct->tm_mday, month[timeAsStruct->tm_mon], timeAsStruct->tm_year + 1900, 
					  timeAsStruct->tm_hour, timeAsStruct->tm_min, timeAsStruct->tm_sec,
					  milliSecs, microSecs];
		[timeString getCString:theTimeStr maxLength:128 encoding:NSASCIIStringEncoding];
    }
	
	// Convert the time
    [self osc220ConvertTime:&timeInSecs timeToConvert:&theTimeStr[0]];
    [mDataObj[0] setTimeInSecs:timeInSecs];
}

//--------------------------------------------------------------------------------
/*!\method  oscRunOsc
 * \brief	Assumes 
 * \param	aStartMsg			- A starting message to write out to the screen.
 * \error	Throws error if any command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscRunOsc:(NSString*) aStartMsg
{
    
	// Get scope ready.
    [self clearStatusReg];
    [self oscScopeId];
    [self oscLockPanel:true];
    
	// Acquire data.  Places scope in single waveform acquisition mode.
	if ( mRunInProgress ){
		// time_t	theTime;
		//  struct tm	*theTimeGMTAsStruct;
		//  time( &theTime );
		//  theTimeGMTAsStruct = gmtime( &theTime );
		// [self oscSetDateTime:mktime( theTimeGMTAsStruct )];
	    [self oscInitializeForDataTaking:aStartMsg];
	    [self oscArmScope];
	}
	
	// Place oscilloscope in free running mode.
	else {
	    [self oscSetAcqMode:kNormalTrigger];
	    [self writeToGPIBDevice:@"ACQUIRE:STATE RUN"];
	    [self oscLockPanel:false];
	}
}

//--------------------------------------------------------------------------------
/*!\method  oscSetAcqMode
 * \brief	Sets the acquisition mode for the oscilloscope. Either free running
 *			or one event at a time.
 * \param	aMode		- Either kNormalTrigger or kSingleWaveform.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscSetAcqMode:(short) aMode
{
    NSString	*command;
    
	switch( aMode ){
		case kNormalTrigger:
			command = @"ACQUIRE:STOPAFTER RUNSTOP";
		break;
		case kSingleWaveform:
			command = @"ACQUIRE:STOPAFTER SEQUENCE; MODE:SAMPLE";
		break;
	 	default:
			command = @"ACQUIRE:STOPAFTER RUNSTOP";
		break;
	}
	
	[self writeToGPIBDevice:command];
}

- (void) oscSetDataReturnMode
{
    [self writeToGPIBDevice:@"DATA:WID 1"];			// Byte data
    [self writeToGPIBDevice:@"DATA:ENCDG RIBINARY"];	// Binary data
    [self writeToGPIBDevice:@"DATA:START 1"];			// Data starts at chnl 1.	
    [self writeToGPIBDevice:[NSString stringWithFormat:@"DATA:STOP %d", mWaveformLength]];  // Waveform size
    [self oscSetAcqMode:kSingleWaveform];  // Set to single waveform acquisition.
}

- (void) oscSet220WaveformAcq:(unsigned short) aMask
{
    NSString *command = @"DATA:SOURCE ";
    int		i;
    int		j;
	
	// Tell oscilloscope which channels to return data from
    j = 0;
    for ( i = 0; i < [self numberChannels]; i++ ){   // Select channels for output
        if ( [self chnlAcquire:i]  && (aMask & (1<<i))){
            command = [command stringByAppendingFormat:@"%@ CH%d", (j++ == 0) ? @"" :@",",i + 1];
			// NSLog( @"%u \n",aMask );
        }
    }
	
	//	printf( "%s\n", [command cString] );
    [self writeToGPIBDevice:command];   // Write channels for output to scope.
}

- (void) oscStopAcquisition
{
    [self writeToGPIBDevice:@"ACQUIRE:STATE OFF"];
    NSLog( @"T220:Data acquisition stopped.\n" );
}


#pragma mark ***DataTaker

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORTek220DecoderForScopeData",            @"decoder",
								 [NSNumber numberWithLong:dataId],           @"dataId",
								 [NSNumber numberWithBool:YES],              @"variable",
								 [NSNumber numberWithLong:-1],               @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"ScopeData"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORTek220DecoderForScopeGTID",            @"decoder",
				   [NSNumber numberWithLong:gtidDataId],       @"dataId",
				   [NSNumber numberWithBool:NO],               @"variable",
				   [NSNumber numberWithLong:IsShortForm(gtidDataId)?1:2],   @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"ScopeGTID"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORTek220DecoderForScopeTime",            @"decoder",
				   [NSNumber numberWithLong:clockDataId],      @"dataId",
				   [NSNumber numberWithBool:NO],               @"variable",
				   [NSNumber numberWithLong:3],                @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"ScopeTime"];
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
    NSMutableArray* eventGroup = [NSMutableArray array];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ScopeGTID",							@"name",
				   [NSNumber numberWithLong:gtidDataId],	@"dataId",
				   nil];
	[eventGroup addObject:aDictionary];
	
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ScopeTime",							@"name",
				   [NSNumber numberWithLong:clockDataId],	@"dataId",
				   nil];
	[eventGroup addObject:aDictionary];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ScopeData",						@"name",
				   [NSNumber numberWithLong:dataId],	@"dataId",
				   [NSNumber numberWithLong:4],		@"maxChannels",
				   nil];
	[eventGroup addObject:aDictionary];
	
	[anEventDictionary setObject:eventGroup forKey:@"Tek220Scope"];
	
}


- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(id) anUserInfo
{
    short		i;
    bool		bRetVal = false;
	
	// Call base class method that initializes _cancelled conditional lock.
    [super runTaskStarted:aDataPacket userInfo:anUserInfo];
    
	// Handle case where device is not connected.
    if( ![self isConnected] ){
	    [NSException raise:@"Not Connected" format:@"You must connect to a GPIB Controller."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORTek220Model"]; 
    
	
	// Get the controller so that it is cached
    bRetVal = [self cacheTheController];
    if ( !bRetVal ){
        [NSException raise:@"Not connected" format:@"Could not cache the controller."];
    }
    
	// Initialize the scope correctly.
    firstEvent = YES;
    
	// Set up memory structures for data and channel mask.
	mChannelMask = 0;
    for ( i = 0; i < [self numberChannels]; i++ ){
		if ( mChannels[i].chnlAcquire ) mChannelMask += 1 << i;
        mDataObj[i] = [[ORTek220Data alloc] initWithWaveformModel:self channel:i];
    } 
    
	// Start the oscilloscope
    NSNumber* initValue = [anUserInfo objectForKey:@"doinit"];
    if ( initValue ) 
		[self setDoFullInit:[initValue intValue]];
    else 
		[self setDoFullInit:YES];
	
	// Initialize the oscilloscope settings and start acquisition using a run configuration.
    mRunInProgress = true;
	[self oscSetStandardSettings];
	[self oscRunOsc:nil];
	
}

//--------------------------------------------------------------------------------
/*!\method  takeDataTask
 * \brief	Thread that is repeatedly called to actually acquire the data. 
 * \param	anUserInfo				- Dictionary holding information from
 *										outside this task that is needed by
 *										this task.
 * \note	first 32 bits data		- 5 bits data type - deviceIndex -> deviceType	
 *									  4 bits oscilloscope number
 *									  4 bits channel
 *									  3 bits spare
 *									 16 bits size of following waveform
 * \note	first 32 bits time		- 5 bits data type - deviceIndex -> deviceType
 *									  3 bits channel number
 *									 24 bits high portion of time.
 * \history	2003-11-12 (jmw)	- Fixed output record when multiple channels fire.
 *								  Only one GTID written at beginning of record.
 */
//--------------------------------------------------------------------------------
- (void) 	takeDataTask:(id) notUsed 
{
	
	ORDataPacket* aDataPacket = nil;
    while(1) {
        
        mDataThreadRunning = YES;
        
		[_okToGo lockWhenCondition:YES];
		
        // -- Do some basic initialization prior to acquiring data ------------------
        // Threads are responsible to manage their own autorelease pools
        NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
        
        BOOL processedAnEvent = NO;
        BOOL readOutError      = NO;
		
        //extract the data packet to use.
		if(aDataPacket)[aDataPacket release];
        aDataPacket 	= [[threadParams objectForKey:@"ThreadData"] retain];
		
        // Set which channels to read based on the mask - If not available read all channels.
        unsigned char mask;
        NSNumber* theMask = [threadParams objectForKey:@"ChannelMask"];
        if ( theMask ){
            mask  = [theMask charValue];
        }
        else {
            mask = 0xff;
        }
        
        // Get the GTID
        NSNumber* gtidNumber    = [threadParams objectForKey:@"GTID"];
        NSTimeInterval t0       = [NSDate timeIntervalSinceReferenceDate];
		//NSLog(@"set t0:%f\n",t0);
        NSString* errorLocation = @"?"; // Used to determine at what point code stops if it stops.
        
		// -- Basic loop that reads the data -----------------------------------
        while ( ![self cancelled]) {   
            // If we are not in standalone mode then gtid will be set.
            // In that case break out of this loop in a reasonable amount of time.
            if( gtidNumber && ( [NSDate timeIntervalSinceReferenceDate] - t0 > 2.5 ) ){
                NSLogError( @"", @"Scope Error", [NSString stringWithFormat:@"Thread timeout, no data for scope (%d)", 
												  [self primaryAddress]], nil );
                readOutError = YES;
                break;
            }
			
            // Start section that reads data.
            @try {
                short i;
                
                // Scope is not busy so read it out
                errorLocation = @"oscBusy";
				if ( ![self oscBusy] ) {
					
                    // Read the header only for the first event.  We assume that scope settings will not change.
                    if ( firstEvent ) {
                        //set the channel mask temporarily to read the headers for all channels.
                        errorLocation = @"oscSetWaveformAcq";
                        [self oscSet220WaveformAcq:0xff];
                        errorLocation = @"oscGetHeader";
                        [self oscGetHeader];
                        
                        for ( i = 0; i<[self numberChannels]; i++ ){
                            if ( mChannels[i].chnlAcquire ) [mDataObj[i] convertHeader];
                        }
                    }
					
                    // Get data after setting the acquire mask.
                    
                    errorLocation = @"oscGetWaveform";
                    [self oscGetWaveform:mask];			// Get the actual waveform data.
                    
                    errorLocation = @"oscGetWaveformTime";
                    [self oscGetWaveformTime:mask];				// Get the time.
                    
					// Rearm the oscilloscope.
					// [self clearStatusReg];
                    errorLocation = @"oscArmScope";
                    [self oscArmScope];   
					
                    // Place data in array where other parts of ORCA can grab it.
                    for ( i = 0; i < [self numberChannels]; i++ ) {
                        if ( mChannels[i].chnlAcquire && ( mask & ( 1 << i ) )) {
                            [mDataObj[i] setGtid:(uint32_t)(gtidNumber ? [gtidNumber longValue] :0)];
							
                            //Note only mDataObj[0] has the timeData.
                            NSData* theTimeData = [mDataObj[0] timePacketData:aDataPacket channel:i];
							
                            //note that the gtid is shipped only with the first data set.
                            [mDataObj[i] setDataPacketData:aDataPacket timeData:theTimeData includeGTID:!processedAnEvent];
                            processedAnEvent = YES; 
                            [self incEventCount:i];                   
                        }
                    }
                }
                
                // Oscilloscope was busy - Loop for a short while and then try again.
                else {
					[NSThread sleepUntilDate:[[NSDate date] dateByAddingTimeInterval:.01]];
                    //NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];
                    //while([NSDate timeIntervalSinceReferenceDate] - t1 < .01 );
                }
				
            }
			@catch(NSException* localException) {
                readOutError = YES;
            }
            
            // Indicate that we have processed our first event.
            if( processedAnEvent )
                firstEvent = NO;
			
            // If we have the data or encountered an error break out of while.
            if( processedAnEvent || readOutError )
                break;
        }
		
		// -- Handle any errors encountered during read -------------------------------
        if( readOutError ) {
            NSLogError( @"", @"Scope Error", [NSString stringWithFormat:@"Exception:%@ (%d)", 
											  errorLocation, [self primaryAddress]], nil );
			
            //we must rearm the scope. Since there was an error we will try a rearm again just to be sure.
            int errorCount = 0;
            while( 1 ) {
                @try {
                    [self clearStatusReg];
                    [self oscArmScope];
                }
				@catch(NSException* localException) {
                    errorCount++;
                }
                
                if( errorCount == 0 ) 
                    break;
                else if( errorCount > 2 ) {
                    NSLogError( @"", @"Scope Error", [NSString stringWithFormat:@"Rearm failed (%d)", [self primaryAddress]], nil );
                    break;
                }
            }
        }
        // Release the autoreleasepool
		[_okToGo unlockWithCondition:NO];
        if([self cancelled]) {
			if(aDataPacket)[aDataPacket release];
			mDataThreadRunning = NO;
			[thePool release];
			
			break;
		}
		else [thePool release];
		
    }
	
	
    // Exit this thread
    [NSThread exit];
}

- (BOOL) runInProgress
{
    return mDataThreadRunning && [_okToGo condition];
}


- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(id) anUserInfo
{
    short i;
	
	// Cancel the task.
    [super runTaskStopped:aDataPacket userInfo:anUserInfo];
	
	// Stop running and place oscilloscope in free running mode.
    mRunInProgress = false;
    [self oscRunOsc:nil];
    
	// Release memory structures used for data taking
    for ( i = 0; i < [self numberChannels]; i++ )
    {
        [mDataObj[i] release];
        mDataObj[i] = nil;
    } 	
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];
	
    [[self undoManager] disableUndoRegistration];
    
    [[self undoManager] enableUndoRegistration];
    return self;
}

#pragma mark ***Support
- (void) osc220ConvertTime:(uint64_t*) a10MHzTime timeToConvert:(char*) aCharTime
{
    struct tm					unixTime;
	//    struct tm*					tmpStruct;
    const char*					stdMonths[] = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", 
	"Oct", "Nov", "Dec" };
    time_t						baseTime;
    uint32_t				fracSecs = 0;
    const uint64_t	mult = 10000000;
    short						iStart = -1;
    short						i;
    bool						f_Found = false;
    //char*						dateString;
	char*						datePiece;
	
	// Initialize time to zero in case we fail.
	//	printf( "T220:%s\n", aCharTime );	
	
	*a10MHzTime = 0;
    
	// Set date/time reference to Greenwich time zone - no daylight savings time.
    unixTime.tm_isdst = 0;
    unixTime.tm_gmtoff = 0;
	
    
	// Get past garbage at beginning of date/time string
    f_Found = false;
    while ( !f_Found && iStart < 10 )
    {
        iStart++;
        if ( isdigit( aCharTime[iStart] ) ) f_Found = true;
    }
	
	// No leading digit - return 0.
	if ( !f_Found ) return;
	
	// Get base time by breaking down Tektronix time into its parts.
	datePiece = strtok( &aCharTime[iStart], " " );
    unixTime.tm_mday = atoi( datePiece );
	if ( !datePiece ) return;
    
    char* month = strtok( 0, " " );
	if ( !month ) return;
    
    for ( i = 0; i < 12; i++ ){
        if ( strstr( month, stdMonths[i] ) ){
            unixTime.tm_mon = i;
            break;
        }
    }
	
	datePiece = strtok( 0, " " );
	if ( !datePiece ) return;
	unixTime.tm_year = atoi( datePiece ) - 1900;  // Standard unix reference relative to 1900.
	
	datePiece = strtok( 0, ":" );
	if ( !datePiece ) return;
    unixTime.tm_hour = atoi( datePiece );
	
	datePiece = strtok( 0, ":" );
	if ( !datePiece ) return;
    unixTime.tm_min = atoi( datePiece );
	
	datePiece = strtok( 0, "." );
	if ( !datePiece ) return;
    unixTime.tm_sec = atoi( datePiece );
    
   // dateString = asctime( &unixTime );
    
	// Get base time in seconds
    baseTime = timegm( &unixTime ); // Have to use timegm because mktime forces the time to
	// local time and then does conversion to gmtime    
	//    tmpStruct = gmtime( &baseTime );
	//    dateString = asctime( tmpStruct );
    
	// Get fractions of a second.
	datePiece = strtok( 0, " " );
	if ( datePiece ) 
		fracSecs = atoi( datePiece ) * 10000;
	
	datePiece = strtok( 0, " " );
	if ( datePiece )fracSecs += atoi( datePiece ) * 10;
	
	datePiece = strtok( 0, " " );
	if ( datePiece ) fracSecs += atoi( datePiece ) / 100; 
	
	// Convert to 10 Mhz Clock
    *a10MHzTime = (uint64_t)baseTime * mult + fracSecs;
	//  printf( "T220 - converted:%lld\n", *a10MHzTime );	
	
}
@end

@implementation ORTek220DecoderForScopeData
//just use the base class decodedata
@end

@implementation ORTek220DecoderForScopeGTID
- (uint32_t) decodeData:(void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*) aDataSet
{
    return [self decodeGtId:aSomeData fromDecoder:aDecoder intoDataSet:aDataSet];
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    return [self dataGtIdDescription:ptr];
}

@end

@implementation ORTek220DecoderForScopeTime
- (uint32_t) decodeData:(void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*) aDataSet
{
    return [self decodeClock:aSomeData fromDecoder:aDecoder intoDataSet:aDataSet];
} 
- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    return [self dataClockDescription:ptr];
}
@end
