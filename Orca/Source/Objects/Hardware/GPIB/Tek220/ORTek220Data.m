//
//  ORTek220Data.m
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
// Imports
#import "ORTek220Data.h"
#import "OROscBaseModel.h"
#import "ORDataTypeAssigner.h"

@implementation ORTek220Data
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
 *				time is only stored in ORTek220Data object for channel 0.
 */
//--------------------------------------------------------------------------------
- (id) initWithWaveformModel: (OROscBaseModel*) aModel channel: (short) aChannel
{

    if ( self = [super init] ){
        mMaxSizeWaveform = [ aModel waveformLength ];
        mAddress = [ aModel primaryAddress ];
        mChannel = aChannel;
        mData = nil;
        mModel = aModel;
    }
    return self;
}

- (void) dealloc
{
    [ mTime release ];
    [ mData release ];
    [ super dealloc ];
}

#pragma mark ***Accessors
- (long) actualWaveformSize
{
    return( mActualSizeWaveform );
}

- (void) setActualWaveformSize: (unsigned long) aWaveformSize
{
    mActualSizeWaveform = aWaveformSize;
}

- (long) maxWaveformSize
{
    return mMaxSizeWaveform;
}

- (NSMutableData*) rawData
{
    return mData;
}

- (NSMutableData*) timeData
{
    return( mTime );
}

- (char*) rawHeader
{
    return( mHeaderChar );
}


#pragma mark ***Data Routines
//--------------------------------------------------------------------------------
//- (void) clearAcquisition
//{
//    mAcquire = false;
//}

- (void) setGtid: (unsigned long) aGtid
{
    
    unsigned long dataWord[2];

    // Create the new data storage area.
    unsigned long len;
    if(IsShortForm([mModel gtidDataId])){
        len = 1;
        // Place header in first word of data storage along with gtid
        dataWord[0] = [mModel gtidDataId] | (aGtid & 0x00FFFFFF);
    }
    else {
        len = 2;
        dataWord[0] = [mModel gtidDataId] | len;
        dataWord[1] = aGtid;
    }
    
    [ mGtid release ];
    mGtid = [[ NSMutableData allocWithZone: NULL ] initWithBytes:dataWord length: len*sizeof(long) ];
    
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
    mData = [[ NSMutableData allocWithZone: NULL ] initWithCapacity: ( mMaxSizeWaveform + 8 ) ];
    [ mData setLength: (mMaxSizeWaveform + 8) ]; // Since data is added outside of this class
                                                 //  have to set data length here.
    dataLoc = [ mData mutableBytes ] + 8;
    
    return( dataLoc ); 
}

- (unsigned long long) timeInSecs
{
    return timeInSecs;
}

- (void) setTimeInSecs:(unsigned long long)aTime
{
    timeInSecs = aTime;
}

- (void) setDataPacketData: (ORDataPacket*) aDataPacket timeData: (NSData*) aTimeData
                                                     includeGTID: (BOOL) aFlag
{
    NSArray*		arrayWithObjects;
    
    // Place header in first word of data storage.

    unsigned long		mHeaderBaseInfo[2];
    mHeaderBaseInfo[0] = [ mModel dataId ] | ([mData length]/sizeof(long) & kLongFormLengthMask);
    mHeaderBaseInfo[1] = ([ mModel primaryAddress ] & 0xF ) << 23 | (mChannel & 0xF ) << 19;

    if(mData){
        memcpy( [ mData mutableBytes ], &mHeaderBaseInfo, 8 );
    
        // Place data in data packet. Use the data cache since we run in a separate thread.
        // Only first channel includes GTID and time.  Subsequent channels only include the data.
        if (aFlag) arrayWithObjects = [ NSArray arrayWithObjects: mGtid, aTimeData, mData, nil ];
        else       arrayWithObjects = [ NSArray arrayWithObjects: mData, nil ];
        
        [ aDataPacket addArrayToCache: arrayWithObjects ];
    }
}

- (NSData*) timePacketData: (ORDataPacket*) aDataPacket channel: (unsigned short) aChannel
{
    unsigned long 	dataWord[3];
    unsigned long   len = 3;

    // Place header in first word of data storage along with data.
    dataWord[0] = [ mModel clockDataId] | len;
    dataWord[1] =  ((aChannel & 0x7 ) << 24) | (timeInSecs & 0x00ffffff00000000LL)>>32;
    dataWord[2] = timeInSecs & 0x00000000ffffffffLL;
    [mTime release];
    mTime = [[NSMutableData allocWithZone:nil] initWithBytes:dataWord length:len*sizeof(long)];
    
	return mTime;
}

//- (void) setAcquisition
//{
//    mAcquire = true;
//}

- (void) convertHeader
{
	
	// Only process if we have header.
   if ( mHeaderChar[0] != '\0' ){
		
		// Get data from raw header and place in variables that are understandable.
		//06/09/03 MAH changed the %d's to %ld's to get rid of two compiler warnings.
        sscanf( mHeaderChar, "%ld;%e;%e;%e;%ld;%[^;];%s", 
             &( mHeader.nrPts ),
             &( mHeader.yOff ),
             &( mHeader.yMult ),
             &( mHeader.xIncr ),
             &( mHeader.ptOff ),
             &( mHeader.xUnit[ 0 ] ),
             &( mHeader.yUnit[ 0 ] ) );	      		  	      	
    }
}


@end
