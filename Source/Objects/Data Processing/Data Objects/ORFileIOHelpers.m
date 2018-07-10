/*
 *  ORFileIOHelpers.c
 *  Orca
 *
 *  Created by Mark Howe on Tue Mar 04 2003.
 *  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#include "ORFileIOHelpers.h"

NSMutableString* getNextString(NSFileHandle* fp)
{
    NSMutableString* aString = [NSMutableString stringWithCapacity:64];
    char c;
    @try {
		while((c = *((char*)[[fp readDataOfLength:1] bytes])) != '\n'){
			if(c!='\n')[aString appendFormat:@"%c",c];
		}
    }
	@catch(NSException* localException) {
    }
    return aString;
}

NSString* peek_ahead(NSFileHandle* fp)
{
    unsigned long long pos = [fp offsetInFile];
    NSString* peekString = getNextString(fp);
    [fp seekToFileOffset:pos];
    return peekString;
}