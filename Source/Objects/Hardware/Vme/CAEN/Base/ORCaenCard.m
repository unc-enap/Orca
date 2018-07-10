//--------------------------------------------------------------------------------
// CLASS:		ORCaenCard
// Purpose:		Handles core communications between VME and CAEN VME modules.
// Author:		Jan M. Wouters
// History:		2003-06-24 (jmw) Modified to clean up model.
//--------------------------------------------------------------------------------
#import "ORCaenCard.h"

// Constants
const unsigned short kDefaultAddressModifier = 0x39;


@implementation ORCaenCard

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
    mErrorCount 		= 0;
    memset( mEventCounter, 0, sizeof(unsigned long) * 32 );
    
    return self;
}


#pragma mark ***Accessors
//--------------------------------------------------------------------------------
// Method:	errorCount
// Purpose: Return the number of errors.
//--------------------------------------------------------------------------------
- (unsigned long) errorCount { return( mErrorCount ); }

//--------------------------------------------------------------------------------
// Method:	getTotalEventCount
// Purpose: Return total number of errors.
//--------------------------------------------------------------------------------
- (unsigned long) getTotalEventCount { return mTotalEventCounter; }

//--------------------------------------------------------------------------------
// Method:	getEventCount
// Purpose: Return current number of events read in.
//--------------------------------------------------------------------------------
- (unsigned long)  getEventCount: (unsigned short) pIndex
{
    if( pIndex < 32 )
    return mEventCounter[pIndex];
    else
    return 0;
}

#pragma mark ***Commands
//--------------------------------------------------------------------------------
/*!\method  read
* \brief	Read a value from a register. Get the offset from the table.
* \param	pReg			- index of register.
* \param	pValue			- Value read from register
* \return	noErr if no problem.
* \note
*/
//--------------------------------------------------------------------------------
- (OSErr) read: (unsigned short) pReg returnValue: (unsigned short* ) pValue
{
    // Make sure that register is valid
    if ( pReg >= [self getNumberRegisters] ) return( kCaenNoRegErr );
    
    // Make sure that one can read from register
    if( [self accessType: pReg] != kReadOnly
        && [self accessType: pReg] != kReadWrite ) return kCaenIllegalOpErr;
    
    // Perform the read operation.
    [[self adapter] readWordBlock: pValue
                        atAddress: [self baseAddress] + [self getAddressOffset: pReg]
                        numToRead: 1
                       withAddMod: [self addressModifier]
                    usingAddSpace: 0x01];
    
    return( noErr );
}

//--------------------------------------------------------------------------------
/*!\method  write
* \brief	write a value to a register.  Get the offset from the table.
* \param	pReg			- index of register.
* \param	pValue			- Value to write to register
* \return	noErr if no problem.
* \note
*/
//--------------------------------------------------------------------------------
- (OSErr) write: (unsigned short) pReg sendValue: (unsigned short) pValue
{
    // Check that register is a valid register.
    if ( pReg >= [self getNumberRegisters] ) return kCaenNoRegErr;
    
    // Make sure that register can be written to.
    if( [self accessType: pReg] != kWriteOnly
        && [self accessType: pReg] != kReadWrite ) return kCaenIllegalOpErr;
    
    // Do actual write
    NS_DURING
        if ( [self accessSize: pReg] == kD16 ){
            [[self adapter] writeWordBlock: &pValue
                    atAddress: [self baseAddress] + [self getAddressOffset: pReg]
                    numToRead: 1
                   withAddMod: [self addressModifier]
                usingAddSpace: 0x01];
            
        }
    NS_HANDLER
    NS_ENDHANDLER
    
    return( noErr );
}

//--------------------------------------------------------------------------------
/*!\method  readOutputBuffer
* \brief	Read out the output Buffer up to a max number of bytes. Actual bufferSize
*          read will be inserted for the returned value.
* \param	pOutputBuffer	- Pointer to output buffer.
* \param	pBufferSize		- Number of bytes actual returned.
* \return	noErr if no problem.
* \note	1) Caller is assumed to have allocated enough space for the read.
*/
//--------------------------------------------------------------------------------
- (OSErr) readOutputBuffer: (unsigned long *) pOutputBuffer withSize: (unsigned short *) pBufferSize
{
    OSErr theError = noErr;
    
    unsigned long* dp = pOutputBuffer;
    unsigned short totalLongCount = 0;
    unsigned short totalEventCount = 0;
    
    unsigned short 	theStatus1;
    unsigned short 	theStatus2;
    
    bool 			bufferIsNotBusy;
    bool 			dataIsReady;
    bool 			bufferIsFull;
    bool			isHeader;
    bool			isValidDatum;
    bool			endOfBlock;
    
    short			i;
    
    NS_DURING
        
        // Determine size of buffer in longs.  Make sure that we do not overflow the pOutputBuffer array.
        short longsToRead = (*pBufferSize > [self getDataBufferSize]
        ? [self getDataBufferSize] : *pBufferSize )
        /sizeof( unsigned long );
        *pBufferSize = 0;
        
        //first read the status resisters to see if there is anything to read.
        [[self adapter] readWordBlock: &theStatus1
                            atAddress: [self baseAddress] + [self getStatus1RegOffset]
                            numToRead: 1
                           withAddMod: [self addressModifier]
                        usingAddSpace: 0x01];
        
        
        [[self adapter] readWordBlock: &theStatus2
                            atAddress: [self baseAddress] + [self getStatus2RegOffset]
                            numToRead: 1
                           withAddMod: [self addressModifier]
                        usingAddSpace: 0x01];
        
        
        // Get some values from the status register using the decoder.
        bufferIsNotBusy 	= ![mDecoder Busy: theStatus1];
        dataIsReady 		= [mDecoder DataReady: theStatus1];
        bufferIsFull 		= [mDecoder BufferFull: theStatus2];
        
        // Read the buffer.
        if ( ( bufferIsNotBusy && dataIsReady ) || bufferIsFull ) {
            
            for ( i = 0; i < longsToRead; ++i ) {
                
                [[self adapter] readLongBlock: dp
                                    atAddress: [self baseAddress] + [self getBufferOffset]
                                    numToRead: 1
                                   withAddMod: [self addressModifier]
                                usingAddSpace: 0x01];
                
                
                isHeader   = [mDecoder IsHeader: *dp];			//decode for a header
                isValidDatum = [mDecoder ValidDatum: *dp];		//decode for valid data
                endOfBlock = [mDecoder EndOfBlock: *dp];			//decode for endBlock
                
                // Update buffer
                if ( isHeader || isValidDatum || endOfBlock ) {
                    *pBufferSize = (++totalLongCount) * sizeof( unsigned long );
                    if ( isValidDatum ) {
                        ++mTotalEventCounter;
                        unsigned short chan = [mDecoder Channel: *dp];
                        if ( chan < 32 ) ++mEventCounter[chan];
                    }
                    
                    if ( endOfBlock ) {
                        if ( ++totalEventCount >= 32 ) {
                            break;				//can not have more than 32 events in the buffer.
                        }
                    }
                }
                else if ( [mDecoder NotValidDatum: *dp] )break;		//should never get this....
                else break;											    //should really never get here...
                
                ++dp;
            }
        }
    NS_HANDLER
        mErrorCount++;
    NS_ENDHANDLER
    
    return(  theError );
}


//--------------------------------------------------------------------------------
// Method:	readThreshold
// Purpose: Read a Threshold value.
//--------------------------------------------------------------------------------
- (OSErr) readThreshold: (unsigned short) pChan returnValue: (unsigned short *) pthres_value
{
    
    [[self adapter] readWordBlock:pthres_value
                        atAddress:[self baseAddress]+[self getThresholdOffset] + ( pChan * kD16 )
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return( noErr );
}

//--------------------------------------------------------------------------------
// Method:	writeThreshold
// Purpose: Write a value to a Threshold register.
//--------------------------------------------------------------------------------
- (OSErr) writeThreshold: (unsigned short) pChan sendValue: (unsigned short) pthres_Value
{
    [[self adapter] writeWordBlock: &pthres_Value
                         atAddress: [self baseAddress] + [self getThresholdOffset]
        + ( pChan * kD16 )
                         numToRead: 1
                        withAddMod: [self addressModifier]
                     usingAddSpace: 0x01];
    return( noErr );
}

//--------------------------------------------------------------------------------
// Function:	Various
// Description: Methods that don't do anything in this class and must be
//				over-ridden in derived class.
//--------------------------------------------------------------------------------
- (short) 			accessSize: (short) i 			{ return 0; }
- (short) 			accessType: (short) i 			{ return 0; }
- (unsigned long) 	getAddressOffset: (short) i 	{ return 0; }
- (unsigned long) 	getBufferOffset 				{ return 0; }
- (unsigned short) 	getDataBufferSize 				{ return 0; }
- (short)  			getNumberRegisters 				{ return 0; }
- (unsigned short) 	getStatus1RegOffset 			{ return 0; }
- (unsigned short) 	getStatus2RegOffset 			{ return 0; }
- (unsigned long) 	getThresholdOffset 				{ return 0; }


@end
