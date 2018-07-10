//--------------------------------------------------------------------------------
// Class:		ORLC950Data
// brief:		Oscilloscope data.
// Author:		Jan M. Wouters
// History:		2003-04-29 (jmw) - Original
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
// Imports
#import "ORLC950Data.h"
#import "OROscBaseModel.h"
#import "ORDataTypeAssigner.h"

@implementation ORLC950Data
#pragma mark ***initialization
//--------------------------------------------------------------------------------
/*!\method  initWithWaveformMode
 * \brief	Called to initialization the class.  Creates char array used for data.
 * \param	aModel			- The model that will acquire the data.
 * \return	The created object.
 * \note	1) Create header for data which consists of device type, primary address
 *				and channel number.
 * \note	2) Create header for time which consists of device type, and channel,
 *				number, which will be added later.  Cannot add it here since
 *				time is only stored in ORTek754DData object for channel 0.
 */
//--------------------------------------------------------------------------------
- (id) initWithWaveformModel: (OROscBaseModel*) aModel channel: (short) aChannel
{

    if ( self = [ super init ] )
    {
        mMaxSizeWaveform = [ aModel waveformLength ];
        mAddress = [ aModel primaryAddress ];
        mChannel = aChannel;
        mData = nil;
        
        mHeaderBaseInfo[0] = [ aModel dataId ];
        mHeaderBaseInfo[1] = ( [ aModel primaryAddress ] & 0xF ) << 23 | ( mChannel & 0xF ) << 19;
        
        mHeaderBaseGtidInfo[0] = [ aModel gtidDataId ];		// Gtid
        
        
        mHeaderBaseTimeInfo = [ aModel clockDataId ];

    }
    
                        
                              
    return self;
}

//--------------------------------------------------------------------------------
/*!\method  dealloc
 * \brief	Frees up waveform storage
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) dealloc
{
    [ mTime release ];
    [ mData release ];
    [ super dealloc ];
}

#pragma mark ***Accessors
//--------------------------------------------------------------------------------
/*!\method  actualWaveformSize
 * \brief	Get the actual size of the waveform.
 * \return	Return the actual size of the waveform read in.
 * \note	
 */
//--------------------------------------------------------------------------------
- (long) actualWaveformSize
{
    return( mActualSizeWaveform );
}

//--------------------------------------------------------------------------------
/*!\method  setActualWaveformSize
 * \brief	Set the actual size of the waveform read in.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) setActualWaveformSize: (unsigned long) aWaveformSize
{
    mActualSizeWaveform = aWaveformSize;
}

//--------------------------------------------------------------------------------
/*!\method  maxWaveformSize
 * \brief	Return the maximum size of the waveform array.
 * \return	The allocated size of the waveform array.
 * \note	
 */
//--------------------------------------------------------------------------------
- (long) maxWaveformSize
{
    return( mMaxSizeWaveform );
}


//--------------------------------------------------------------------------------
/*!\method  rawData
 * \brief	Return pointer to raw data array so that it can be filled.
 * \return	Pointer to the raw data array.
 * \note	
 */
//--------------------------------------------------------------------------------
- (NSMutableData*) rawData
{
    return( mData );
}

//--------------------------------------------------------------------------------
/*!\method  timeData
 * \brief	Return pointer to time so that it can be filled.
 * \return	Pointer to the time data.
 * \note	
 */
//--------------------------------------------------------------------------------
- (NSMutableData*) timeData
{
    return( mTime );
}

//--------------------------------------------------------------------------------
/*!\method  rawHeader
 * \brief	Return pointer to raw data header so that it can be filled.
 * \return	Pointer to the raw data array.
 * \note	
 */
//--------------------------------------------------------------------------------
- (char*) rawHeader
{
    return( (char*)(&mHeader) );
}

//--------------------------------------------------------------------------------
/*!\method 	setGtidStorage
 * \brief	Creates data storage for GTID and inserts gtid with header into this
 *			storage.
 */
//--------------------------------------------------------------------------------
- (void) setGtid: (unsigned long) aGtid
{
    // Create the new data storage area.
    unsigned long len;
    if(IsShortForm(mHeaderBaseGtidInfo[0])){
        len = 1;
        // Place header in first word of data storage along with gtid
        mHeaderBaseGtidInfo[0] &= ~0x0003ffff; //zero the old gtid
        mHeaderBaseGtidInfo[0] |= aGtid & 0x0003ffff;
    }
    else {
        len = 2;
        mHeaderBaseGtidInfo[0] |= len;
        mHeaderBaseGtidInfo[1] = aGtid & 0x0003ffff;
    }
    // Release the last storage area used for the last event.
    [ mGtid release ];
    mGtid = [[ NSMutableData allocWithZone: NULL ] initWithBytes:mHeaderBaseGtidInfo length:len*sizeof(long) ];
}

//--------------------------------------------------------------------------------
/*!\method 	createDataStorage
 * \brief	Creates the waveform storage and returns it to the user.
 * \return	Pointer to data memory location just past header word.
 * \note	The four extra bytes are for the header.  This routine returns
 *			a pointer to the 2nd word to preserve the space reserved for the
 *			header word.
 */
//--------------------------------------------------------------------------------
- (char*) createDataStorage
{
    char*		dataLoc;
    
// Release the last storage area used for the last event.
    [ mData release ];
    mData = nil;

// Create the new data storage area.
    mData = [[ NSMutableData allocWithZone: NULL ] initWithCapacity: ( mMaxSizeWaveform + 4 ) ];
    [ mData setLength: (mMaxSizeWaveform + 4) ]; // Since data is added outside of this class
                                                 //  have to set data length here.
    dataLoc = [ mData mutableBytes ] + 4;
    
    return( dataLoc ); 
}

//--------------------------------------------------------------------------------
/*!\method 	createTimeStorage
 * \brief	Creates the time storage and returns it to the user.
 * \return	Pointer to time memory location.
 * \note	This routine allocates enough space for a long long.  The
 *			data is acquired as a string which is converted prior to being
 *			stored as standard UNIX time.
 * \note	Using a 10 MHz clock the time will never exceed
 *			4.0 x 10^16 during the life of the experiment, which can be contained
 *			in 56 bits.  The upper most 8 bits are for the device type and channel.
 */
//--------------------------------------------------------------------------------
- (char*) createTimeStorage
{
    char*		timeLoc;
    
// Release the last storage area used for the last event.
    [ mTime release ];
    mTime = nil;

// Create the new data storage area.
    mTime = [[ NSMutableData allocWithZone: NULL ] initWithCapacity: 3*sizeof(long) ];
                                                // Since data is added outside of this class
                                                 //  have to set data length here.
    [ mTime setLength: 3*sizeof(long) ];
    timeLoc = [ mTime mutableBytes ];
    
    return( timeLoc ); 
}

//--------------------------------------------------------------------------------
/*!\method  setDataPacketData
 * \brief	Set the actual size of the waveform read in.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) setDataPacketData: (ORDataPacket*) aDataPacket timeData: (NSData*) aTimeData
                                                     includeGTID: (BOOL) aFlag
{
    NSArray*		arrayWithObjects;
    
    // add length to first word of header
    mHeaderBaseInfo[0] |= [mData length]/sizeof(long) & 0x0003FFFF;
    if(mData){
        memcpy( [ mData mutableBytes ], &mHeaderBaseInfo, 8 );
    
// Place data in data packet. Use the data cache since we run in a separate thread.
// Only first channel includes GTID and time.  Subsequent channels only include the data.
        if ( aFlag )
            arrayWithObjects = [ NSArray arrayWithObjects: mGtid, aTimeData, mData, nil ];
        else
            arrayWithObjects = [ NSArray arrayWithObjects: mData, nil ];
        
        [ aDataPacket addArrayToCache: arrayWithObjects ];
    }
}

//--------------------------------------------------------------------------------
/*!\method  timePacketData
 * \brief	returns the time data.
 */
//--------------------------------------------------------------------------------
- (NSData*) timePacketData: (ORDataPacket*) aDataPacket channel: (unsigned short) aChannel
{
    unsigned long 	headerInfo[3];
    unsigned long*	firstWord;
    unsigned long len;
// Get the time information.
    firstWord = [ mTime mutableBytes ];

    // Place header in first word of data storage along with data.
	len = 3;
	headerInfo[0] = mHeaderBaseTimeInfo | len;
	headerInfo[1] =  ( ( aChannel & 0x7 ) << 24 ) | *firstWord;
	headerInfo[2] = *(firstWord+1);
// Copy back to mutable array.
    memcpy( [ mTime mutableBytes ], headerInfo, len*sizeof(long) );
    
	return mTime;
}


//--------------------------------------------------------------------------------
/*!\method 	setAcquisition
 * \brief	Sets internal flag to true indicating that raw data was successfully read.
 * \note	
 */
//--------------------------------------------------------------------------------
//- (void) setAcquisition
//{
//    mAcquire = true;
//}

//--------------------------------------------------------------------------------
/*!\method  convertHeader
 * \brief	Convert header information to useable form.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) convertHeader
{
	
// Only process if we have header.
    if ( mData != nil )
    {
		
// Get data from raw header and place into short header.
		mHeaderShort.nrPts = mHeader.mWaveArrayCount;
		mHeaderShort.yOff = mHeader.mVerticalOffset;
		mHeaderShort.yMult = mHeader.mVerticalGain;
        mHeaderShort.xIncr = mHeader.mHorizInterval;
        mHeaderShort.ptOff = mHeader.mHorizOffset;
		strcpy( &(mHeaderShort.xUnit[ 0 ]), &(mHeader.mVerUnit[ 0 ] ) );
		strcpy( &(mHeaderShort.yUnit[ 0 ]), &( mHeader.mHorUnit[ 0 ] ) );	      		  	      	
    }
}

@end



