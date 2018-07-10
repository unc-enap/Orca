/*
 *  cb.c
 *  cPciTest
 *
 *  Created by Mark Howe on 6/14/07.
 *  Copyright 2007 CENPA, University of Washington. All rights reserved.
 *
 */
 
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

#include "CircularBuffer.h"
#include <signal.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <pthread.h>
#include <sys/types.h>

typedef struct {
    pthread_mutex_t  cbMutex;
    int32_t*         buffer;
    int32_t          bufferLength;
    int32_t          amountInBuffer;
    int32_t          writeIndex;
    int32_t          readIndex;
    int32_t          lostByteCount;
    int32_t          wrapArounds;
} CircularBufferStruct;


static CircularBufferStruct cb;
//--------------------------------------------------------
// Circular Buffer format
//     BxxxxxxxBxxxxxx
//     ^------------------Block count (longs) to follow
//      ^^^^^^^-----------the data
//                    ^---Write index points to here
//     ^------------------Read  index points to here
//--------------------------------------------------------


void CB_initialize(size_t length)
{
    if (cb.buffer) CB_cleanup();
    cb.buffer = (int32_t*)malloc(length*sizeof(int32_t));
    if(!cb.buffer)exit(1);
    cb.bufferLength = length;
    pthread_mutex_init(&cb.cbMutex, NULL);
    cb.readIndex  = 0;
    cb.writeIndex = 0;
    cb.lostByteCount = 0;
    cb.amountInBuffer = 0;

}

void CB_cleanup(void)
{
    if(cb.buffer)free(cb.buffer);
    cb.buffer = 0;
    cb.writeIndex = 0;
    cb.readIndex  = 0;
    cb.amountInBuffer = 0;
    cb.lostByteCount = 0;
    cb.wrapArounds     = 0;
    pthread_mutex_destroy(&cb.cbMutex);
}

void CB_flush(void)
{
    pthread_mutex_lock (&cb.cbMutex);                        //begin critical section
    cb.lostByteCount += cb.amountInBuffer;
    cb.writeIndex = 0;
    cb.readIndex  = 0;
    cb.amountInBuffer = 0;
    pthread_mutex_unlock (&cb.cbMutex);                       //end critical section
}


int32_t CB_freeSpace(void)
{
	int32_t freeSpace = 0;
    pthread_mutex_lock (&cb.cbMutex);                        //begin critical section
	freeSpace = cb.bufferLength - cb.amountInBuffer;
    pthread_mutex_unlock (&cb.cbMutex);                       //end critical section
	return freeSpace;
}

void CB_writeDataBlock(int32_t* data, int32_t length)
{
    if(length<=0)return;
    
    pthread_mutex_lock (&cb.cbMutex);                        //begin critical section
    if((cb.amountInBuffer + length + 1) < cb.bufferLength){    //is there room for the data plus the block length header?
        int32_t index = cb.writeIndex;
        cb.buffer[index] = length;                        //write the block length NOT including header
        index++;
        if(index >= cb.bufferLength){
            index = 0;
            cb.wrapArounds++;
        }
        size_t firstWrite = 
            (length + index < cb.bufferLength) ? 
            length : cb.bufferLength - index - 1;
        size_t secondWrite = 
            (firstWrite == length) ? 0 : length - firstWrite;
        memcpy(cb.buffer + index, data, firstWrite*sizeof(int32_t));
        index += firstWrite;
        if (secondWrite != 0) {
          index = secondWrite;
          memcpy(cb.buffer, data + firstWrite, secondWrite*sizeof(int32_t)); 
          cb.wrapArounds++;
        }
        
        cb.amountInBuffer += length + 1;
        cb.writeIndex = index;                                //advance the write pointer
    }
    else {
        cb.lostByteCount += length*sizeof(int32_t);
    }
    pthread_mutex_unlock (&cb.cbMutex);                        //end critical section
}

int32_t CB_nextBlockSize(void)
{
    //peak at the next block and return its size.
    int32_t blockSize = 0;
    pthread_mutex_lock (&cb.cbMutex);        //begin critical section
    if(cb.amountInBuffer > 0){    
        blockSize = cb.buffer[cb.readIndex];
    }
    pthread_mutex_unlock (&cb.cbMutex);        //end critical section
    return blockSize;
}


int32_t CB_readNextDataBlock(int32_t* buffer,int32_t maxSize)
{
    int32_t blockLength = 0;
    pthread_mutex_lock (&cb.cbMutex);                        //begin critical section
    
    if(cb.amountInBuffer > 0){    
        int32_t index = cb.readIndex;
        blockLength = cb.buffer[index];                    //first word is the block length
        index = (index+1) % cb.bufferLength;
        if(maxSize>=blockLength){
            size_t firstWrite = 
                (blockLength + index < cb.bufferLength) ? 
                blockLength : cb.bufferLength - index - 1;
            size_t secondWrite = 
                (firstWrite == blockLength) ? 0 : blockLength - firstWrite;
            memcpy(buffer, cb.buffer + index, firstWrite*sizeof(int32_t));
            index += firstWrite;
            if (secondWrite != 0) {
              index = secondWrite;
              memcpy(buffer + firstWrite, cb.buffer, secondWrite*sizeof(int32_t)); 
            }
             cb.amountInBuffer -= blockLength + 1;                //adjust the total
        }
        else {
            index += blockLength;                            //have to discard because the user buffer is too small
            index = index % cb.bufferLength;
            cb.lostByteCount += blockLength;
        }
        cb.readIndex = index;                                //advance the read pointer
    }
    else blockLength = 0; 
    
    pthread_mutex_unlock (&cb.cbMutex);                        //end critical section
    return blockLength;
}

void CB_getBufferInfo(BufferInfo* buffInfo)
{
    pthread_mutex_lock (&cb.cbMutex);        //begin critical section
    buffInfo->readIndex       = cb.readIndex;
    buffInfo->writeIndex     = cb.writeIndex;
    buffInfo->lostByteCount  = cb.lostByteCount;
    buffInfo->amountInBuffer = cb.amountInBuffer;
    buffInfo->wrapArounds    = cb.wrapArounds;
    pthread_mutex_unlock (&cb.cbMutex);      //end critical section    
}
