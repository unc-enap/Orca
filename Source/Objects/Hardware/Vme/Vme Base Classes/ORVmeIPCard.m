//
//  ORVmeIOCard.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORVmeIPCard.h"


@implementation ORVmeIPCard

- (int) slotConv
{
    int conv[4] = {3,2,1,0};
    int aSlot = [self slot];
    if(aSlot>=0 && aSlot<=3)return conv[aSlot];
    else return -1;
}

- (void) setSlot:(unsigned short)aSlot
{
	[super setSlot:aSlot];
	[self calcBaseAddress];
}

- (void) calcBaseAddress
{
	[self setBaseAddress:[guardian baseAddress] + [self slotConv]*0x100];
}


- (NSString*) identifier
{
	int i = [self slotConv];
    if(i<0)return @"?";
	NSString* s[4]={
		@"IP A",
		@"IP B",
		@"IP C",
		@"IP D"
	};
	return [NSString stringWithString:s[i]];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORIPCarrierModel");
}

- (unsigned long) baseAddress
{
    return [guardian baseAddress]+ [self slotConv] * 0x100;
}

- (void) probe
{
    
    int addressOffset[4]={0x0080,0x0180,0x0280,0x0380};
    
    int i = [self slotConv];
    @try {
        unsigned char ipac[5];
        strncpy((char*)ipac,"\0",5);
        [[self adapter] readByteBlock:&ipac[0] atAddress:[guardian baseAddress]+addressOffset[i]+0x1
                            numToRead:1 withAddMod:[guardian addressModifier] usingAddSpace:0x01];
        
        [[self adapter] readByteBlock:&ipac[1] atAddress:[guardian baseAddress]+addressOffset[i]+0x3
                            numToRead:1 withAddMod:[guardian addressModifier] usingAddSpace:0x01];
		
        [[self adapter] readByteBlock:&ipac[2] atAddress:[guardian baseAddress]+addressOffset[i]+0x5
                            numToRead:1 withAddMod:[guardian addressModifier] usingAddSpace:0x01];
		
        [[self adapter] readByteBlock:&ipac[3] atAddress:[guardian baseAddress]+addressOffset[i]+0x7
                            numToRead:1 withAddMod:[guardian addressModifier] usingAddSpace:0x01];
		
        unsigned char manufacturerCode = 0;
        [[self adapter] readByteBlock:&manufacturerCode atAddress:[guardian baseAddress]+addressOffset[i]+0x9
                            numToRead:1 withAddMod:[guardian addressModifier] usingAddSpace:0x01];
		
        unsigned char modelCode = 0;
        [[self adapter] readByteBlock:&modelCode atAddress:[guardian baseAddress]+addressOffset[i]+0x0b
                            numToRead:1 withAddMod:[guardian addressModifier] usingAddSpace:0x01];
		
        if(!strcmp((const char*)ipac,"IPAC"))NSLog(@"%@ %s Manufacturer Code: 0x%x  Model Code: 0x%x\n",[self identifier],ipac,manufacturerCode,modelCode);
        else NSLog(@"%@ ID Prom appears to contain garbage.\n",[self identifier]);
		
    }
	@catch(NSException* localException) {
        NSLog(@"%@ raised exception during probe. gion probably empty.\n",[self identifier]);
    }
	
}


@end
