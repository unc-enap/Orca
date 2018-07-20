//
//  NSData+Extensions.m
//  Orca
//
//  Created by Mark Howe on Wed Dec 04 2002.
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


#pragma mark ¥¥¥Imported Files

@implementation NSData (OR_NSDataWithExtensions)

#pragma mark ¥¥¥Class Methods
+(NSData*)dataWithNSPoint:(NSPoint)aPoint
{
    return [NSData dataWithBytes:&aPoint length:sizeof(NSPoint)];
}

+(NSData*)dataWithNSRect:(NSRect)aRect
{
    return [NSData dataWithBytes:&aRect length:sizeof(NSRect)];
}


#pragma mark ¥¥¥Conversions
-(NSPoint)pointValue
{
    return *((NSPoint*)[self bytes]);
}

-(NSRect)rectValue
{
    return *((NSRect*)[self bytes]);
}

- (NSArray *)rowsAndColumns
{
	NSString *fileContents;
	
	@try {
		fileContents = [[[NSString alloc] initWithData: self encoding: NSASCIIStringEncoding] autorelease];
   	}
	@catch(NSException* localException) {
		fileContents = nil;
		[NSException raise: @"Format Error"
					format: @"There was a problem reading your file.  Please make sure that it is a Tab delimited file.  Additional information:\n\nException: %@\nReason: %@\nDetail: %@", 
		 [localException name], 
		 [localException reason], 
		 [localException userInfo]];
	}
	
	return [[fileContents lines] valueForKey: @"tabSeparatedComponents"];
}

- (NSString *)description
{
	unsigned char *bytes = (unsigned char *)[self bytes];
	NSMutableString *s   = [NSMutableString stringWithFormat:@"NSData (total length: %d bytes):\n", (int)[self length]];
	int maxIndex = 1024;
	int i, j;
	uint32_t len = (uint32_t)MIN([self length],maxIndex);
	for (i=0 ; i<len ; i+=16 ){
		for (j=0 ; j<16 ; j++) {
			int index = i+j;
			if (index < maxIndex)	[s appendFormat:@"%02X ", bytes[index]];
			else				[s appendFormat:@"   "];
		}
		
		[s appendString:@"| "];   
		for (j=0 ; j<16 ; j++){
			int index = i+j;
			if (index < maxIndex){
				unsigned char c = bytes[index];
				if (c < 32 || c > 127) c = '.';
				[s appendFormat:@"%c", c];
			}
		}
		
		if (i+16 < maxIndex)[s appendString:@"\n"]; //all but last row gets a newline
	}
	
	return s;	
}

@end

static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
@implementation NSData (MBBase64)

+ (id) dataWithBase64EncodedString:(NSString *)string;
{
	if (string == nil)        [NSException raise:NSInvalidArgumentException format:@""];
	if ([string length] == 0) return [NSData data];
	
	static char *decodingTable = NULL;
	if (decodingTable == NULL)
	{
		decodingTable = malloc(256);
		if (decodingTable == NULL)
			return nil;
		memset(decodingTable, CHAR_MAX, 256);
		NSUInteger i;
		for (i = 0; i < 64; i++)
			decodingTable[(short)encodingTable[i]] = i;
	}
	
	const char *characters = [string cStringUsingEncoding:NSASCIIStringEncoding];
	if (characters == NULL)     //  Not an ASCII string!
		return nil;
	char *bytes = malloc((([string length] + 3) / 4) * 3);
	if (bytes == NULL)
		return nil;
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (YES)
	{
		char buffer[4];
		short bufferLength;
		for (bufferLength = 0; bufferLength < 4; i++)
		{
			if (characters[i] == '\0')
				break;
			if (isspace(characters[i]) || characters[i] == '=')
				continue;
			buffer[bufferLength] = decodingTable[(short)characters[i]];
			if (buffer[bufferLength++] == CHAR_MAX)      //  Illegal character!
			{
				free(bytes);
				return nil;
			}
		}
		
		if (bufferLength == 0)
			break;
		if (bufferLength == 1)      //  At least two characters are needed to produce one byte!
		{
			free(bytes);
			return nil;
		}
		
		//  Decode the characters in the buffer to bytes.
		bytes[length++] = (buffer[0] << 2) | (buffer[1] >> 4);
		if (bufferLength > 2)
			bytes[length++] = (buffer[1] << 4) | (buffer[2] >> 2);
		if (bufferLength > 3)
			bytes[length++] = (buffer[2] << 6) | buffer[3];
	}
	
	bytes = realloc(bytes, length);
	return [NSData dataWithBytesNoCopy:bytes length:length];
}

- (NSString *)base64Encoding;
{
	if ([self length] == 0)
		return @"";
	
    char *characters = malloc((([self length] + 2) / 3) * 4);
	if (characters == NULL)
		return nil;
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (i < [self length])
	{
		char buffer[3] = {0,0,0};
		short bufferLength = 0;
		while (bufferLength < 3 && i < [self length])
			buffer[bufferLength++] = ((char *)[self bytes])[i++];
		
		//  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
		characters[length++] = encodingTable[(buffer[0] & 0xFC) >> 2];
		characters[length++] = encodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
		if (bufferLength > 1)
			characters[length++] = encodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
		else characters[length++] = '=';
		if (bufferLength > 2)
			characters[length++] = encodingTable[buffer[2] & 0x3F];
		else characters[length++] = '=';	
	}
	
	return [[[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES] autorelease];
}

@end
