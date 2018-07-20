//--------------------------------------------------------------------------------
// CLASS:		ORCaenCard
// Purpose:		Handles core communications between VME and CAEN VME modules.
// Author:		Jan M. Wouters
// History:		2003-06-24 (jmw) Modified to clean up model.
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

#import "ORCaenCardModel.h"
#import "ORCaenDataDecoder.h"
#import "SBC_Config.h"
#import "SBC_Cmds.h"
#import "VME_HW_Definitions.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORDataTypeAssigner.h"

#pragma mark ***Notification Strings
NSString* 	caenSelectedRegIndexChanged		= @"CAEN Selected Reg Index Changed";
NSString* 	caenSelectedChannelChanged		= @"CAEN Selected Channel Changed";
NSString* 	caenWriteValueChanged			= @"CAEN Write Value Changed";
NSString*	caenChnlThresholdChanged		= @"CAEN Channel Threshold Changed";

#pragma mark ***Indentification Strings
NSString* 	caenChnl				= @"CAEN Chnl";


@implementation ORCaenCardModel


#pragma mark ¥¥¥Inialization
//--------------------------------------------------------------------------------
/*!\method  initWithDocument
 * \brief	Called first time class is initialized.  Used to set basic
 *			default values first time object is created.
 * \param	aDocument			- The initialization document.
 * \note
 */
//--------------------------------------------------------------------------------
- (id) init //designated initializer
{
    self = [super init];
    
    // Initialization internal variables.
    errorCount 		= 0;    
    return self;
}

- (void) dealloc
{
    [dataDecoder release];
    [super dealloc];
}

#pragma mark ***Accessors

- (NSString*) shortName
{
	NSString* n = [super shortName];
	if([n hasPrefix:@"Caen"]) n = [n substringFromIndex:4];
	return n;
}

//--------------------------------------------------------------------------------
// Method:	errorCount
// Purpose:Return the number of errors.
//--------------------------------------------------------------------------------
- (uint32_t) errorCount { return(errorCount); }

//--------------------------------------------------------------------------------
// Method:	getTotalEventCount
// Purpose:Return total number of errors.
//--------------------------------------------------------------------------------
- (uint32_t) getTotalEventCount { return totalEventCounter; }

//--------------------------------------------------------------------------------
// Method:	getEventCount
// Purpose:Return current number of events read in.
//--------------------------------------------------------------------------------
- (uint32_t)  getEventCount:(unsigned short) pIndex
{
    if(pIndex < 32)return eventCounter[pIndex];
    else return 0;
}

//--------------------------------------------------------------------------------
/*!\method  selectedRegIndex
 * \brief	Returns which register was selected.
 * \note
 */
//--------------------------------------------------------------------------------
- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}

//--------------------------------------------------------------------------------
/*!\method  setSelectedRegIndex
 * \brief	Sets the register commands will work on.
 * \param	anIndex		- The index of the register.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self]
	 setSelectedRegIndex:[self selectedRegIndex]];
    
    // Set the new value in the model.
    selectedRegIndex = anIndex;
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:caenSelectedRegIndexChanged
	 object:self];
}

//--------------------------------------------------------------------------------
/*!\method  selectedChannel
 * \brief	Returns the currently selected channel.
 * \return	The selected channel.
 * \note
 */
//--------------------------------------------------------------------------------
- (unsigned short) selectedChannel
{
    return selectedChannel;
}

//--------------------------------------------------------------------------------
/*!\method  setSelectedChannel
 * \brief	Sets the currently selected channel.
 * \param	anIndex			- The index for the channel.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) setSelectedChannel:(unsigned short) anIndex
{
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self]
	 setSelectedChannel:[self selectedChannel]];
    
    // Set the new value in the model.
    selectedChannel = anIndex;
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:caenSelectedChannelChanged
	 object:self];
}

//--------------------------------------------------------------------------------
/*!\method  writeValue
 * \brief	Return the value written out to the register.
 * \return	The value written to the register
 * \note
 */
//--------------------------------------------------------------------------------
- (uint32_t) writeValue
{
    return writeValue;
}

//--------------------------------------------------------------------------------
/*!\method  setWriteValue
 * \brief	Set the value written out to the register
 * \param	aValue		- The value to write to the register.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) setWriteValue:(uint32_t) aValue
{
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    
    // Set the new value in the model.
    writeValue = aValue;
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:caenWriteValueChanged
	 object:self];
}

//--------------------------------------------------------------------------------
/*!\method  threshold
 * \brief	Returns the internal model value for the threshold of specific channel.
 * \param	aChnl			- Channel to get value for.
 * \return	The threshold value.
 * \note
 */
//--------------------------------------------------------------------------------
- (unsigned short) threshold:(unsigned short) aChnl
{
    return(thresholds[aChnl]);
}

//--------------------------------------------------------------------------------
/*!\method  setThreshold
 * \brief	Sets the internal model value for the threshold of specific channel.
 * \param	aChnl			- Channel to get value for.
 * \param	aValue			- The value to use for the threshold.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) setThreshold:(unsigned short) aChnl threshold:(unsigned short) aValue
{
    
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChnl threshold:[self threshold:aChnl]];
    
    // Set the new value in the model.
    thresholds[aChnl] = aValue;
    
    // Create a dictionary object that stores a pointer to this object and the channel that was changed.
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:caenChnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:caenChnlThresholdChanged
	 object:self
	 userInfo:userInfo];
}

- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

#pragma mark ***CAEN Commands
//--------------------------------------------------------------------------------
/*!\method  read
 * \brief	Reads data from CAEN vme device register.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) read
{
    
    unsigned short 	theValue   = 0;
    short		start;
    short		end;
    short		i;
    // Get register and channel from dialog box.
    short theChannelIndex	= [self selectedChannel];
    short theRegIndex 		= [self selectedRegIndex];
    
    @try {
        
        if (theRegIndex == [self getThresholdIndex]){
            start = theChannelIndex;
            end = theChannelIndex;
            if(theChannelIndex >= [self numberOfChannels]) {
                start = 0;
                end = [self numberOfChannels] - 1;
            }
            
            // Loop through the thresholds and read them.
            for(i = start; i <= end; i++){
                [self readThreshold:i];
                NSLog(@"Threshold %2d = 0x%04lx\n", i, [self threshold:i]);
            }
        }
        
        // If user selected the output buffer then read it.
        else if (theRegIndex == [self getOutputBufferIndex]){
			
            ORDataPacket* tempDataPacket = [[ORDataPacket alloc]init];
			dataDecoder = [[ORCaenDataDecoder alloc] init];
			//make buffer for data with extra room for our 2 int32_t word header.
			dataBuffer = (uint32_t*)malloc([self getDataBufferSize]+2*sizeof(uint32_t));
			controller = [self adapter]; //cache for speed
			
            [self takeData:tempDataPacket userInfo:nil];
			if([[tempDataPacket dataArray]count]){
				NSData* theData = [[tempDataPacket dataArray] objectAtIndex:0];
				uint32_t* someData = (uint32_t*)[theData bytes];
                ORCaenDataDecoder *aDecoder = [[ORCaenDataDecoder alloc] init];
                [aDecoder printData:[self className] data:someData];
                [aDecoder release];
            }
        }
        
        // Handle all other registers.  Just read them.
        else {
            [self read:theRegIndex returnValue:&theValue];
            NSLog(@"CAEN reg [%@]:0x%04lx\n", [self getRegisterName:theRegIndex], theValue);
        }
        
	}
	@catch(NSException* localException) {
		NSLog(@"Can't Read [%@] on the %@.\n",
			  [self getRegisterName:theRegIndex], [self identifier]);
		[localException raise];
	}
	@finally {
		[dataDecoder release];
		dataDecoder = nil;
		free (dataBuffer);
		dataBuffer = 0;
		controller = 0;
	}
}


//--------------------------------------------------------------------------------
/*!\method  write
 * \brief	Writes data out to a CAEN VME device register.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) write
{
    short	start;
    short	end;
    short	i;
    
    
    // Get the value - Already validated by stepper.
    int32_t theValue =  [self writeValue];
    // Get register and channel from dialog box.
    short theChannelIndex	= [self selectedChannel];
    short theRegIndex 		= [self selectedRegIndex];
    
    @try {
        
        NSLog(@"Register is:%d\n", theRegIndex);
        NSLog(@"Index is   :%d\n", theChannelIndex);
        NSLog(@"Value is   :0x%04x\n", theValue);
        
        if(theRegIndex == [self getThresholdIndex]) {
            start = theChannelIndex;
            end 	= theChannelIndex;
            if(theChannelIndex >= [self numberOfChannels]){
                start = 0;
                end = [self numberOfChannels] - 1;
            }
            for (i = start; i <= end; i++){
                [self setThreshold:i threshold:theValue];
                [self writeThreshold:i];
            }
        }
        
        // Handle all other registers
        else {
            [self write:theRegIndex sendValue:(short) theValue];
        }
        
	}
	@catch(NSException* localException) {
		NSLog(@"Can't write 0x%04lx to [%@] on the %@.\n",
			  theValue, [self getRegisterName:theRegIndex],[self identifier]);
		[localException raise];
	}
}


//--------------------------------------------------------------------------------
/*!\method  read
 * \brief	Performs low level read from CAEN VME register
 * \param	pReg			- index of register.
 * \param	pValue			- Value read from register
 * \return	noErr if no problem.
 * \note	Gets offset to register from unit register map.
 */
//--------------------------------------------------------------------------------
- (void) read:(unsigned short) pReg returnValue:(void*) pValue
{
    // Make sure that register is valid
    if (pReg >= [self getNumberRegisters]) {
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    // Make sure that one can read from register
    if([self getAccessType:pReg] != kReadOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (read not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    // Perform the read operation.
	if ([self getAccessSize:pReg] == kD16){
		unsigned short aValue;
		[[self adapter] readWordBlock:&aValue
							atAddress:[self baseAddress] + [self getAddressOffset:pReg]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		*((unsigned short*)pValue) = aValue;
	}
	else {
		uint32_t aValue;
		[[self adapter] readLongBlock:&aValue
							atAddress:[self baseAddress] + [self getAddressOffset:pReg]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		*((uint32_t*)pValue) = aValue;
	}
}

//--------------------------------------------------------------------------------
/*!\method  write
 * \brief	Performs low level write to CAEN VME device register.
 * \param	pReg			- index of register.
 * \param	pValue			- Value to write to register
 * \return	noErr if no problem.
 * \note	Gets offset to register from unit register map.
 */
//--------------------------------------------------------------------------------
- (void) write:(unsigned short) pReg sendValue:(uint32_t) pValue
{
    // Check that register is a valid register.
    if (pReg >= [self getNumberRegisters]){
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    // Make sure that register can be written to.
    if([self getAccessType:pReg] != kWriteOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (write not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    // Do actual write
    @try {
        if ([self getAccessSize:pReg] == kD16){
			unsigned short aValue = (unsigned short)pValue;
            [[self adapter] writeWordBlock:&aValue
                                 atAddress:[self baseAddress] + [self getAddressOffset:pReg]
                                numToWrite:1
                                withAddMod:[self addressModifier]
                             usingAddSpace:0x01];
            
        }
		else {
            [[self adapter] writeLongBlock:&pValue
                                 atAddress:[self baseAddress] + [self getAddressOffset:pReg]
                                numToWrite:1
                                withAddMod:[self addressModifier]
                             usingAddSpace:0x01];
			
		}
	}
	@catch(NSException* localException) {
	}
}


//--------------------------------------------------------------------------------
/*!\method  readThresholds
 * \brief	Calls low level routine to read all the thresholds.
 * \return	noErr if no problem.
 */
//--------------------------------------------------------------------------------
- (void) readThresholds
{
    short			i;
    for (i = 0; i < [self numberOfChannels]; i++){
        [self readThreshold:i];
    }
}

//--------------------------------------------------------------------------------
/*!\method  writeThresholds
 * \brief	Calls low level routine to write all the thresholds.
 * \return	noErr if no problem.
 */
//--------------------------------------------------------------------------------
- (void) writeThresholds
{
    short	i;
    
    for (i = 0; i < [self numberOfChannels]; i++){
        [self writeThreshold:i];
    }
}

//--------------------------------------------------------------------------------
/*!\method  caenInitializeForDataTaking
 * \brief	This routine setups up the caen device so that it can acquire data using
 *			the computer.
 * \error	Throws error if any command fails.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) caenInitializeForDataTaking
{
}

- (NSString*) decodeManufacturerCode:(short)aCode
{
	if(aCode == 0x02)return @"CAEN";
	else return @"Unknown Manufacturer";
}

- (NSString*) decodeModuleCode:(short)aCode
{
	if(aCode == 0x012)return @"V265";
	else return @"Unknown module";
}


#pragma mark ***Support Hardware Functions
//--------------------------------------------------------------------------------
// Method:	readThreshold
// Purpose:Read a Threshold value.
//--------------------------------------------------------------------------------
- (void) readThreshold:(unsigned short) pChan
{
    
    unsigned short		value;
    
    // Read the threshold
    [[self adapter] readWordBlock:&value
                        atAddress:[self baseAddress] + [self getThresholdOffset] + (pChan * kD16)
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    // Store new value
   // [self setThreshold:pChan threshold:value];
    
}

//--------------------------------------------------------------------------------
// Method:	writeThreshold
// Purpose:Write a value to a Threshold register.
//--------------------------------------------------------------------------------
- (void) writeThreshold:(unsigned short) pChan
{
    unsigned short 	threshold = [self threshold:pChan];
    
    [[self adapter] writeWordBlock:&threshold
                         atAddress:[self baseAddress] + [self getThresholdOffset] + (pChan * kD16)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

#pragma mark ¥¥¥Archival
// Encode decode strings.
static NSString*	CAENSelectedRegIndex	= @"CAENSelectedRegIndex";
static NSString*	CAENSelectedChannelIndex= @"CAENSelectedChannelIndex";
static NSString*	CAENWriteValue			= @"CAENWriteValue";
static NSString*	CAENThresholdChnl       = @"CAENThresholdChnl%d";


//--------------------------------------------------------------------------------
/*!\method  initWithCoder
 * \brief	Initialize object using archived settings.
 * \param	aDecoder			- Object used for getting archived internal parameters.
 * \note
 */
//--------------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*) aDecoder
{
    short i;
    
    self = [super initWithCoder:aDecoder];
    
    [[self undoManager] disableUndoRegistration];
    
    // Get the last values from the first tab of the dialog box.
    [self setSelectedRegIndex:[aDecoder decodeIntegerForKey:CAENSelectedRegIndex]];
    [self setSelectedChannel:[aDecoder decodeIntegerForKey:CAENSelectedChannelIndex]];
    [self setWriteValue:[aDecoder decodeIntForKey:CAENWriteValue]];
    
    // Get the thresholds
    for (i = 0; i < [self numberOfChannels]; i++){
        [self setThreshold:i
                 threshold:[aDecoder decodeIntegerForKey:
							[NSString stringWithFormat:CAENThresholdChnl, i]]];
    }
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

//--------------------------------------------------------------------------------
/*!\method  encodeWithCoder
 * \brief	Save the internal settings to the archive.
 * \param	anEncoder			- Object used for encoding.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    short i;
    
    [super encodeWithCoder:anEncoder];
    
    // Save the information from first TAB.
    [anEncoder encodeInteger:[self selectedRegIndex] forKey:CAENSelectedRegIndex];
    [anEncoder encodeInteger:[self selectedChannel] forKey:CAENSelectedChannelIndex];
    [anEncoder encodeInt:[self writeValue] forKey:CAENWriteValue];
    
    // Save the thresholds
    for (i = 0; i < [self numberOfChannels]; i++){
        [anEncoder encodeInteger:[self threshold:i]
                      forKey:[NSString stringWithFormat:CAENThresholdChnl, i]];
    }
    
}


//--------------------------------------------------------------------------------
// Function:	Various
// Description:Methods that don't do anything in this class and must be
//				over-ridden in derived class.
//--------------------------------------------------------------------------------
#pragma mark ¥¥¥Register - General routines
- (short)		getNumberRegisters			{ return 0; }
- (uint32_t) 	getBufferOffset				{ return 0; }
- (unsigned short) 	getDataBufferSize			{ return 0; }
- (uint32_t) 	getThresholdOffset			{ return 0; }

- (short)		getStatusRegisterIndex:(short) aRegister   { return 0; }
- (short)		getThresholdIndex			    { return 0; }
- (short)		getOutputBufferIndex			    { return 0; }

#pragma mark ***Register - Register specific routines
- (NSString*)		getRegisterName:(short) anIndex	{ return 0; }
- (uint32_t) 	getAddressOffset:(short) anIndex 	{ return 0; }
- (short)		getAccessSize:(short) anIndex 		{ return 0; }
- (short)		getAccessType:(short) anIndex 		{ return 0; }
- (BOOL)		dataReset:(short) anIndex		{ return false; }
- (BOOL)		swReset:(short) anIndex		{ return false; }
- (BOOL)		hwReset:(short) anIndex		{ return false; }

#pragma mark ***Misc routines
- (uint32_t*)	getDataBuffer				{ return 0; }

#pragma mark ¥¥¥DataTaker

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    
    NSString* decoderName = [[NSStringFromClass([self class]) componentsSeparatedByString:@"Model"] componentsJoinedByString:@"DecoderFor"];
    decoderName = [decoderName stringByAppendingString:@"CAEN"];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 decoderName,                 @"decoder",
								 [NSNumber numberWithLong:dataId],           @"dataId",
								 [NSNumber numberWithBool:YES],              @"variable",
								 [NSNumber numberWithLong:-1],               @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"CAEN"];
    return dataDictionary;
}


- (void) 	runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:NSStringFromClass([self class])]; 
    
    dataDecoder = [[ORCaenDataDecoder alloc] init];
    //make buffer for data with extra room for our 2 int32_t word header.
    dataBuffer = (uint32_t*)malloc([self getDataBufferSize]+2*sizeof(uint32_t));
    controller = [self adapter]; //cache for speed
	
	[self flushBuffer];
    
}
//--------------------------------------------------------------------------------
/*!\method  takeData
 * \brief	Read out the output Buffer up to a max number of bytes. Actual bufferSize
 *          read will be inserted for the returned value.
 * \param	aDataPacket	- Pointer to output data packet.
 * \param	userInfo	- arbitrary data.
 */
//--------------------------------------------------------------------------------
//-------------------------------------------------------------------------------
//data format
//0000 0000 0000 0000 0000 0000 0000 0000
//^^^^ ^^^^ ^^^^ ^^---------------------- device type
//		           ^^ ^^^^ ^^^^ ^^^^ ^^^^ length of record including this header
//0000 0000 0000 0000 0000 0000 0000 0000
//^^^^ ^^^------------------------------- spare
//        ^ ^^^-------------------------- crate
//             ^ ^^^^-------------------- card
// n bytes of raw data follow.
//-------------------------------------------------------------------------------
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
{
    
    unsigned short 	theStatus1;
    unsigned short 	theStatus2;
    
    @try {
        
        //first read the status resisters to see if there is anything to read.
        [self read:[self getStatusRegisterIndex:1] returnValue:&theStatus1];
        [self read:[self getStatusRegisterIndex:2] returnValue:&theStatus2];
        
        // Get some values from the status register using the decoder.
        BOOL bufferIsNotBusy 	= ![dataDecoder isBusy:theStatus1];
        BOOL dataIsReady 		= [dataDecoder isDataReady:theStatus1];
        BOOL bufferIsFull 		= [dataDecoder isBufferFull:theStatus2];
        BOOL unrecoverableError = NO;
        uint32_t bufferAddress = [self baseAddress] + [self getBufferOffset];
        unsigned short mod = [self addressModifier];
        
        // Read the buffer.
        if ((bufferIsNotBusy && dataIsReady) || bufferIsFull) {
            
            unsigned short totalEventCount = 0;     //reset the total number of events
            short dataIndex = 2;                    //leave space for our header
            
            while(1){
                uint32_t dataValue;
                //read the first word, could be a header, or the buffer could be empty now
                [controller readLongBlock:&dataValue
                                atAddress:bufferAddress
                                numToRead:1
                               withAddMod:mod
                            usingAddSpace:0x01];
                
                if([dataDecoder isNotValidDatum:dataValue]) {
                    break; //buffer is empty
                }
                
                //insert the header (1st word of this record)
                if([dataDecoder isHeader:dataValue]){
                    dataBuffer[dataIndex++] = dataValue;
                }
                else {
                    //error--flush buffer
                    [self flushBuffer];
                    break;
                }
                //read out the channel data
                int n = [dataDecoder numMemorizedChannels:dataValue];
                int i;
                for(i=0;i<n;i++){
                    [controller readLongBlock:&dataValue
                                    atAddress:bufferAddress
                                    numToRead:1
                                   withAddMod:mod
                                usingAddSpace:0x01];
                    
                    if([dataDecoder isValidDatum:dataValue]){
                        dataBuffer[dataIndex++] = dataValue;
                    }
                    else {
                        //oh-oh. big problems flush the buffer.
                        unrecoverableError = YES;
                        break;
                    }
                }
                
                if(unrecoverableError){
                    [self flushBuffer];
                    break;
                }
                
                //get the end of block
                [controller readLongBlock:&dataValue
                                atAddress:bufferAddress
                                numToRead:1
                               withAddMod:mod
                            usingAddSpace:0x01];
                
                if([dataDecoder isEndOfBlock:dataValue]){
                    totalEventCount++;
                    dataBuffer[dataIndex++] = dataValue;
					//we did read some data, so fill in the header
					dataBuffer[0] = dataId |  (dataIndex & 0x3ffff);
					dataBuffer[1] = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
					[aDataPacket addLongsToFrameBuffer:dataBuffer length:dataIndex];
					dataIndex = 2;
					break;
                }
                else {
                    //error...the end of block not where we expected it
                    [self flushBuffer];
                    break;
                }
            }
        }
	}
	@catch(NSException* localException) {
		errorCount++;
	}
}

- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
    [dataDecoder release];
    dataDecoder = nil;
    free (dataBuffer);
    dataBuffer = 0;
    controller = 0;
}

- (void) reset
{
    //required by the datataking protocal.
}

- (void) flushBuffer
{
    short n = [self getDataBufferSize]/sizeof(int32_t);
    int i;
    uint32_t dataValue;
    for(i=0;i<n;i++){
        [[self adapter] readLongBlock:&dataValue
                            atAddress:[self baseAddress] + [self getBufferOffset]
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        if([dataDecoder isNotValidDatum:dataValue]) break;
    }
}

#pragma mark ¥¥¥HW Wizard

- (int) numberOfChannels
{
    return 32;
}

-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0.00" upperLimit:1200 lowerLimit:0 stepSize:.01 units:@""];
    [p setSetMethod:@selector(setThreshold:threshold:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
	[p setInitMethodSelector:@selector(writeThresholds)];
    [a addObject:p];
    
	p = [[[ORHWWizParam alloc] init] autorelease];
	[p setUseValue:NO];
	[p setName:@"Init"];
	[p setSetMethodSelector:@selector(writeThresholds)];
	[a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:NSStringFromClass([self class])]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:NSStringFromClass([self class])]];
    return a;
    
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Threshold"])return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else return nil;
}

- (void) logThresholds
{
    short	i;
    NSLog(@"%@ Thresholds\n",[self identifier]);
    for (i = 0; i < [self numberOfChannels]; i++){
        NSLog(@"chan:%d value:0x%04x\n",i,[self threshold:i]);
    }
    
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    int i;
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self numberOfChannels]];
    for(i=0;i<[self numberOfChannels];i++){
        [array addObject:[NSNumber numberWithShort:thresholds[i]]];
    }
    [objDictionary setObject:array forKey:@"thresholds"];
    
    return objDictionary;
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kCaen; //should be unique
	configStruct->card_info[index].hw_mask[0]	= (int32_t)dataId; //better be unique
	configStruct->card_info[index].slot			= [self slot];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= [self addressModifier];
	configStruct->card_info[index].base_add		= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0] = [self getAddressOffset:[self getStatusRegisterIndex:1]];
	configStruct->card_info[index].deviceSpecificData[1] = [self getAddressOffset:[self getStatusRegisterIndex:2]];
	configStruct->card_info[index].deviceSpecificData[2] = [self getDataBufferSize]/sizeof(uint32_t);
	configStruct->card_info[index].deviceSpecificData[3] = ([self baseAddress] + [self getBufferOffset]);
	configStruct->card_info[index].deviceSpecificData[4] = [self getAccessType:[self getStatusRegisterIndex:1]];
	configStruct->card_info[index].deviceSpecificData[5] = [self getAccessType:[self getStatusRegisterIndex:2]];
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	return index+1;
}


@end
