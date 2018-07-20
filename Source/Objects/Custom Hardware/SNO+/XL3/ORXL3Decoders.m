//
//  ORXL3Decoders.m
//  Orca
//
//Created by Jarek Kaspar on Sun, September 12, 2010
//Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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

#import "ORXL3Decoders.h"
#import "PacketTypes.h"

@implementation ORXL3DecoderForXL3MegaBundle

#define swapLong(x) (((uint32_t)(x) << 24) | (((uint32_t)(x) & 0x0000FF00) <<  8) | (((uint32_t)(x) & 0x00FF0000) >>  8) | ((uint32_t)(x) >> 24))

- (NSString*) decodePMTBundle:(uint32_t*)ptr
{
	BOOL swapBundle = YES;
	if (0x0000ABCD != htonl(0x0000ABCD) && indexerSwaps) swapBundle = NO;
	//if (0x0000ABCD == htonl(0x0000ABCD) && !indexerSwaps) swapBundle = NO;

    NSMutableString* dsc = [NSMutableString string];

    /*
    if (ptr[1] == 0x5F46414B && ptr[2] == 0x455F5F0A) {
        char fake_id[5];
        if (0x0000ABCD != htonl(0x0000ABCD)) ptr[0] = swapLong(ptr[0]);
        memcpy(fake_id, ptr, 4);
        fake_id[4] = '\0';
        [dsc appendFormat:@"XL3 fake id: %s\n", fake_id];
        if (0x0000ABCD != htonl(0x0000ABCD)) ptr[0] = swapLong(ptr[0]);
    }
    else {
    */

    if (swapBundle) {
        ptr[0] = swapLong(ptr[0]);
        ptr[1] = swapLong(ptr[1]);
        ptr[2] = swapLong(ptr[2]);
    }
    
    [dsc appendFormat:@"GTId = 0x%06x\n", (*ptr & 0x0000ffff) | ((ptr[2] << 4) & 0x000f0000) | ((ptr[2] >> 8) & 0x00f00000)];
    [dsc appendFormat:@"CCCC: %lu, %lu, ", (*ptr >> 21) & 0x1fUL, (*ptr >> 26) & 0x0fUL];
    [dsc appendFormat:@"%lu, %lu\n", (*ptr >> 16) & 0x1fUL, (ptr[1] >> 12) & 0x0fUL];
    [dsc appendFormat:@"QHL = 0x%03lx\n", ptr[2] & 0x0fffUL ^ 0x0800UL];
    [dsc appendFormat:@"QHS = 0x%03lx\n", (ptr[1] >> 16) & 0x0fffUL ^ 0x0800UL];
    [dsc appendFormat:@"QLX = 0x%03lx\n", ptr[1] & 0x0fffUL ^ 0x0800UL];
    [dsc appendFormat:@"TAC = 0x%03lx\n", (ptr[2] >> 16) & 0x0fffUL ^ 0x0800UL];
    [dsc appendFormat:@"Sync errors CGT16: %@,\n", ((*ptr >> 30) & 0x1UL) ? @"Yes" : @"No"];
    [dsc appendFormat:@"CGT24: %@, ", ((*ptr >> 31) & 0x1UL) ? @"Yes" : @"No"];
    [dsc appendFormat:@"CMOS16: %@\n", ((ptr[1] >> 31) & 0x1UL) ? @"Yes" : @"No"];
    [dsc appendFormat:@"Missed count error: %@\n", ((ptr[1] >> 28) & 0x1UL) ? @"Yes" : @"No"];
    [dsc appendFormat:@"NC/CC: %@, ", ((ptr[1] >> 29) & 0x1UL) ? @"CC" : @"NC"];
    [dsc appendFormat:@"LGI: %@\n", ((ptr[1] >> 30) & 0x1UL) ? @"Long" : @"Short"];
    [dsc appendFormat:@"Wrd0 = 0x%08x\n", *ptr];
    [dsc appendFormat:@"Wrd1 = 0x%08x\n", ptr[1]];
    [dsc appendFormat:@"Wrd2 = 0x%08x\n\n", ptr[2]];

    //swap back the PMT bundle 
    if (swapBundle) {
        ptr[0] = swapLong(ptr[0]);
        ptr[1] = swapLong(ptr[1]);
        ptr[2] = swapLong(ptr[2]);
    }
    
    return [[dsc retain] autorelease];
}


- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
	indexerSwaps = [aDecoder needToSwap]; //won't work for multicatalogs with mixed endianness
	return length; //must return number of bytes processed.
}



- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	/*
	the megaBundle is always big-endian, but ORRecordIndexer could have swapped it
	LE file & LE cpu indexer swaps? NO  datarecord BE swapneeded? YES
	LE file & BE cpu indexer swaps? YES datarecord LE swapneeded? YES  
	BE file & LE cpu indexer swaps? YES datarecord LE swapneeded? NO
	BE file & BE cpu indexer swaps? NO  datarecord BE swapneeded? NO
	*/

	BOOL swapBundle = YES;
	if (0x0000ABCD != htonl(0x0000ABCD) && indexerSwaps) swapBundle = NO;
	//if (0x0000ABCD == htonl(0x0000ABCD) && !indexerSwaps) swapBundle = NO;

	uint32_t length = ExtractLength(*ptr);
	unsigned short i = 0;
    unsigned short version = 0;
	NSMutableString* dsc = [NSMutableString string];

    ptr += 1;
    version = ptr[0] >> 5 & 0x7;
    [dsc appendFormat:@"packetNum: %u\ncrate_num: %u\nversion: %d\nnum_longs: %u\n",
     ptr[0] >> 16, ptr[0] & 0x1f, version, length];
    ptr += 1;

    switch (version) {
        case 0:
            for (i=0; i<length/3; i++) {
                [dsc appendString:[self decodePMTBundle:ptr]];
                ptr += 3;
            }
            break;
            
        case 1:
            if (swapBundle) {
                ptr[0] = swapLong(ptr[0]); ptr[1] = swapLong(ptr[1]); ptr[2] = swapLong(ptr[2]);
            }
            uint32_t num_longs = ptr[0] & 0xffffff;
            [dsc appendFormat:@"\ncrate_num: %u\nnum_longs: %u\npass_min: %u\nxl3_clock: %u\n",
             ptr[0] >> 24, num_longs, ptr[1], ptr[2]];
            if (swapBundle) {
                ptr[0] = swapLong(ptr[0]); ptr[1] = swapLong(ptr[1]); ptr[2] = swapLong(ptr[2]);
            }
            
            if (num_longs * 4 > XL3_PAYLOAD_SIZE) {
                [dsc appendFormat:@"num longs > XL3_PAYLOAD_SIZE,\ntrimming to continue\n"];
                num_longs = XL3_PAYLOAD_SIZE / 4;
            }
            if (num_longs > length - 1) {
                [dsc appendFormat:@"num longs > orca packet length,\ntrimming to continue\n"];
                num_longs = length - 1;
            }
            
            ptr += 3;            
            uint32_t mini_header = 0;
            while (num_longs != 0) {
                mini_header = ptr[0];
                if (swapBundle) {
                    mini_header = swapLong(mini_header);
                }
                
                unsigned int mini_num_longs = mini_header & 0xffffff;
                unsigned char mini_card = mini_header >> 24 & 0xf;
                unsigned char mini_type = mini_header >> 31;
                
                [dsc appendFormat:@"\n---\nmini bundle\ncard: %d\ntype: %@\nnum_longs: %u\ninfo: 0x%08x\n\n",
                 mini_card, mini_type?@"pass cur":@"pmt bundles", mini_num_longs, mini_header];
                ptr +=1;
                
                switch (mini_type) {
                    case 0:
                        //pmt bundles
                        if (mini_num_longs % 3 || num_longs < mini_num_longs) {
                            [dsc appendFormat:@"mini bundle header\ncorrupted, quit.\n"];
                            num_longs = 0;
                            [dsc appendFormat:@"0x%08x\n0x%08x\n0x%08x\n0x%08x\n", ptr[0], ptr[1], ptr[2], ptr[3]];
                            break;
                        }

                        for (i = 0; i < mini_num_longs / 3; i++) {
                            [dsc appendString:[self decodePMTBundle:ptr]];
                            ptr += 3;
                        }
                        num_longs -= mini_num_longs + 1;
                        break;
                        
                    case 1:
                        //pass cur
                        if (mini_num_longs != 1 || num_longs < 2) {
                            [dsc appendFormat:@"mini bundle header\ncorrupted, quit.\n"];
                            num_longs = 0;
                            break;
                        }
                        uint32_t pass_cur = ptr[0];
                        if (swapBundle) {
                            pass_cur = swapLong(pass_cur);
                        }
                        [dsc appendFormat:@"pass_cur: %u\n", pass_cur];
                        num_longs -= 2;
                        ptr += 1;
                        break;
                        
                    default:
                        break;
                }
            }
            break;

        default:
            [dsc appendFormat:@"\nnot implemented.\n"];
            break;
    }
	return [[dsc retain] autorelease];
}

@end

@implementation ORXL3DecoderForCmosRate

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
    indexerSwaps = [aDecoder needToSwap];
	return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    /* data[0] ORCA int32_t header
     * data[1] crate number filled by orca
     * data[2..18] longs by orca
     * data[19] ... big endian longs written by XL3, swapped by orca
     * data[21+8*32] ... timestamp string by orca, 6 longs
     */

    NSMutableString* dsc = [NSMutableString stringWithFormat: @"CMOS rates crate %u\n\nslot mask: 0x%x\n", dataPtr[1], dataPtr[2]];
    unsigned char slot = 0;
    for (slot=0; slot<16; slot++) {
        [dsc appendFormat:@"ch mask slot %2d: 0x%08x\n", slot, dataPtr[3+slot]];
    }
    [dsc appendFormat:@"delay: %u ms\n\nerror flags: 0x%08x\n", dataPtr[19], dataPtr[20]];

    unsigned char ch, slot_idx = 0;
    for (slot=0; slot<16; slot++) {
        if ((dataPtr[2] >> slot) & 0x1) {
            [dsc appendFormat:@"\nslot %d\n", slot];
            for (ch = 0; ch < 32; ch++) {
                [dsc appendFormat:@"ch %2d: %u\n", ch, dataPtr[21 + slot_idx*32 + ch]];
            }
            slot_idx++;
        }
    }
    unsigned int idx; //XCode 3 requires the type def outside the for loop. changed to unsigned int to prevent truncation warning.
    if (indexerSwaps) for (idx=21+8*32; idx < 21+8*32+6; idx++) dataPtr[idx] = swapLong(dataPtr[idx]);
    [dsc appendFormat:@"\ntimestamp: %s\n", (unsigned char*) &dataPtr[21+8*32]];
    if (indexerSwaps) for (idx=21+8*32; idx < 21+8*32+6; idx++) dataPtr[idx] = swapLong(dataPtr[idx]);
    
    return [[dsc retain] autorelease];
}

@end

@implementation ORXL3DecoderForFifo

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
    indexerSwaps = [aDecoder needToSwap];
	return length; //must return number of bytes processed.    
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    /* data[0] ORCA int32_t header
     * data[1] crate number filled by ORCA
     * data[2] ... data[18] floats written by XL3 swapped by ORCA
     */

    NSMutableString* dsc = [NSMutableString stringWithFormat: @"FIFO state crate %u\n\n", dataPtr[1]];
    unsigned char slot=0;
    
    for (slot=2; slot<18; slot++) {
        [dsc appendFormat:@"slot %2d: %3.1f\n", slot-2, *(float*)&dataPtr[slot]];
    }

    [dsc appendFormat:@"\nXL3 mem: %3.1f\n", *(float*)&dataPtr[18]];

    return [[dsc retain] autorelease];
}
@end

@implementation ORXL3DecoderForPmtBaseCurrent

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
    indexerSwaps = [aDecoder needToSwap];
	return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    /* data[0] ORCA int32_t header
     * data[1] crate number filled by ORCA
     * data[2] ... data[18] longs written by ORCA
     * data[19] int32_t written by XL3 swapped by ORCA
     * data[20] ... 16*32 chars adc written by XL3
     * data[20+16*8] ... 16*32 chars busyFlagss written by XL3
     * data[20+16*8+16*8] ... timestamp string by ORCA, 6 longs
     */
    
    NSMutableString* dsc = [NSMutableString stringWithFormat: @"PMT base currents crate %u\n", dataPtr[1]];
        
    [dsc appendFormat:@"slotmask: 0x%04x\n\nchannel masks:\n", dataPtr[2]];
    unsigned short idx;
    for (idx=3; idx<19; idx++) {
        [dsc appendFormat:@"slot %02u: 0x%08x\n", idx-3U, dataPtr[idx]];
    }
    [dsc appendFormat:@"\nerrorFlags: 0x%08x\n", dataPtr[19]];

    if (indexerSwaps) for (idx=20; idx < 20+16*8+16*8+6; idx++) dataPtr[idx] = swapLong(dataPtr[idx]);
    [dsc appendFormat:@"\nADC values:"];
    unsigned char* adc = (unsigned char*) &dataPtr[20];
    unsigned char slot;
    for (slot=0; slot<16; slot++) {
        [dsc appendFormat:@"\nslot %hhu:", slot];
		unsigned char db;
        for (db=0; db<8; db++) {
            [dsc appendFormat:@"\nch%02u-%02u:", db*4, db*4+3];
			unsigned char ch;
            for (ch=0; ch<4; ch++) {
                [dsc appendFormat:@" 0x%02hhx", adc[slot*32 + db*4 + ch]];
            }
        }
    }
    [dsc appendFormat:@"\n\nbusy flags:"];
    adc = (unsigned char*) &dataPtr[20+16*8];
    for (slot=0; slot<16; slot++) {
        [dsc appendFormat:@"\nslot %hhu:", slot];
		unsigned char db;
        for (db=0; db<8; db++) {
            [dsc appendFormat:@"\nch%02u-%02u:", db*4, db*4+3];
			unsigned char ch;
            for (ch=0; ch<4; ch++) {
                [dsc appendFormat:@" 0x%02hhx", adc[slot*32 + db*4 + ch]];
            }
        }
    }
    [dsc appendFormat:@"\n\ntimestamp: %s\n", (unsigned char*) &dataPtr[20+16*8+16*8]];
    if (indexerSwaps) for (idx=20; idx < 20+16*8+16*8+6; idx++) dataPtr[idx] = swapLong(dataPtr[idx]);

    [dsc appendFormat:@"\nraw packet:\n"];
    for (idx = 0; idx < 20+16*8+16*8+6; idx++) {
        [dsc appendFormat:@"%02hu: 0x%08x\n", idx, dataPtr[idx]];
    }
    
    return [[dsc retain] autorelease];
}
@end

@implementation ORXL3DecoderForHv

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
    indexerSwaps = [aDecoder needToSwap];
	return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    /* data[0] ORCA int32_t header
     * data[1] crate number filled by ORCA
     * data[2] ... data[5] floats written by ORCA
     * data[6] ... timestamp string by ORCA, 6 longs
     */
    
    NSMutableString* dsc = [NSMutableString stringWithFormat: @"HV status %u\n\n", dataPtr[1]];
    float* vlt = (float*)&dataPtr[2];
    [dsc appendFormat:@"voltage A: %4.1f V\n", vlt[0]];
    [dsc appendFormat:@"voltage B: %4.1f V\n", vlt[1]];
    [dsc appendFormat:@"current A: %3.1f mA\n", vlt[2]];
    [dsc appendFormat:@"current B: %3.1f mA\n", vlt[3]];
    
    unsigned char idx; //XCode 3 requires the type def outside the for loop 
    if (indexerSwaps) for (idx=6; idx<12; idx++) dataPtr[idx] = swapLong(dataPtr[idx]);
    [dsc appendFormat:@"\n\ntimestamp: %s\n", (unsigned char*) &dataPtr[6]];
    if (indexerSwaps) for (idx=6; idx<12; idx++) dataPtr[idx] = swapLong(dataPtr[idx]);

    return [[dsc retain] autorelease];
}
@end

@implementation ORXL3DecoderForVlt

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
    indexerSwaps = [aDecoder needToSwap];
	return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    /* data[0] ORCA int32_t header
     * data[1] crate number filled by ORCA
     * data[2] ... data[9] floats written by XL3, swapped by ORCA
     * data[10] ... timestamp string by ORCA, 6 longs
     */
    
    NSMutableString* dsc = [NSMutableString stringWithFormat: @"XL3 voltages crate: %u\n\n", dataPtr[1]];
    
    float* vlt = (float*)&dataPtr[2];
    [dsc appendFormat:@"VCC : %6.2f V\n", vlt[0]];
    [dsc appendFormat:@"VEE : %6.2f V\n", vlt[1]];
    //[dsc appendFormat:@"VP8 : %4.1f V\n", vlt[2]];
    [dsc appendFormat:@"VP24: %6.2f V\n", vlt[3]];
    [dsc appendFormat:@"VM24: %6.2f V\n", vlt[4]];
    [dsc appendFormat:@"TMP0: %6.2f V\n", vlt[5]];
    [dsc appendFormat:@"TMP1: %6.2f V\n", vlt[6]];
    [dsc appendFormat:@"TMP2: %6.2f V\n", vlt[7]];
    
    unsigned char idx;
    if (indexerSwaps) for (idx=10; idx<16; idx++) dataPtr[idx] = swapLong(dataPtr[idx]);
    [dsc appendFormat:@"\ntimestamp: %s\n", (unsigned char*) &dataPtr[10]];
    if (indexerSwaps) for (idx=10; idx<16; idx++) dataPtr[idx] = swapLong(dataPtr[idx]);
    
    return [[dsc retain] autorelease];
}
@end

@implementation ORXL3DecoderForFecVlt

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
    indexerSwaps = [aDecoder needToSwap];
	return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    /* data[0] ORCA int32_t header
     * data[1] crate number filled by ORCA
     * data[2] slot ORCA
     * data[3] ... data[23] floats written by XL3, swapped by ORCA
     * data[24] ... timestamp string by ORCA, 6 longs
     */
    
    NSMutableString* dsc = [NSMutableString stringWithFormat: @"XL3 voltages crate: %u\n\n", dataPtr[1]];
    
    [dsc appendFormat:@"slot: %u\n", dataPtr[2]];
    
    float* vlt = (float*)&dataPtr[3];
    [dsc appendFormat:@" -24V Sup: %6.2f V\n", vlt[0]];
    [dsc appendFormat:@" -15V Sup: %6.2f V\n", vlt[1]];
    [dsc appendFormat:@"  VEE Sup: %6.2f V\n", vlt[2]];
    [dsc appendFormat:@"-3.3V Sup: %6.2f V\n", vlt[3]];
    [dsc appendFormat:@"-2.0V Sup: %6.2f V\n", vlt[4]];
    [dsc appendFormat:@" 3.3V Sup: %6.2f V\n", vlt[5]];
    [dsc appendFormat:@" 4.0V Sup: %6.2f V\n", vlt[6]];
    [dsc appendFormat:@"  VCC Sup: %6.2f V\n", vlt[7]];
    [dsc appendFormat:@" 6.5V Sup: %6.2f V\n", vlt[8]];
    [dsc appendFormat:@" 8.0V Sup: %6.2f V\n", vlt[9]];
    [dsc appendFormat:@"  15V Sup: %6.2f V\n", vlt[10]];
    [dsc appendFormat:@"  24V Sup: %6.2f V\n", vlt[11]];
    [dsc appendFormat:@"-2.0V Ref: %6.2f V\n", vlt[12]];
    [dsc appendFormat:@"-1.0V Ref: %6.2f V\n", vlt[13]];
    [dsc appendFormat:@" 0.8V Ref: %6.2f V\n", vlt[14]];
    [dsc appendFormat:@" 1.0V Ref: %6.2f V\n", vlt[15]];
    [dsc appendFormat:@" 4.0V Ref: %6.2f V\n", vlt[16]];
    [dsc appendFormat:@" 5.0V Ref: %6.2f V\n", vlt[17]];
    [dsc appendFormat:@"    Temp.: %6.2f degC\n", vlt[18]];
    [dsc appendFormat:@"  Cal DAC: %6.2f V\n", vlt[19]];
    [dsc appendFormat:@"  HV Curr: %6.2f mA\n", vlt[20]];
    
	unsigned char idx;
    if (indexerSwaps) for (idx=24; idx<30; idx++) dataPtr[idx] = swapLong(dataPtr[idx]);
    [dsc appendFormat:@"\ntimestamp: %s\n", (unsigned char*) &dataPtr[24]];
    if (indexerSwaps) for (idx=24; idx<30; idx++) dataPtr[idx] = swapLong(dataPtr[idx]);
    
    return [[dsc retain] autorelease];
}
@end

