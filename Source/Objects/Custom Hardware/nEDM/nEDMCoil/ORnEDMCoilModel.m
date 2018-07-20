
//
//  ORnEDMCoilModel.m
//  Orca
//
//  Created by Michael Marino 15 Mar 2012 
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORnEDMCoilModel.h"
#import "ORTTCPX400DPModel.h"
#import "ORAdcProcessing.h"
#import "ORXYCom564Model.h"

NSString* ORnEDMCoilPollingActivityChanged = @"ORnEDMCoilPollingActivityChanged";
NSString* ORnEDMCoilPollingFrequencyChanged    = @"ORnEDMCoilPollingFrequencyChanged";
NSString* ORnEDMCoilProportionalTermChanged    = @"ORnEDMCoilProportionalTermChanged";
NSString* ORnEDMCoilIntegralTermChanged    = @"ORnEDMCoilIntegralTermChanged";
NSString* ORnEDMCoilFeedbackThresholdChanged    = @"ORnEDMCoilFeedbackThresholdChanged";
NSString* ORnEDMCoilRegularizationParameterChanged    = @"ORnEDMCoilRegularizationParameterChanged";
NSString* ORnEDMCoilRunCommentChanged = @"ORnEDMRunCommentChanged";
NSString* ORnEDMCoilADCListChanged = @"ORnEDMCoilADCListChanged";
NSString* ORnEDMCoilHWMapChanged   = @"ORnEDMCoilHWMapChanged";
NSString* ORnEDMCoilSensitivityMapChanged   = @"ORnEDMCoilSensitivityMapChanged";
NSString* ORnEDMCoilActiveChannelMapChanged   = @"ORnEDMCoilActiveChannelMapChanged";
NSString* ORnEDMCoilSensorInfoChanged   = @"ORnEDMCoilSensorInfoChanged";
NSString* ORnEDMCoilDebugRunningHasChanged = @"ORnEDMCoilDebugRunningHasChanged";
NSString* ORnEDMCoilDynamicModeHasChanged = @"ORnEDMCoilDynamicModeHasChanged";
NSString* ORnEDMCoilVerboseHasChanged = @"ORnEDMCoilVerboseHasChanged";
NSString* ORnEDMCoilRealProcessTimeHasChanged = @"ORnEDMCoilRealProcessTimeHasChanged";
NSString* ORnEDMCoilTargetFieldHasChanged = @"ORnEDMCoilTargetFieldHasChanged";
NSString* ORnEDMCoilStartCurrentHasChanged = @"ORnEDMCoilStartCurrentHasChanged";
NSString* ORnEDMCoilPostToPathHasChanged    = @"ORnEDMCoilPostToPathHasChanged";
NSString* ORnEDMCoilPostDataToDBHasChanged  = @"ORnEDMCoilPostDataToDBHasChanged";
NSString* ORnEDMCoilPostDataToDBPeriodHasChanged = @"ORnEDMCoilPostDataToDBPeriodHasChanged";

bool useIntegralTerm=TRUE;
double integralTermFraction=0.3; //is replaced by porportionalTerm and integralTerm


@interface ORnEDMCoilModel (private) // Private interface
#pragma mark •••Running
- (void) _runThread;
- (void) _setCurVector:(NSData*)aData;
- (void) _setCurrentMemory:(NSData*)aData;
- (void) _setFieldTarget:(NSData*)aData;
- (void) _setStartCurrent:(NSArray*)anArray;
- (void) _runProcess;
- (void) _stopRunning;
- (void) _startRunning;
- (void) _setUpRunning:(BOOL)verbose;
- (void) _saveStaticInfoInDB;
- (void) _saveFieldMapInDB;
- (void) _saveFieldMapLoop:(NSNumber*)atime;

#pragma mark •••Read/Write
- (void) _readADCValues;
//- (void) _writeValuesToDatabase;
- (NSMutableData*) _transposeData:(NSMutableData*)inData withColumns:(int)cols;
- (NSData*) _calcPowerSupplyValues;
- (void) _readCurrentValues:(NSMutableData*)inData;
- (void)    _syncPowerSupplyValues:(NSData*)currentVector;
- (double)  _fieldAtMagnetometer:(int)index;
- (void)    _setCurrent:(double)current forSupply:(int)index;
- (double)  _getCurrent:(int)supply;
- (void)    _setADCList:(NSArray*)anArray;
- (void)    _setRealProcessingTime:(NSTimeInterval)interv;

- (void) _setOrientationMatrix:(NSArray*)anArray;
- (void) _setMagnetometerMatrix:(NSArray*)anArray;
- (void) _setActiveChannelMatrix:(NSArray*)anArray;
- (void) _setSensorInfo:(NSData*)anArray;
- (void) _setSensorDirectInfo:(NSArray*)anArray;
- (void) _setConversionMatrix:(NSData*)aData;
- (void) _setSensitivityMatrix:(NSData*)aData withChannels:(NSUInteger) nChannels withCoils:(NSUInteger) nCoils;

- (BOOL) _checkArray:(NSArray*)anArray;
- (BOOL) _verifyMatrixSizes:(NSArray*)feedBackMatrix orientationMatrix:(NSArray*)orMax magnetometerMap:(NSArray*)magMap;

- (void) _checkForErrors; // throws exceptions
- (void) _runAlertOnMainThread:(NSException *)exc;
- (void) _pushRunStatusToDB;
@end

#define CALL_SELECTOR_ONALL_POWERSUPPLIES(x)      \
{                                                 \
NSEnumerator* anEnum = [objMap objectEnumerator]; \
for (id obj in anEnum) [obj x];                   \
}

#define CALL_SELECTOR_ONALL_ADCS(x)               \
{                                                 \
for (id obj in listOfADCs) [obj x];               \
}


#define ORnEDMCoil_DEBUG 1

@implementation ORnEDMCoilModel (private)

- (void) _runThread
{
    [self initializeForRunning];
    CALL_SELECTOR_ONALL_POWERSUPPLIES(resetTrips);
    
    // Actively shut everything off.
    if (debugRunning) {
        CALL_SELECTOR_ONALL_POWERSUPPLIES(setAllOutputToBeOn:NO);
    } else {
        CALL_SELECTOR_ONALL_POWERSUPPLIES(setAllOutputToBeOn:YES);
    };

    //Wait for everything to start up.
    [NSThread sleepForTimeInterval:1.0];
    
    NSRunLoop* rl = [NSRunLoop currentRunLoop];
    
    [lastProcessStartDate release];
    lastProcessStartDate = nil;
    [self _setRealProcessingTime:0.0];
    @try {
        // make sure we schedule the run
        [self performSelector:@selector(_runProcess) withObject:nil afterDelay:0.5];
        if (postDataToDB){
            [self performSelector:@selector(_saveFieldMapLoop:)
                       withObject:[NSNumber numberWithDouble:postToDBPeriod]
                       afterDelay:1.0];
        }
        
        // perform the run loop, but cancel every second to check whether we should still run.
        while( isRunning ) {
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            if (![rl runMode:NSDefaultRunLoopMode
                  beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]) {
                [pool drain];
                break;
            }
            [pool drain];
        }
        
        
    } @catch (NSException * exc) {
        [self _stopRunning];        
        [self performSelectorOnMainThread:@selector(_runAlertOnMainThread:)
                               withObject:exc
                            waitUntilDone:NO];
    } @finally {
        [self cleanupForRunning];
        [self _setRealProcessingTime:0.0];
        
        // Finally notify that we've finished.
        [self _pushRunStatusToDB];
        [[NSNotificationCenter defaultCenter]
         postNotificationOnMainThreadWithName:ORnEDMCoilPollingActivityChanged
         object:self];
        
    }
    
}

- (void) _saveFieldMapLoop:(NSNumber*)atime
{
    [self _saveFieldMapInDB];
    if (!isRunning) return; // This is generally unnecessary
    [self performSelector:@selector(_saveFieldMapLoop:) withObject:atime afterDelay:[atime floatValue]];
}

- (void) _setCurrentMemory:(NSMutableData*)aData
{
    [aData retain];
    [CurrentMemory release];
    CurrentMemory = aData;
    // No notification implemented, since CurrentMemory is chaning very fast
}

- (void) _setCurVector:(NSData*)aData
{
    [aData retain];
    [CurVector release];
    CurVector = aData;
    // No notification implemented, since CurVector is chaning very fast
}

- (void) _setFieldTarget:(NSData*)aData
{
    [aData retain];
    [FieldTarget release];
    FieldTarget = aData;
    [[NSNotificationCenter defaultCenter]
     postNotificationOnMainThreadWithName:ORnEDMCoilTargetFieldHasChanged
                                   object:self];
}

- (void) _setStartCurrent:(NSArray*)anArray
{
    [anArray retain];
    [StartCurrent release];
    StartCurrent = anArray;
    [[NSNotificationCenter defaultCenter]
     postNotificationOnMainThreadWithName:ORnEDMCoilStartCurrentHasChanged
     object:self];
}

- (void) _runProcess
{
    // The current calculation process
    NSDate* now = [[NSDate date] retain];
    if (lastProcessStartDate != nil){
        [self _setRealProcessingTime:[now timeIntervalSinceDate:lastProcessStartDate]];
        [lastProcessStartDate release];
    }
    lastProcessStartDate = now;
    for (id adc in listOfADCs) {
        if (![adc isPolling]) {
            [NSException raise:@"nEDM Coil" format:@"ADC %@, Crate: %d, Slot: %d not polling.",[adc objectName],[adc crateNumber],[adc slot]];
        }
    }
    NSData* currentVector = [self _calcPowerSupplyValues];
    if (verbose) NSLog(@"Currents updated\n");

    [self _syncPowerSupplyValues:currentVector];

    // Force a readback of all values.
    CALL_SELECTOR_ONALL_POWERSUPPLIES(readback:NO);
    if(pollingFrequency!=0){
        // Wait until every command has completed so that we stay synchronized with the device.
        [self _checkForErrors];
        NSTimeInterval delay = (1.0/pollingFrequency) + [lastProcessStartDate timeIntervalSinceNow];
        if (delay < 0) delay = 0.0;
        [self performSelector:@selector(_runProcess)
                   withObject:nil
                   afterDelay:delay];
    } else {
        [self _stopRunning];
    }
}


- (void) _readADCValues
{
    // Reads current ADC values, creating a list of channels (128 for each ADC)

    uint32_t sizeOfArray = 0;
    for (id obj in listOfADCs) {
        sizeOfArray += [obj numberOfChannels];
    }
    assert([self numberOfChannels] <= sizeOfArray);
    
    sizeOfArray *= sizeof(double);

    if (!currentADCValues || [currentADCValues length] != sizeOfArray) {
        [currentADCValues release];
        currentADCValues = [[NSMutableData dataWithLength:sizeOfArray] retain];
    }
    double* ptr = (double*)[currentADCValues bytes];
    int j = 0;
    for (id obj in listOfADCs){
        [obj convertedValues:(ptr + j) range:NSMakeRange(0, [obj numberOfChannels])];
        j += [obj numberOfChannels];
    }        
    
}

- (NSMutableData*) _transposeData:(NSMutableData*)inData withColumns:(int)cols
{
    int rows = (int)([inData length] /(cols * sizeof(double)));
    NSMutableData* data = [NSMutableData dataWithData:inData];
    NSMutableData* outData = [NSMutableData dataWithLength:[data length]];
    double* dataPtr = (double*) [data bytes];
    double* outDataPtr = (double*) [outData bytes];
    int i, j;
    for (i=0; i < cols; i++) {
        for (j= 0; j < rows; j++) {
            outDataPtr[i * rows + j] = dataPtr[j * cols+ i];
        }
    }
    return outData;
}

- (NSData*) _calcPowerSupplyValues
{
    // Calculates the desired power supply currents given.  Johannes, you should start here,
    // grabbing desired field values using [self _fieldAtMagnetometer:index]; and setting the 
    // current using [self _setCurrent:currentValue forSupply:index];
    
    //init FieldVectormutable
    
    NSUInteger nCoil = [self numberOfCoils];
    NSUInteger nChannel = [self numberOfChannels];

    NSData* CurrentVector = CurVector;
    if (!CurrentVector) {
        CurrentVector = [NSMutableData data];
        [self _readCurrentValues:(NSMutableData*)CurrentVector];
    }
    double* curVectorPtr = (double*) [CurrentVector bytes];
    
    if (!_PrevCurrentLocal) _PrevCurrentLocal = [[NSMutableData data] retain];
    [_PrevCurrentLocal setData:CurrentVector];
    double* prevCurPtr = (double*)[_PrevCurrentLocal bytes];
    
    //Grab field values (including subtraction of target field)
    if (!_FieldVectorLocal) _FieldVectorLocal = [[NSMutableData data] retain];
    [_FieldVectorLocal setLength:(nChannel*sizeof(double))];
    double* ptr = (double*)[_FieldVectorLocal bytes];

    [self _readADCValues];    
    int i;
    for (i=0; i<nChannel;i++) ptr[i] = [self _fieldAtMagnetometer:i] -  [self targetFieldAtMagnetometer:i];
    int simulationMode = (debugRunning) ? 0 : 1;
    int dynamic = (dynamicMode) ? 1 : 0;
    
    // Perform multiplication with FeedbackMatrix, product is automatically added to CurrentVector
    // Y = alpha*A*X + beta*Y
    cblas_dgemv(CblasRowMajor,      // Row-major ordering
                CblasNoTrans,       // Don't transpose
                (int)nCoil,      // Row number (A)
                (int)nChannel,   // Column number (A)
                1,                  // Scaling Factor alpha
                [FeedbackMatData bytes], // Matrix A
                (int)nChannel,   // Size of first dimension
                ptr,                // vector X
                1,                  // Stride (should be 1)
                simulationMode,     // Scaling Factor beta  //0 for simulation mode
                curVectorPtr,// vector Y
                1                   // Stride (should be 1)
                );
    
    
    // Proportional-Integral Control Loop

    if (!_DCurrentLocal) _DCurrentLocal = [[NSMutableData data] retain];
    [_DCurrentLocal setData:CurrentVector];
    double* dCurPtr = (double*)[_DCurrentLocal bytes];
    for (i=0; i<nCoil;i++) dCurPtr[i] = dynamic * (dCurPtr[i] - prevCurPtr[i]);
    
    // Adding current to memory, deleting oldest current if necessary
    double *curMemPtr = (double*) [CurrentMemory bytes];
    if(integralTerm!=0){
        int i;
        for (i=0; i<nCoil; i++) {
            if (CurrentMemorySize==0) {
                curMemPtr[i] = 0;
            } else {
                curMemPtr[i] += dCurPtr[i];
            }
        }
        CurrentMemorySize += 1;
    }
    double threshold = [self feedbackThreshold] /1000; //division by 1000 to convert from mA to A
    double nrm2DCur = cblas_dnrm2((int)nCoil, dCurPtr, 1) / sqrt(nCoil);
    if (nrm2DCur < threshold) {
        for (i=0; i<nCoil; i++) {
            dCurPtr[i] = 0;
        }
    
    }
    double* retCurPtr = curVectorPtr;

    // Calculate PI-value for next current
    if (CurrentMemorySize !=0) {
        for (i=0; i<nCoil;i++) retCurPtr[i] = prevCurPtr[i] + proportionalTerm * dCurPtr[i] + dynamic * integralTerm * curMemPtr[i]/(1+ 0*CurrentMemorySize);
    } else {
        for (i=0; i<nCoil;i++) retCurPtr[i] = prevCurPtr[i] + proportionalTerm * dCurPtr[i];
    }



    [self _setCurVector:CurrentVector];
    return CurrentVector;
    
}

- (void) _readCurrentValues:(NSMutableData*)inData
{
    // The following tells the power supplies to read the current value, we don't wait for the actual value.
    CALL_SELECTOR_ONALL_POWERSUPPLIES(sendCommandReadBackGetCurrentReadbackWithOutput:0);
    CALL_SELECTOR_ONALL_POWERSUPPLIES(sendCommandReadBackGetCurrentReadbackWithOutput:1);
    
    NSUInteger nCoil = [self numberOfCoils];
    [inData setLength:(nCoil*sizeof(double))];
    double* ptr = (double*)[inData bytes];
    
    // Also waits to ensure that the commands have finished
    [self _checkForErrors];
    
	int i;
    for (i=0; i<nCoil;i++){
        ptr[i] = [self _getCurrent:i];
    }
}

- (void) _syncPowerSupplyValues:(NSData*) currentVector
{
    // Will write the saved power supply values to the hardware

    
    NSUInteger nCoil = [self numberOfCoils];
    double* dblPtr = (double*)[currentVector bytes];
    int i;
    for (i=0; i<nCoil;i++){
        [self _setCurrent:dblPtr[i] forSupply:i];
    }
    [self _checkForErrors];

}

- (double) _fieldAtMagnetometer:(int)index
{
    // Returns the field at a given magnetometer, index is mapped.
    
    // MagnetometerMap is to contain list of channels of magnetometers in order of appearance in FM
    // Channel values are as in currentADCValues: 128 slots for each ADC
    
    // ToBeFixed: in current setup, z-channels are reading inverted values. Where to account for orientation? -> FluxGate object will be created
    if (index >= [MagnetometerMap count]) {
        NSLog(@"Index (%i) out of range of magnetometer map (%i)\n",index,[MagnetometerMap count]);
        return 0.0;
    }
    const double* ptr = [currentADCValues bytes];
    assert([[MagnetometerMap objectAtIndex:index] intValue] < [currentADCValues length]/sizeof(ptr[0]));
    double raw = ptr[[[MagnetometerMap objectAtIndex:index] intValue]];

    if (verbose) NSLog(@"Field %i: %f\n",index,raw);
    return raw;
    
}

- (void) _setCurrent:(double)current forSupply:(int)index 
{
    // Will save the current for a given supply,
    // magnetometers and channels naturally ordered
    // Mapping will be taken care of at GUI level
    
    //Account for reversed wiring in PowerSupplies
    current=current*[[OrientationMatrix objectAtIndex:index] intValue];

    // Check if current ranges of power supplies are exceeded, cancel
    if (current>MaxCurrent) {
        //[NSException raise:@"Current Exceeded in Coil" format:@"Current Exceeded in Coil Channel: %d",index];
        current = MaxCurrent;
    }
    if (current<0) {
        //[NSException raise:@"Current Negative in Coil" format:@"Current Negative in Coil Channel:%d",index];
        current = 0.0;
    }
    

    
    [[objMap objectForKey:[NSNumber numberWithInt:(index/2)]]
     setWriteToSetCurrentLimit:current
                    withOutput:(index%2)];
    
    if (verbose) NSLog(@"Set Current (%@,%@): %f\n",
                       [[objMap objectForKey:[NSNumber numberWithInt:(index/2)]] ipAddress],
                       [[objMap objectForKey:[NSNumber numberWithInt:(index/2)]] serialNumber],
                       current);
}

- (double) _getCurrent:(int)index
{
    double retVal = [[objMap objectForKey:[NSNumber numberWithInt:(index/2)]] readBackGetCurrentReadbackWithOutput:(index%2)];
    
    //Account for reversed wiring in PowerSupplies
    retVal=retVal*[[OrientationMatrix objectAtIndex:index] intValue];
    
    if (verbose) NSLog(@"Read back current (%@,%@): %f\n",[[objMap objectForKey:[NSNumber numberWithInt:(index/2)]] ipAddress],
          [[objMap objectForKey:[NSNumber numberWithInt:(index/2)]] serialNumber],retVal);
    return retVal;

}

#pragma mark •••Running
- (void) _stopRunning
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(_runProcess)
                                               object:nil];
	isRunning = NO;
    NSLog(@"Stopping nEDM Coil Compensation processing.\n");
}

- (void) _startRunning
{
    [self _setCurVector:nil];
    [self _setCurrentMemory:[NSMutableData dataWithLength:[self numberOfCoils] * sizeof(double)]];
    CurrentMemorySize = 0;
    [self connectAllPowerSupplies];
    
    if (FeedbackMatData != nil && OrientationMatrix != nil &&
        MagnetometerMap != nil &&
        [self _verifyMatrixSizes:nil
               orientationMatrix:OrientationMatrix
                 magnetometerMap:MagnetometerMap] ) {
        [self _setUpRunning:YES];    
    } else {
         ORRunAlertPanel(@"Error", @"Input matrices are inconsistent or non-existent.  Process can not be started.", nil , nil,nil);
    }
}

- (void) _setUpRunning:(BOOL)aVerb
{
	
	if(isRunning && pollingFrequency != 0)return;
    
    if(postDataToDB) [self _saveStaticInfoInDB];
    if(pollingFrequency!=0){  
		isRunning = YES;
        if(aVerb) NSLog(@"Running nEDM Coil compensation at a rate of %.2f Hz.\n",pollingFrequency);
        [NSThread detachNewThreadSelector:@selector(_runThread)
                                 toTarget:self
                               withObject:nil];
    }
    else {
        if(aVerb) NSLog(@"Not running nEDM Coil compensation, polling frequency set to 0\n");
    }
    [self _pushRunStatusToDB];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilPollingActivityChanged
	 object: self];
}

- (void) _setADCList:(NSMutableArray*)anArray
{
    [anArray retain];
    [listOfADCs release];
    listOfADCs = anArray;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilADCListChanged
	 object: self];        
}


- (void) _setOrientationMatrix:(NSMutableArray*)anArray
{
    [anArray retain];
    [OrientationMatrix release];
    OrientationMatrix = anArray;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilHWMapChanged object: self];
}

- (void) _setMagnetometerMatrix:(NSMutableArray*)anArray
{
    [anArray retain];
    [MagnetometerMap release];
    MagnetometerMap = anArray;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilHWMapChanged object: self];
}

- (void) _setActiveChannelMatrix:(NSMutableArray*)anArray
{
    [ActiveChannelMap release];
    if ([[anArray objectAtIndex:0] isKindOfClass:[NSArray class]]){
        ActiveChannelMap = nil;
        [[NSNotificationCenter defaultCenter]
         postNotificationName:ORnEDMCoilSensitivityMapChanged object: self];
        return;
    }

    [anArray retain];
    ActiveChannelMap = anArray;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilSensitivityMapChanged object: self];
}

- (void) _setSensorInfo:(NSMutableArray*)anArray
{
    [anArray retain];
    [SensorInfo release];
    SensorInfo = anArray;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilSensorInfoChanged object: self];
}

- (void) _setSensorDirectInfo:(NSMutableArray *)anArray
{
    [anArray retain];
    [SensorDirectInfo release];
    SensorDirectInfo = anArray;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORnEDMCoilSensorInfoChanged object:self]
    ;}

- (void) _setConversionMatrix:(NSMutableData*)aData
{
    [aData retain];
    [FeedbackMatData release];
    FeedbackMatData = aData;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilHWMapChanged object: self];
}

- (void) _setSensitivityMatrix:(NSMutableData*)aData withChannels:(NSUInteger) nChannels withCoils:(NSUInteger) nCoils
{
    
    [aData retain];
    [SensitivityMatData release];
    if ([aData length] != nChannels*nCoils*sizeof(double)) {
        SensitivityMatData = nil;
        [aData release];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:ORnEDMCoilSensitivityMapChanged object: self];
        return;
    }
    SenNumChannels = nChannels;
    SenNumCoils = nCoils;
    SensitivityMatData = aData;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilSensitivityMapChanged object: self];
}

- (BOOL) _checkArray:(NSArray *)anArray
{
    int i;
    int len = (int)[[anArray objectAtIndex:0] count];
    for (i=0; i<[anArray count]; i++) {
        if([[anArray objectAtIndex:i] count] != len) return FALSE;
    }
    return TRUE;
}

- (BOOL) _verifyMatrixSizes:(NSArray*)feedBackMatrix orientationMatrix:(NSArray*)orMax magnetometerMap:(NSArray*)magMap
{
    // Returns YES when matrix sizes are OK.
    
    @try {
        if (feedBackMatrix != nil) {
            // Means the feedback matrix is being defined.
            for (id e in feedBackMatrix) {
                if (![e isKindOfClass:[NSArray class]]) {
                    [NSException raise:@"MatrixReadInError"
                                format:@"Feedback Matrix is mal-formed."];
                }
                for (id var in e) {
                    if (![var isKindOfClass:[NSNumber class]]) {
                        [NSException raise:@"MatrixReadInError"
                                    format:@"Feedback Matrix is mal-formed."];
                    }
                }
            }
            NumberOfChannels   = (int)[[feedBackMatrix objectAtIndex: 0] count];
            NumberOfCoils      = (int)[feedBackMatrix count];
        }

        for (id e in orMax) {
            if (![e isKindOfClass:[NSNumber class]]) {
                [NSException raise:@"MatrixReadInError"
                            format:@"Input matrices are malformed."];
            }
        }
        for (id e in magMap) {
            if (![e isKindOfClass:[NSNumber class]]) {
                [NSException raise:@"MatrixReadInError"
                            format:@"Input matrices are malformed."];
            }
        }
        
        // Can't test if we don't know the number of coils or channels
        if (NumberOfCoils == 0 || NumberOfChannels == 0) return YES;
        if ((orMax != nil && [orMax count] != NumberOfCoils) &&
            (magMap != nil && [magMap count] != NumberOfChannels)) {
            [NSException raise:@"MatrixReadInError"
                        format:@"Input matrices are inconsistent.  Either try again, or reset the already input data."];
        }

    } @catch(NSException *e) {
        // This means something was wrong with the data, return NO!
        ORRunAlertPanel(@"Error", @"%@", nil , nil,nil,[e reason]);
        return NO;
    }
    return YES;
}

- (void) _checkForErrors
{
    NSEnumerator* e = [objMap objectEnumerator];
    for (ORTTCPX400DPModel* i in e) {
        if (![i isConnected]) {
            [NSException raise:@"Not connected"
                        format:@"Not connected: (%@,%@,%@)",[i objectName],[i ipAddress],[i serialNumber]];
        }
        [i checkAndClearErrors:NO];

    }
    e = [objMap objectEnumerator];    
    for (ORTTCPX400DPModel* i in e) {
        [i waitUntilCommandsDone];
        if ([i currentErrorCondition]) {
            [NSException raise:@"Error in nEDM Coil"
                        format:@"Error in nEDM Coil (%@,%@,%@)",[i objectName],[i ipAddress],[i serialNumber]];
        }
    }
}

- (void) _runAlertOnMainThread:(NSException*) exc
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    ORRunAlertPanel(nil, @"%@", @"OK", nil, nil,exc);
#else
    [[NSAlert alertWithMessageText:nil
                    defaultButton:nil
                  alternateButton:nil
                      otherButton:nil
        informativeTextWithFormat:@"%@",exc] runModal];
#endif
}

- (void) _setRealProcessingTime:(NSTimeInterval)timeint
{
    realProcessingTime = timeint;
    [[NSNotificationCenter defaultCenter]
	 postNotificationOnMainThreadWithName:ORnEDMCoilRealProcessTimeHasChanged
	 object: self];
}

- (void) _saveStaticInfoInDB
{
    // Save the static information in DB
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [self magnetometerMap],@"MagnetometerMap",
                          [self orientationMatrix],@"OrientationMatrix",
                          [self runComment],@"RunComment",
                          @"configuration",@"type",nil];
    NSDictionary* postDict = [NSDictionary dictionaryWithObjectsAndKeys:dict,@"Document",
                              [self postToPath],@"Address",nil];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationOnMainThreadWithName:@"ORCouchDBPostOrPutCustomRecord"
     object:self
     userInfo:postDict];
    
}
- (void) _saveFieldMapInDB
{
    // Save the fields in DB

    int i;
    NSUInteger nChannel = [self numberOfChannels];
    NSUInteger nCoil = [self numberOfCoils];
    [self _readADCValues]; // ensures that we've read
    NSMutableDictionary* array = [NSMutableDictionary dictionaryWithCapacity:(nChannel + nCoil)];
    for (i=0;i<nChannel;i++) {
        [array setObject:[NSNumber numberWithDouble:[self _fieldAtMagnetometer:i]]
                  forKey:[NSString stringWithFormat:@"FieldMap_%i",i]];
    }
    if (!_CurrentDataLocal) _CurrentDataLocal = [[NSMutableData data] retain];
    [self _readCurrentValues:_CurrentDataLocal];
    double* ptr = (double*)[_CurrentDataLocal bytes];
    
    for (i=0;i<nCoil;i++) {
        [array setObject:[NSNumber numberWithDouble:ptr[i]]
                  forKey:[NSString stringWithFormat:@"Coil_%i",i]];
    }
    
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          array,@"value",
                          @"data",@"type",
                          nil];
    NSDictionary* postDict = [NSDictionary dictionaryWithObjectsAndKeys:dict,@"Document",
                              [self postToPath],@"Address",nil];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationOnMainThreadWithName:@"ORCouchDBPostOrPutCustomRecord"
     object:self
     userInfo:postDict];
}

- (void) _pushRunStatusToDB
{
    if (!postDataToDB) return;
    NSDictionary* array = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:isRunning],@"run_status",nil];
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          array,@"value",
                          @"data",@"type",
                          nil];
    NSDictionary* postDict = [NSDictionary dictionaryWithObjectsAndKeys:dict,@"Document",
                              [self postToPath],@"Address",nil];
    [[NSNotificationCenter defaultCenter]
     postNotificationOnMainThreadWithName:@"ORCouchDBPostOrPutCustomRecord"
     object:self
     userInfo:postDict];
}
@end

@implementation ORnEDMCoilModel

#pragma mark •••initialization

- (id) init
{
    self = [super init];
    [self _setFieldTarget:nil];
    return self;
}

- (void) dealloc
{
    [objMap release];
    [listOfADCs release];
    [currentADCValues release];  
    [FeedbackMatData release];
    [lastProcessStartDate release];
    [CurVector release];
    [CurrentMemory release];
    [FieldTarget release];
    [StartCurrent release];
    [postToPath release];
    [RunComment release];
    
    // Release cache variables
    [_PrevCurrentLocal release];
    [_FieldVectorLocal release];
    [_CurrentDataLocal release];
    [_DCurrentLocal release];
    [super dealloc];
}

- (void) makeConnectors
{	
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"nEDMCoil"]];
    // The following code might still be useful, hold on to it for the time being.  - M. Marino
}

- (void) makeMainController
{
    [self linkToController:@"ORnEDMCoilController"];
}

- (BOOL) isRunning
{
    return isRunning;
}

- (float) realProcessingTime
{
    return realProcessingTime;
}

- (float) pollingFrequency
{
    return pollingFrequency;
}

- (float) proportionalTerm
{
    return proportionalTerm;
}

- (float) integralTerm
{
    return integralTerm;
}

- (float) feedbackThreshold
{
    return feedbackThreshold;
}

- (float) regularizationParameter
{
    return regularizationParameter;
}

- (BOOL) debugRunning
{
    return debugRunning;
}

- (BOOL) dynamicMode
{
    return dynamicMode;
}

- (void) setDebugRunning:(BOOL)debug
{
    if (debug == debugRunning) return;
    debugRunning = debug;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilDebugRunningHasChanged
	 object: self];     
}

- (void) setDynamicMode:(BOOL)dynamic
{
    if (dynamic == dynamicMode) return;
    if (dynamic) {
        CurrentMemorySize = 0;
        [self setTargetField];
    }
    dynamicMode = dynamic;

    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilDynamicModeHasChanged
	 object: self];
}

- (void) connectAllPowerSupplies
{
    CALL_SELECTOR_ONALL_POWERSUPPLIES(connect);
}

- (void) addADC:(id)adc
{
    if (!listOfADCs) listOfADCs = [[NSMutableArray array] retain];
    // FixME Add protection for double entries
    [listOfADCs addObject:adc];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilADCListChanged
	 object: self];     
}

- (void) removeADC:(id)adc
{
    [listOfADCs removeObject:adc];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilADCListChanged
	 object: self];         
}

- (NSArray*) listOfADCs
{
    if (!listOfADCs) listOfADCs = [[NSMutableArray array] retain];
    return listOfADCs;
}

- (int) numberOfChannels
{
    return NumberOfChannels;
}

- (int) numberOfCoils
{
    return NumberOfCoils;
}

- (int) mappedChannelAtChannel:(int)aChan
{
    if (aChan >= [MagnetometerMap count]) return -1;
    return [[MagnetometerMap objectAtIndex:aChan] intValue];
}

- (int) activeChannelAtChannel:(int)aChan
{
    if (aChan >= [ActiveChannelMap count]) return -1;
    return [[ActiveChannelMap objectAtIndex:aChan] intValue];
}

- (double) xPositionAtChannel:(int)aChan
{
    if (aChan >= [SensorInfo count]) return -1;
    return [[[SensorInfo objectAtIndex:aChan] objectAtIndex:0] doubleValue];
}

- (double) yPositionAtChannel:(int)aChan
{
    if (aChan >= [SensorInfo count]) return -1;
    return [[[SensorInfo objectAtIndex:aChan] objectAtIndex:1] doubleValue];
}

- (double) zPositionAtChannel:(int)aChan
{
    if (aChan >= [SensorInfo count]) return -1;
    return [[[SensorInfo objectAtIndex:aChan] objectAtIndex:2] doubleValue];
}

- (NSString*) fieldDirectionAtChannel:(int)aChar
{
    if (aChar >= [SensorInfo count]) return @"";
    return [[SensorInfo objectAtIndex:aChar] objectAtIndex:[[SensorInfo objectAtIndex:aChar] count]];
}

- (double) conversionMatrix:(int)channel coil:(int)aCoil
{
    NSUInteger nChannel = [self numberOfChannels];
    NSUInteger nCoil = [self numberOfCoils];
    if (aCoil > nCoil || channel > nChannel) return 0.0;
    double* dblPtr = (double*)[FeedbackMatData bytes];
    return dblPtr[aCoil*nChannel + channel];
}

- (double) sensitivityMatrix:(int)coil channel:(int)aChannel
{
    if (SensitivityMatData==nil) return 0.0;
    if (coil > SenNumCoils || aChannel > SenNumChannels) return 0.0;
    double* dblPtr = (double*)[SensitivityMatData bytes];
    return dblPtr[aChannel*SenNumCoils + coil];
}

- (void) setPollingFrequency:(float)aFrequency
{
    if (pollingFrequency == aFrequency) return;
    pollingFrequency = aFrequency;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilPollingFrequencyChanged
	 object: self];
}

- (void) setProportionalTerm:(float)aValue
{
    if (proportionalTerm == aValue) return;
    proportionalTerm = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilProportionalTermChanged
	 object: self];
}

- (void) setIntegralTerm:(float)aValue
{
    if (integralTerm == aValue) return;
    integralTerm = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilIntegralTermChanged
	 object: self];
}

- (void) setFeedbackThreshold:(float)aValue
{
    if (feedbackThreshold == aValue) return;
    feedbackThreshold = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilFeedbackThresholdChanged
	 object: self];
}

- (void) setRegularizationParameter:(float)aValue
{
    if (regularizationParameter == aValue) return;
    regularizationParameter = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilRegularizationParameterChanged
	 object: self];
}

- (void) setRunComment:(NSString *)aString
{
    [RunComment release];
    RunComment = [aString copy];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilRunCommentChanged
	 object: self];
}

- (BOOL) verbose
{
    return verbose;
}

- (BOOL) withStartCurrent
{
    bool tempbool = FALSE;
    double tempcur;
    int i;
    for (i=0; i<[self numberOfCoils];i++){
        tempcur = [self startCurrentAtCoil:i];
        if (tempcur != 0) {
            tempbool = TRUE;
        };
    };
    return tempbool;
}

- (void) setVerbose:(BOOL)aVerb
{
    if (verbose == aVerb) return;
    verbose = aVerb;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilVerboseHasChanged
	 object: self];
}

- (void) setPostDataToDB:(BOOL)postData
{
    if (postDataToDB == postData) return;
    postDataToDB = postData;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilPostDataToDBHasChanged
	 object: self];
}
- (BOOL) postDataToDB
{
    return postDataToDB;
}

- (void) setPostDataToDBPeriod:(NSTimeInterval)period
{
    if (period < 1.0) period = 1.0;
    postToDBPeriod = period;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilPostDataToDBPeriodHasChanged
	 object: self];
}

- (NSTimeInterval) postDataToDBPeriod
{
    return postToDBPeriod;
}

- (NSString*) postToPath
{
    if (!postToPath) return @"";
    return postToPath;
}

- (void) setPostToPath:(NSString *)aPath
{
    [postToPath release];
    postToPath = [aPath copy];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilPostToPathHasChanged
	 object: self];
}

- (void) initializeForRunning
{
    CALL_SELECTOR_ONALL_POWERSUPPLIES(setUserLock:YES withString:@"nEDM Coil Process");
    int i;
    NSUInteger nCoil = [self numberOfCoils];
    if ([self withStartCurrent]) {
        for (i=0; i<nCoil;i++){
            [self _setCurrent:[self startCurrentAtCoil:i] forSupply:i];
            [self setVoltage:MaxVoltage atCoil:i];
        }
        CALL_SELECTOR_ONALL_POWERSUPPLIES(setAllOutputToBeOn:YES);
    } else {
        for (i=0; i<nCoil;i++){
            [self _setCurrent:0 forSupply:i];
            [self setVoltage:MaxVoltage atCoil:i];
        }
    }
    CALL_SELECTOR_ONALL_ADCS(setUserLock:YES withString:@"nEDM Coil Process");
    CALL_SELECTOR_ONALL_ADCS(startPollingActivity);
}

- (void) cleanupForRunning
{
    CALL_SELECTOR_ONALL_ADCS(stopPollingActivity);
    CALL_SELECTOR_ONALL_ADCS(setUserLock:NO withString:@"nEDM Coil Process");
    
    int i;
    for (i=0; i<[self numberOfCoils];i++){
        [self _setCurrent:0 forSupply:i];
        [self setVoltage:1.0 atCoil:i];
    }
    CALL_SELECTOR_ONALL_POWERSUPPLIES(setAllOutputToBeOn:NO);
    CALL_SELECTOR_ONALL_POWERSUPPLIES(setUserLock:NO withString:@"nEDM Coil Process");
    CALL_SELECTOR_ONALL_POWERSUPPLIES(readback);
    [CurVector release];
    CurVector = nil;
    [CurrentMemory release];
    CurrentMemory = nil;
}

- (void) toggleRunState
{
    if (isRunning) [self _stopRunning];
    else [self _startRunning];
}

- (void) initializeSensitivityMatrixWithPlistFile:(NSString*)plistFile
{
    NSLog(@"Reading SensitivityMatrix\n");
    
    // reads SensitivityMatrix from GUI
    // SensitivityMatrix is 180 x 24 (Channels x Coils), unused columns filled with 0s
    
    // Build the array from the plist
    NSArray *RawSensitivityMatrix = [NSArray arrayWithContentsOfFile:plistFile];
    if ([self _checkArray:RawSensitivityMatrix]) {
        //nil;
    } else {
        NSLog(@"Length of rows is incosistent");
        return;
    }
    NSUInteger senChannels = [RawSensitivityMatrix count];
    NSUInteger senCoils = [[RawSensitivityMatrix objectAtIndex:0] count];

    NSMutableData* matData = [NSMutableData dataWithLength:senChannels*senCoils*sizeof(double)];
    double* dblPtr = (double*)[matData bytes];
    
    int line,i;
    for(line=0; line<senChannels; line++){
        for (i=0; i<senCoils;i++){
            dblPtr[line*senCoils + i] = [[[RawSensitivityMatrix objectAtIndex:line] objectAtIndex:i] doubleValue];
        }
    }
    [self _setSensitivityMatrix:matData withChannels:senChannels withCoils:senCoils];
    
#ifdef ORnEDMCoil_DEBUG
    NSLog(@"Filled SensitivityMatData\n");
    for (i=0; i<SenNumChannels*SenNumCoils;i++) NSLog(@"%f\n",dblPtr[i]);
    NSLog(@"output complete\n");
#endif
}

- (void) initializeOrientationMatrixWithPlistFile:(NSString*)plistFile
{
    
    NSMutableArray* orientMat = [NSMutableArray arrayWithContentsOfFile:plistFile];
    NSArray* oldOrientMat = [NSArray arrayWithArray:OrientationMatrix];

    //if( ![self _verifyMatrixSizes:nil orientationMatrix:orientMat magnetometerMap:MagnetometerMap] ) return;
    if ([OrientationMatrix count] != [self numberOfCoils]) {
        NSLog(@"OrientMatrix and FeedbackMatrix are incompatible! Please select a suitable OrientationMatrix.");
        [self _setOrientationMatrix:oldOrientMat];
        return;
    }
    
    [self _setOrientationMatrix:orientMat];
    
#ifdef ORnEDMCoil_DEBUG
    NSLog(@"OrientationMatrix read:");
    int i;
    for (i=0; i<[orientMat count]; i++) {
        NSLog([NSString stringWithFormat:@"element: %f\n",[[orientMat objectAtIndex:i] floatValue]]);
    }
#endif

    
}

- (void) initializeMagnetometerMapWithPlistFile:(NSString*)plistFile
{
    NSMutableArray* magMap = [NSMutableArray arrayWithContentsOfFile:plistFile];
    NSArray* oldMagMap = [NSArray arrayWithArray:MagnetometerMap];
    //if( ![self _verifyMatrixSizes:nil orientationMatrix:OrientationMatrix magnetometerMap:magMap] ) return;
    if ([magMap count] != [self numberOfChannels]) {
        NSLog(@"MagnetometerMap and FeedbackMatrix are incompatible! Please select a suitable MagnetometerMap.");
        [self _setMagnetometerMatrix:oldMagMap];
        return;
    }
    [self _setMagnetometerMatrix:magMap];
    
#ifdef ORnEDMCoil_DEBUG
    NSLog(@"MagnetometerMap read:\n");
    int i;
    for (i=0; i<[magMap count]; i++) {
        NSLog([NSString stringWithFormat:@"element: %f\n",[[magMap objectAtIndex:i] floatValue]]);
    }
#endif
}

- (void) initializeActiveChannelMapWithPlistFile:(NSString*)plistFile
{
    NSMutableArray* actchaMap = [NSMutableArray arrayWithContentsOfFile:plistFile];
    //if( ![self _verifyMatrixSizes:nil orientationMatrix:OrientationMatrix magnetometerMap:actchaMap] ) return;
    [self _setActiveChannelMatrix:actchaMap];
    
#ifdef ORnEDMCoil_DEBUG
    NSLog(@"MagnetometerMap read:\n");
    int i;
    for (i=0; i<[actchaMap count]; i++) {
        NSLog([NSString stringWithFormat:@"element: %f\n",[[actchaMap objectAtIndex:i] floatValue]]);
    }
#endif
}

//- (void) initializeSensorInfoWithPlistFile:(NSString*)plistFile
//{
//    NSMutableArray* senInfo = [NSMutableArray arrayWithContentsOfFile:plistFile];
//    //if( ![self _verifyMatrixSizes:nil orientationMatrix:OrientationMatrix magnetometerMap:actchaMap] ) return;
//    [self _setSensorInfo:senInfo];
//
//#ifdef ORnEDMCoil_DEBUG
//    NSLog(@"MagnetometerMap read:\n");
//    int i;
//    for (i=0; i<[senInfo count]; i++) {
//        NSLog([NSString stringWithFormat:@"element: %f\n",[[senInfo objectAtIndex:i] floatValue]]);
//    }
//#endif
//}

- (void) initializeSensorInfoWithPlistFile:(NSString*)plistFile
{
    NSLog(@"Reading SensorInfo\n");
    NSArray *RawSensorInfo = [NSArray arrayWithContentsOfFile:plistFile];
    NSUInteger RawSensorInfoLength;
    NSUInteger RawSensorDirectInfoLength;
    RawSensorInfoLength = [RawSensorInfo count]*([[RawSensorInfo objectAtIndex:0] count]-1)*sizeof(double);
    RawSensorDirectInfoLength = [RawSensorInfo count]*sizeof(char);
    
    // Initialise SensorInfo
    NSMutableData* senInfo = [NSMutableData dataWithLength:RawSensorInfoLength];
    NSMutableArray* senDirectInfo = [NSMutableArray array];
    double* dblPtr = (double*)[senInfo bytes];
    
    int line,i;
    for(line=0; line<[RawSensorInfo count]; line++){
        //chrPtr[line] = [[[RawSensorInfo objectAtIndex:line] objectAtIndex:([[RawSensorInfo objectAtIndex:line] count]-1)] charValue];
        [senDirectInfo addObject:[[RawSensorInfo objectAtIndex:line] objectAtIndex:3]];
        
        for (i=0; i<([[RawSensorInfo objectAtIndex:line] count] - 1);i++){
            dblPtr[line*([[RawSensorInfo objectAtIndex:line]count]-1) + i] = [[[RawSensorInfo objectAtIndex:line] objectAtIndex:i] doubleValue];
        }
    }
    [self _setSensorInfo:senInfo];
//    int line2;
//    for (line2=0; line2<[RawSensorInfo count]; line2++){
//        chrPtr[line2] = [[[RawSensorInfo objectAtIndex:line2] objectAtIndex:([[RawSensorInfo objectAtIndex:line2] count]-1)] charValue];
//    }
    [self _setSensorDirectInfo:senDirectInfo];
    
#ifdef ORnEDMCoil_DEBUG
    NSLog(@"Filled SensorInformationMap\n");
    for (i=0; i<RawSensorInfoLength/sizeof(double);i++) NSLog(@"%f\n",dblPtr[i]);
    NSLog(@"Filled SensorDirectionMap\n");
    for (i=0; i<RawSensorDirectInfoLength/sizeof(char);i++) NSLog(@"%@\n",[senDirectInfo objectAtIndex:i]);
    NSLog(@"output complete\n");
#endif
}    
- (void) saveCurrentFieldInPlistFile:(NSString*)plistFile
{
    NSUInteger nChannel = [self numberOfChannels];
    NSMutableArray* tempArray = [NSMutableArray arrayWithCapacity:nChannel];
    
    int i;
    for(i=0;i<nChannel;i++) [tempArray insertObject:[NSNumber numberWithDouble:[self fieldAtMagnetometer:i]] atIndex:i];
    
    [tempArray writeToFile:plistFile atomically:YES];
}

- (void) loadTargetFieldWithPlistFile:(NSString*)plistFile
{
    NSArray* targetFieldRaw = [NSArray arrayWithContentsOfFile:plistFile];
    NSMutableData* targetField = [NSMutableData dataWithLength:[targetFieldRaw count] *sizeof(double)];
    double* targetFieldPtr = (double*) [targetField bytes];
    int i;
    for (i=0; i<[targetFieldRaw count]; i++) {
        targetFieldPtr[i] = [[targetFieldRaw objectAtIndex:i] doubleValue];
    }
    NSData* oldTargetField = [NSData dataWithData:FieldTarget];
    //if( ![self _verifyMatrixSizes:nil orientationMatrix:OrientationMatrix magnetometerMap:targetField] ) return;
    if ([targetField length]/sizeof(double)!= [self numberOfChannels]) {
        NSLog(@"FieldTarget and FeedbackMatrix are incompatible! Please select a suitbale FieldTarget.\n");
        [self _setFieldTarget:oldTargetField];
        return;
    }
    [self _setFieldTarget:targetField];
}

- (void) setTargetField
{
    NSUInteger nChannel = [self numberOfChannels];
    NSMutableData* tempData = [NSMutableData dataWithLength:nChannel * sizeof(double)];
    double* tempDataPtr = (double*) [tempData bytes];
    int n,i;
    int nmax;
    nmax = 10;
    for (n=0;n<nmax;n++){
        for(i=0;i<nChannel;i++){
            tempDataPtr[i] = tempDataPtr[i] + [self fieldAtMagnetometer:i];
        }
    }
    for(i=0;i<nChannel;i++){
        tempDataPtr[i] = tempDataPtr[i] /nmax;
    }

    [self _setFieldTarget:tempData];
}

- (void) setTargetFieldToZero
{
    [self _setFieldTarget:nil];
}

- (void) saveCurrentStartCurrentInPlistFile:(NSString*)plistFile
{
    NSUInteger nCoil = [self numberOfCoils];
    NSMutableArray* tempArray = [NSMutableArray arrayWithCapacity:nCoil];
    
    int i;
    for(i=0;i<nCoil;i++) [tempArray insertObject:[NSNumber numberWithDouble:[self readBackSetCurrentAtCoil:i]] atIndex:i];
    
    [tempArray writeToFile:plistFile atomically:YES];
}

- (void) loadStartCurrentWithPlistFile:(NSString*)plistFile
{
    NSArray* startCurrent = [NSArray arrayWithContentsOfFile:plistFile];
    NSArray* oldStartCurrent = [NSArray arrayWithArray:StartCurrent];
    //if( ![self _verifyMatrixSizes:nil orientationMatrix:startCurrent magnetometerMap:MagnetometerMap] ) return;
    if ([startCurrent count] != [self numberOfCoils]) {
        NSLog(@"StartCurrent and FeedbackMatrix are incompatible! Please select a suitbale StartCurrent.\n");
        [self _setStartCurrent:oldStartCurrent];
        return;
    }
    [self _setStartCurrent:startCurrent];
}

- (void) setStartCurrentToZero
{
    [self _setStartCurrent:nil];
}

- (void) startWithStartCurrent
{
    
    
}

- (void) resetConversionMatrix
{
    [self _setConversionMatrix:nil];
    //NumberOfChannels = 0;
    //NumberOfCoils    = 0;
    //[self resetMagnetometerMap];
    //[self resetOrientationMatrix];
}

- (void) resetSensitivityMatrix
{
    [self _setSensitivityMatrix:nil withChannels:0 withCoils:0];
    [self resetActiveChannelMap];
}

- (void) resetMagnetometerMap
{
    [self _setMagnetometerMatrix:nil];
}

- (void) resetActiveChannelMap
{
    [self _setActiveChannelMatrix:nil];
}

- (void) resetSensorInfo
{
    [self _setSensorInfo:nil];
    [self _setSensorDirectInfo:nil];
}

- (void) resetOrientationMatrix
{
    [self _setOrientationMatrix:nil];
}

- (void) buildFeedback
{
    if (isRunning){
        [self _stopRunning];
        NSLog(@"Run was stopped in order to build the new Feedback Matrix.\n");
    }

    int i, j, nChannel, nCoil, k;
    if (SensitivityMatData==nil || ActiveChannelMap==nil) return;
    NSMutableData* oldSensitivityMatData = [NSMutableData dataWithData:SensitivityMatData];
    double* oldSensitivityMatDataPtr = (double*) [oldSensitivityMatData bytes];
    NSMutableData* oldActiveChannel = [NSMutableData dataWithLength: [ActiveChannelMap count]*sizeof(double)];
    double* oldActiveChannelPtr = (double*)[oldActiveChannel bytes];
    
    for (i=0; i<[ActiveChannelMap count]; i++) {
        oldActiveChannelPtr[i] = (double)[[ActiveChannelMap objectAtIndex:i] doubleValue];
    }
    if (SenNumChannels != [ActiveChannelMap count]) {
        NSLog(@"SensitivityMap and ActiveChannelMap are incompatible.\n");
        return;
    }
    //NumberOfChannels = SenNumChannels;
    //NumberOfCoils = SenNumCoils;
    //nChannel = [self numberOfChannels];
    //nCoil = [self numberOfCoils];
    nChannel = (int)SenNumChannels;
    nCoil = (int)SenNumCoils;
    NSMutableData* aTA = [NSMutableData dataWithLength:nCoil*nCoil*sizeof(double)];
    NSMutableData* newSensitivityMatData = [NSMutableData dataWithLength:nCoil*nChannel*sizeof(double)];
    double* dblPtr = (double*) [newSensitivityMatData bytes];
    NSMutableData* newFeedback = [NSMutableData dataWithLength:nChannel*nCoil*sizeof(double)];

    // Scales some rows of the Sensitivity Matrix. This is used to remove some channels from the feedback algorithm.
    for (i=0; i < nChannel; i++) {
        if (oldActiveChannelPtr[i]!=0) oldActiveChannelPtr[i] = 1; //0 and 1 are the only valid entries
        for (j=0; j <nCoil; j++) {
            dblPtr[i*nCoil + j] = oldSensitivityMatDataPtr[i*nCoil+j] * oldActiveChannelPtr[i];
        }
    }
    
    //Builds reduced Sensitivity Matrix
    int nRedChannel = 0;
    for (i=0; i<nChannel; i++) {
        if (oldActiveChannelPtr[i]==1) nRedChannel++;
    }
    NSMutableData *redSensitivityMatData = [NSMutableData dataWithLength:nRedChannel*nCoil*sizeof(double)];
    double *redSensitivitiyMatDataPtr = (double*) [redSensitivityMatData bytes];
    k = 0;
    for (i=0; i<nChannel; i++) {
        for (j=0; j<nCoil; j++) {
            if (oldActiveChannelPtr[i]==1){
                redSensitivitiyMatDataPtr[k*nCoil + j] = oldSensitivityMatDataPtr[i*nCoil + j];
            }            
        }
        if (oldActiveChannelPtr[i]==1) k++;
    }
    // Calculates A^T . A (reduced version)
    cblas_dgemm(
                CblasRowMajor,
                CblasTrans,
                CblasNoTrans,
                nCoil,
                nCoil,
                nRedChannel,
                1,
                [redSensitivityMatData bytes],
                nCoil,
                [redSensitivityMatData bytes],
                nCoil,
                0,
                (double*) [aTA bytes],
                nCoil
                );
    
    NSMutableData* inverseMatData = [NSMutableData dataWithData:aTA];
    NSMutableData* pivotData = [NSMutableData dataWithLength:nCoil*sizeof(__CLPK_integer)];
    NSMutableData* workData = [NSMutableData dataWithLength:nCoil*sizeof(double)];
    __CLPK_integer n = nCoil;
    __CLPK_integer info;
    __CLPK_integer lwork = n;

    //Factorization of A^T . A. This is needed for the Matrixinversion
    dgetrf_(
            &n, // m: (number of rows in A)
            &n, // n: (number of columns in A)
            (double*) [inverseMatData bytes], // A: (input and output matrix)
            &n, // lda: (leading dimension of A -->should be here equal to m and n)
            (__CLPK_integer *) [pivotData bytes], //ipvt: (integer vector, containing the pivot indices)
            &info //info: ()
            );
    //MatrixInversion of A^T . A
    dgetri_(
            &n, // n: (order of the matrix)
            (double*) [inverseMatData bytes], // A: (the matrix which should be inverted, has to come from 'dgetrf')
            &n, // lda: (leading dimension of A)
            (__CLPK_integer*) [pivotData bytes], //ipvt: (integer vector containing the pivot indices)
            (double*) [workData bytes], //work: ()
            &lwork,
            &info);
    // Calculates the feedback matrix -(A^T . A)^-1 . A^T
    cblas_dgemm(
                CblasRowMajor,
                CblasNoTrans,
                CblasTrans,
                nCoil,
                nChannel,
                nCoil,
                -1,
                [inverseMatData bytes],
                nCoil,
                [newSensitivityMatData bytes],
                nCoil,
                0,
                (double*)[newFeedback bytes],
                nChannel
                );
    
    //Matrix regularization
    n = nChannel;
    __CLPK_integer m = nCoil;
    //n = 3;
    //__CLPK_integer m = 2;
    __CLPK_integer lda = m;
    __CLPK_integer ldu = m;
    __CLPK_integer ldvT = n;

    lwork = -1;
    NSMutableData* a = [NSMutableData dataWithData:newFeedback];
    //NSMutableData* a = [NSMutableData dataWithLength:m*n*sizeof(double)];
    //NSMutableData* test = [NSMutableData dataWithLength:m*n*sizeof(double)];
    NSMutableData* sigma = [NSMutableData dataWithLength:m*sizeof(double)];
    double* sigmaPtr = (double*)[sigma bytes];
    NSMutableData* sigmaMat = [NSMutableData dataWithLength:m*n*sizeof(double)];
    double* sigmaMatPtr = (double*) [sigmaMat bytes];
    NSMutableData* u = [NSMutableData dataWithLength:m*m*sizeof(double)];
    NSMutableData* vT = [NSMutableData dataWithLength:n*n*sizeof(double)];
    NSMutableData* sigmavT = [NSMutableData dataWithLength:m*n*sizeof(double)];
    NSMutableData* work = [NSMutableData data];
    
   // double* aPtr = (double*) [a bytes];
   // double* uPtr = (double*)[u bytes];
   // double* vTPtr = (double*)[vT bytes];
   // double* sigmavTPtr = (double*)[sigmavT bytes];
//    aPtr[0]=1;
//    aPtr[1]=0;
//    aPtr[2]=0;
    
//    aPtr[3]=0;
//    aPtr[4]=2;
//    aPtr[5]=0;
 //   NSMutableData* b =[NSMutableData dataWithLength:[a length]];
    //
    NSMutableData* b = [NSMutableData dataWithData:[self _transposeData:a withColumns:nChannel]];
    //double*  bPtr = (double*)[b bytes];
//    NSMutableData* c =[NSMutableData dataWithLength:[b length]];
    if (regularizationParameter!=0) {
        // singular value decomposition of the feedback matrix
        double optimalWork = 0;
        dgesvd_("All",
                "All",
                &m,
                &n,
                (double*) [b bytes],
                &lda,
                (double*) [sigma bytes],
                (double*) [u bytes],
                &ldu,
                (double*) [vT bytes],
                &ldvT,
                &optimalWork,
                &lwork,
                &info
                );
        lwork = (__CLPK_integer)optimalWork;
        [work setLength:lwork*sizeof(double)];
        dgesvd_("All",
                "All",
                &m,
                &n,
                (double*) [b bytes],
                &lda,
                (double*) [sigma bytes],
                (double*) [u bytes],
                &ldu,
                (double*) [vT bytes],
                &ldvT,
                (double*) [work bytes],
                &lwork,
                &info
                );
        
        //switching back from Column-Major to Row-Major
        u = [self _transposeData:u withColumns:nCoil];
        vT = [self _transposeData:vT withColumns:nChannel];
        
        // regularization of sigma
        for (i=0; i<nCoil; i++) {
            sigmaPtr[i] = sigmaPtr[i] / (1 + pow(pow(10,regularizationParameter) * sigmaPtr[i] , 2));
        }
        
        // building the sigma matrix out of the singular values (sigma)
        
        for (i=0; i<nCoil; i++) {
            for (j=0; j<nChannel; j++) {
                if (i==j) {
                    sigmaMatPtr[i*nChannel + j] = sigmaPtr[i];
                } else {
                    sigmaMatPtr[i*nChannel + j] = 0;
                }
                
            }
        }
        //building regularized feedbackmatrix
        cblas_dgemm(
                    CblasRowMajor,
                    CblasNoTrans,
                    CblasNoTrans,
                    nCoil,
                    nChannel,
                    nChannel,
                    1,
                    [sigmaMat bytes],
                    nChannel,
                    [vT bytes],
                    nChannel,
                    0,
                    (double*)[sigmavT bytes],
                    nChannel
                    );
        
        cblas_dgemm(
                    CblasRowMajor,
                    CblasNoTrans,
                    CblasNoTrans,
                    nCoil,
                    nChannel,
                    nCoil,
                    1,
                    [u bytes],
                    nCoil,
                    [sigmavT bytes],
                    nChannel,
                    0,
                    (double*)[newFeedback bytes],
                    nChannel
                    );
        
    }

    [self resetConversionMatrix];
    NumberOfChannels = nChannel;
    NumberOfCoils = nCoil;
    
    //if (regularizationParameter!=0) {
    //    c = [NSMutableData dataWithData:[self _transposeData:b withColumns:nCoil]];
    //    [self _setConversionMatrix:c];
    //} else {
    //    [self _setConversionMatrix:newFeedback];
    //}
    
    [self _setConversionMatrix:newFeedback];
    // Sets the new feedback matrix and checks, if the other arrays are compatible with it. If not, they are reseted.

    //[self _setConversionMatrix:test];
    if ([MagnetometerMap count]!= nChannel) {
        NSLog(@"MagentometerMap and FeedbackMatrix are incompatible! Please select a suitable MagentometerMap.\n");
        [self resetMagnetometerMap];
    }
    if ([OrientationMatrix count]!= nCoil) {
        NSLog(@"OrientationMatrix and FeedbackMatrix are incompatible! Please select a suitable OrientationMatrix.\n");
        [self resetOrientationMatrix];
    }
    if ([FieldTarget length]/sizeof(double)!= nChannel) {
        NSLog(@"FieldTarget and FeedbackMatrix are incompatible! Please select a suitable FieldTarget.\n");
        [self setTargetFieldToZero];
    }
    if ([StartCurrent count]!= nCoil) {
        NSLog(@"StartCurrent and FeedbackMatrix are incompatible! Please select a suitable StartCurrent.\n");
        [self setStartCurrentToZero];
    }    
}

- (void) saveFeedbackInPlistFile:(NSString*)plistFile
{
    int nChannel = [self numberOfChannels];
    int nCoil = [self numberOfCoils];
    NSMutableArray* tempArray = [NSMutableArray arrayWithCapacity:nCoil];
    double* feedbackPtr = (double*) [FeedbackMatData bytes];
    int i, j;
    for(i=0;i<nCoil;i++){
        [tempArray addObject:[NSMutableArray arrayWithCapacity:nChannel]];
        for (j=0; j<nChannel; j++) {
            [[tempArray objectAtIndex:i] addObject:[NSNumber numberWithDouble:feedbackPtr[i*nChannel + j]]];
        }
    }
    [tempArray writeToFile:plistFile atomically:YES];
}

- (void) buildReplaceFeedback
{
    NSArray* oldMagnetometerMap = [NSArray arrayWithArray:[self magnetometerMap]];
    NSArray* oldOrientationMap = [NSArray arrayWithArray:[self orientationMatrix]];
    [self buildFeedback];
    [self _setMagnetometerMatrix:oldMagnetometerMap];
    [self _setOrientationMatrix:oldOrientationMap];
}

- (NSString*) runComment
{
    if (!RunComment) return @"";
    return RunComment;
}

- (NSArray*) magnetometerMap
{
    return MagnetometerMap;
}

- (NSArray*) activeChannelMap
{
    return ActiveChannelMap;
}

- (NSArray*) orientationMatrix
{
    return OrientationMatrix;
}

- (NSData*)  feedbackMatData
{
    return FeedbackMatData;
}

- (NSData*)  sensitivityMatData
{
    return SensitivityMatData;
}

- (NSMutableArray*)  sensorInfo
{
    return SensorInfo;
}

- (NSMutableArray*)  sensorDirectInfo
{
    return SensorInfo;
}

#pragma mark •••ORGroup
- (void) objectCountChanged
{
    // Recalculate the obj map
    if (!objMap) objMap = [[NSMutableDictionary dictionary] retain];
    [objMap removeAllObjects];
    NSEnumerator* e = [self objectEnumerator];
    for (id anObject in e) {
        [objMap setObject:anObject forKey:[NSNumber numberWithInteger:[anObject tag]]];
    }
}

- (int) rackNumber
{
	return (int)[self uniqueIdNumber];
}

- (void) viewChanged:(NSNotification*)aNotification
{
    [self setUpImage];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"nEDM Coil %d",[self rackNumber]];
}

- (NSComparisonResult)sortCompare:(OrcaObject*)anObj
{
    return [self uniqueIdNumber] - [anObj uniqueIdNumber];
}

#pragma mark •••CardHolding Protocol
#define objHeight 71
#define objectsInRow 2
- (int) maxNumberOfObjects	{ return 12; }	//default
- (int) objWidth			{ return 100; }	//default
- (int) groupSeparation		{ return 0; }	//default
- (NSString*) nameForSlot:(int)aSlot	
{ 
    return [NSString stringWithFormat:@"Slot %d",aSlot]; 
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	return NSMakeRange(0,[self maxNumberOfObjects]);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj 
{ 
    return NO;
}

- (int)slotAtPoint:(NSPoint)aPoint 
{
	float y = aPoint.y;
    float x = aPoint.x;
	int objWidth = [self objWidth];
    int columnNumber = (int)x/objWidth;
	int rowNumber = (int)y/objHeight;
	
    if (rowNumber >= [self maxNumberOfObjects]/objectsInRow ||
        columnNumber >= objectsInRow) return -1;
    return rowNumber*objectsInRow + columnNumber;
}

- (NSPoint) pointForSlot:(int)aSlot 
{
    int rowNumber = aSlot/objectsInRow;
    int columnNumber = aSlot % objectsInRow;
    return NSMakePoint(columnNumber*[self objWidth],rowNumber*objHeight);
}

- (void) place:(id)aCard intoSlot:(int)aSlot
{
    [aCard setTag:aSlot];
	[aCard moveTo:[self pointForSlot:aSlot]];
}
- (int) slotForObj:(id)anObj
{
    return (int)[anObj tag];
}
- (int) numberSlotsNeededFor:(id)anObj
{
	return [anObj numberSlotsUsed];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];

    [self setPollingFrequency:[decoder decodeFloatForKey:@"kORnEDMCoilPollingFrequency"]];
    [self setProportionalTerm:[decoder decodeFloatForKey:@"kORnEDMCoilProportionalTerm"]];
    [self setIntegralTerm:[decoder decodeFloatForKey:@"kORnEDMCoilIntegralTerm"]];
    [self setFeedbackThreshold:[decoder decodeFloatForKey:@"kORnEDMCoilFeedbackThreshold"]];
    [self setRegularizationParameter:[decoder decodeFloatForKey:@"kORnEDMCoilRegularizationParameter"]];
    [self setDebugRunning:[decoder decodeBoolForKey:@"kORnEDMCoilDebugRunning"]];
    [self setDynamicMode:[decoder decodeBoolForKey:@"kORnEDMCoilDynamicMode"]];
    [self _setMagnetometerMatrix:[decoder decodeObjectForKey:@"kORnEDMCoilMagnetometerMap"]];
    [self _setActiveChannelMatrix:[decoder decodeObjectForKey:@"kORnEDMCoilActiveChannelMap"]];
    [self _setSensorInfo:[decoder decodeObjectForKey:@"kORnEDMCoilSensorInfo"]];
    [self _setSensorDirectInfo:[decoder decodeObjectForKey:@"kORnEDMCoilSensorDirectInfo"]];
    [self _setOrientationMatrix:[decoder decodeObjectForKey:@"kORnEDMCoilOrientationMatrix"]];
    [self _setConversionMatrix:[decoder decodeObjectForKey:@"kORnEDMCoilFeedbackMatrixData"]];
    [self _setSensitivityMatrix:[decoder decodeObjectForKey:@"kORnEDMCoilSensitivityMatrixData"]
                   withChannels:[decoder decodeIntegerForKey:@"kORnEDMCoilSensChannels"]
                      withCoils:[decoder decodeIntegerForKey:@"kORnEDMCoilSensCoils"]];
    [self _setFieldTarget:[decoder decodeObjectForKey:@"kORnEDMCoilFieldTarget"]];
    [self _setStartCurrent:[decoder decodeObjectForKey:@"kORnEDMCoilStartCurrent"]];
    NumberOfChannels = [decoder decodeIntForKey:@"kORnEDMCoilNumChannels"];
    NumberOfCoils = [decoder decodeIntForKey:@"kORnEDMCoilNumCoils"];
    
    [self _setADCList:[decoder decodeObjectForKey:@"kORnEDMCoilListOfADCs"]];
    [self _setADCList:[decoder decodeObjectForKey:@"kORnEDMCoilListOfADCs"]];    
    [self setVerbose:[decoder decodeIntegerForKey:@"kORnEDMCoilVerbose"]];
    [self setPostDataToDB:[decoder decodeBoolForKey:@"kORnEDMCoilPostDataToDB"]];
    [self setPostToPath:[decoder decodeObjectForKey:@"kORnEDMCoilPostToPath"]];
    [self setPostDataToDBPeriod:[decoder decodeFloatForKey:@"kORnEDMCoilPostToDBPeriod"]];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:pollingFrequency forKey:@"kORnEDMCoilPollingFrequency"];
    [encoder encodeFloat:proportionalTerm forKey:@"kORnEDMCoilProportionalTerm"];
    [encoder encodeFloat:integralTerm forKey:@"kORnEDMCoilIntegralTerm"];
    [encoder encodeFloat:feedbackThreshold forKey:@"kORnEDMCoilFeedbackThreshold"];
    [encoder encodeFloat:regularizationParameter forKey:@"kORnEDMCoilRegularizationParameter"];
    [encoder encodeBool:debugRunning forKey:@"kORnEDMCoilDebugRunning"];
    [encoder encodeBool:dynamicMode forKey:@"kORnEDMCoilDynamicMode"];
    [encoder encodeObject:MagnetometerMap forKey:@"kORnEDMCoilMagnetometerMap"];
    [encoder encodeObject:ActiveChannelMap forKey:@"kORnEDMCoilActiveChannelMap"];
    [encoder encodeObject:OrientationMatrix forKey:@"kORnEDMCoilOrientationMatrix"];
    [encoder encodeObject:FeedbackMatData forKey:@"kORnEDMCoilFeedbackMatrixData"];
    [encoder encodeObject:SensitivityMatData forKey:@"kORnEDMCoilSensitivityMatrixData"];
    [encoder encodeInteger:NumberOfChannels forKey:@"kORnEDMCoilNumChannels"];    
    [encoder encodeInteger:NumberOfCoils forKey:@"kORnEDMCoilNumCoils"];
    [encoder encodeInteger:SenNumChannels forKey:@"kORnEDMCoilSensChannels"];
    [encoder encodeInteger:SenNumCoils forKey:@"kORnEDMCoilSensCoils"];
    [encoder encodeInteger:verbose forKey:@"kORnEDMCoilVerbose"];
    [encoder encodeBool:postDataToDB forKey:@"kORnEDMCoilPostDataToDB"];
    [encoder encodeObject:postToPath forKey:@"kORnEDMCoilPostToPath"];
    [encoder encodeObject:listOfADCs forKey:@"kORnEDMCoilListOfADCs"];
    [encoder encodeObject:FieldTarget forKey:@"kORnEDMCoilFieldTarget"];
    [encoder encodeObject:StartCurrent forKey:@"kORnEDMCoilStartCurrent"];
    [encoder encodeFloat:postToDBPeriod forKey:@"kORnEDMCoilPostToDBPeriod"];
}

#pragma mark •••Holding ADCs
- (NSArray*) validObjects
{
    return [[self document] collectObjectsConformingTo:@protocol(ORAdcProcessing)];
}

#pragma mark •••Held objects
- (int) magnetometerChannels
{
    [self _readADCValues];
    return (int)([currentADCValues length]/sizeof(double));
}

- (int) coilChannels
{
    return (int)[objMap count]*kORTTCPX400DPOutputChannels;
}

- (void) enableOutput:(BOOL)enab atCoil:(int)coil
{
    [[objMap objectForKey:[NSNumber numberWithInt:(coil/2)]]
     setWriteToSetOutput:(int)enab withOutput:(coil%2)];
}

- (void) setVoltage:(double)volt atCoil:(int)coil
{
    [[objMap objectForKey:[NSNumber numberWithInt:(coil/2)]]
     setWriteToSetVoltage:volt withOutput:(coil%2)];
}

- (void) setCurrent:(double)current atCoil:(int)coil
{
    [self _setCurrent:current forSupply:coil];
}

- (double) readBackSetCurrentAtCoil:(int)coil
{
    return [[objMap objectForKey:[NSNumber numberWithInt:(coil/2)]]
            readAndBlockGetCurrentSetWithOutput:coil%2];
}

- (double) getCurrent:(int)coil
{
    return [self _getCurrent:coil];
}

- (double) readBackSetVoltageAtCoil:(int)coil
{
    return [[objMap objectForKey:[NSNumber numberWithInt:(coil/2)]]
            readAndBlockGetVoltageSetWithOutput:coil%2];

}

- (double) fieldAtMagnetometer:(int)magn
{
    [self _readADCValues];
    return [self _fieldAtMagnetometer:magn];
}

- (double) targetFieldAtMagnetometer:(int)magn
{
    if (magn >= [FieldTarget length]/sizeof(double)) return 0.0;
    double* ptr2= (double*)[FieldTarget bytes];
    return ptr2[magn];
    //if (magn >= [FieldTarget count]) return 0.0;
    //return [[FieldTarget objectAtIndex:magn] doubleValue];
    
}

- (double) startCurrentAtCoil:(int)coil
{
    //if (coil >= [StartCurrent count]) return 0.0;
    //double* ptr2= (double*)[StartCurrent bytes];
    //return ptr2[coil];
    if (coil >= [StartCurrent count]) return 0.0;
    return [[StartCurrent objectAtIndex:coil] doubleValue];
}

@end

