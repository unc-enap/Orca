//
//  FilterScriptEx.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 25 2008.
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

#include <stdio.h>
#include "FilterScriptEx.h"
#include "FilterScript.h"
#include "ORFilterModel.h"
#include "FilterScript.tab.h"
#import "StatusLog.h"
#import "ORDataTypeAssigner.h"
#import <time.h>
#include <stdlib.h>

@implementation FilterScriptEx

- (id) init
{
    self = [super init];
    switchLevel = 0;
    return self;
}

- (void) dealloc
{
    [symbolTable release];
    [super dealloc];
}

- (void) setSymbolTable:(ORFilterSymbolTable*)aTable
{
    [aTable retain];
    [symbolTable release];
    symbolTable = aTable;
}

- (void) startFilterScript:(nodeType**)someNodes nodeCount:(int32_t)nodeCount delegate:(id) delegate
{	
	time_t seconds;
	time(&seconds);
	srand((unsigned int) seconds);
	
	unsigned node;
	for(node=0;node<nodeCount;node++){
		@try {
			[self ex:someNodes[node] delegate:delegate];
		}
		@catch(NSException* localException) {
		}
	}
}

- (void) finishFilterScript:(nodeType**)someNodes nodeCount:(int32_t)nodeCount delegate:(id) delegate
{
	unsigned node;
	for(node=0;node<nodeCount;node++){
		@try {
			[self ex:someNodes[node] delegate:delegate];
		}
		@catch(NSException* localException) {
		}
	}
}

- (void) runFilterNodes:(nodeType**)someNodes nodeCount:(int32_t)nodeCount delegate:(id) delegate
{
	if(symbolTable){
		unsigned node;
		for(node=0;node<nodeCount;node++){
			@try {
                [self ex:someNodes[node] delegate:delegate];
			}
			@catch(NSException* localException) {
			}
		}
	}
}

- (void) doSwitch:(nodeType*)p delegate:(id)delegate;
{
	@try {
		switchLevel++;
		switchValue[switchLevel] = [self ex:p->opr.op[0] delegate:delegate].val.lValue;
		[self ex:p->opr.op[1] delegate:delegate];
	}
	@catch(NSException* localException) {
		if(![[localException name] isEqualToString:@"break"]){
			switchValue[switchLevel] = 0;
			switchLevel--;
			[localException raise]; //rethrow
		}
	}
	switchValue[switchLevel] = 0;
	switchLevel--;
}

- (void) doCase:(nodeType*)p delegate:(id)delegate
{
	if(switchValue[switchLevel] == [self ex:p->opr.op[0] delegate:delegate].val.lValue){
		[self ex:p->opr.op[1] delegate:delegate];
		if (p->opr.nops == 3)[self ex:p->opr.op[2] delegate:delegate];
	}
}

- (void) doDefault:(nodeType*)p delegate:(id)delegate
{
	[self ex:p->opr.op[0] delegate:delegate];
	if (p->opr.nops == 2)[self ex:p->opr.op[1] delegate:delegate];
}


- (void) doLoop:(nodeType*)p delegate:(id)delegate
{
	BOOL breakLoop		= NO;
	BOOL continueLoop	= NO;
	do {
		if([delegate exitNow])break; 
		else {
			@try {
				[self ex:p->opr.op[0] delegate:delegate];
			}
			@catch(NSException* localException) {
				if([[localException name] isEqualToString:@"continue"])continueLoop = YES;
				else if([[localException name] isEqualToString:@"break"])breakLoop = YES;
				else [localException raise];
			}
		}
		if(breakLoop)break;
		if(continueLoop)continue;
	} while([self ex:p->opr.op[1] delegate:delegate].val.lValue);
}

- (void) whileLoop:(nodeType*)p delegate:(id)delegate;
{
	BOOL breakLoop		= NO;
	BOOL continueLoop	= NO;
	while([self ex:p->opr.op[0] delegate:delegate].val.lValue){ 
		if([delegate exitNow])break; 
		else {
			@try {
				[self ex:p->opr.op[1] delegate:delegate];
			}
			@catch(NSException* localException) {
				if([[localException name] isEqualToString:@"continue"])continueLoop = YES;
				else if([[localException name] isEqualToString:@"break"])breakLoop = YES;
				else [localException raise];
			}
		}
		if(breakLoop)	 break;
		if(continueLoop) continue;
	}
}

- (void) forLoop:(nodeType*)p delegate:(id) delegate
{
	BOOL breakLoop		= NO;
	BOOL continueLoop	= NO;
	
	for([self ex:p->opr.op[0] delegate:delegate] ; [self ex:p->opr.op[1] delegate:delegate].val.lValue ; [self ex:p->opr.op[2] delegate:delegate]){
		if([delegate exitNow])break;
		else {
			@try {
				[self ex:p->opr.op[3] delegate:delegate];
			}
			@catch(NSException* localException) {
				if([[localException name] isEqualToString:@"continue"])  continueLoop = YES;
				else if([[localException name] isEqualToString:@"break"])breakLoop = YES;
				else [localException raise];
			}
		}
		if(breakLoop)	 break;
		if(continueLoop) continue;
	}
}

- (void) defineArray:(nodeType*)p delegate:(id) delegate
{
	int n = (int)[self ex:p->opr.op[1] delegate:delegate].val.lValue;
	uint32_t* ptr = 0;
	if(n>0) ptr = calloc(n, sizeof(uint32_t)); //freed in 'freeArray'
	filterData tempData;
	tempData.type		= kFilterPtrType;
	tempData.val.pValue = ptr;
	[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
}

- (void) freeArray:(nodeType*)p delegate:(id) delegate
{
	filterData theFilterData;
	if([symbolTable getData:&theFilterData forKey:p->opr.op[0]->ident.key]){
		if(theFilterData.type == kFilterPtrType){
			if(theFilterData.val.pValue !=0){
				if(theFilterData.val.pValue){
					free(theFilterData.val.pValue); //alloc'ed in 'defineArray'
					theFilterData.val.pValue = 0;
				}
				[symbolTable setData:theFilterData forKey:p->opr.op[0]->ident.key];
			}
			//else {
			//	[NSException raise:@"Access Violation" format:@"Free of NIL pointer"];
			//}
		}
	}
}
- (uint32_t*) loadArray:(uint32_t*) ptr nodeType:(nodeType*)p
{
    if(!ptr)return ptr;
	filterData tempData;
    switch(p->type) {
		case typeCon: *ptr++ = p->con.value;		 break;
		case typeId:       
			[symbolTable getData:&tempData forKey:p->ident.key];
			*ptr++ = tempData.val.lValue;
			break;
		case typeOpr:
			switch(p->opr.oper) {
				case kMakeArgList:	
					ptr = [self loadArray:ptr nodeType:p->opr.op[0]];
					if(p->opr.nops == 2)ptr = [self loadArray:ptr nodeType:p->opr.op[1]];
					break;
				default: break;
			}
		default: break;
	}
	return ptr;
}

- (void) arrayList:(nodeType*)p delegate:(id) delegate

{
	int n = (int)[self ex:p->opr.op[1] delegate:delegate].val.lValue;
	uint32_t* ptr = 0;
	if(n>0) ptr = calloc(n, sizeof(uint32_t)); //freed in 'freeArray'
	filterData tempData;
	tempData.type		= kFilterPtrType;
	tempData.val.pValue = ptr;
	[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
	[self loadArray:ptr nodeType:p->opr.op[2]];
}	

- (filterData) ex:(nodeType*)p delegate:(id) delegate
{
	filterData tempData = {0,{0}};
	filterData tempData1;
    if (!p) {
		tempData.type = kFilterLongType;
		tempData.val.lValue = 0;
		
	}
    else switch(p->type) {
		case typeCon:       
			tempData.type = kFilterLongType;
			tempData.val.lValue = p->con.value;
			return tempData;
			
		case typeId:       
			[symbolTable getData:&tempData forKey:p->ident.key];
			return tempData;
			
		case typeOpr:
			switch(p->opr.oper) {
				case DO:		[self doLoop:p delegate:delegate]; return tempData;
				case WHILE:     [self whileLoop:p delegate:delegate]; return tempData;
				case FOR:		[self forLoop:p delegate:delegate]; return tempData;
				case CONTINUE:	[NSException raise:@"continue" format:@""]; return tempData;
				case IF:        if ([self ex:p->opr.op[0] delegate:delegate].val.lValue != 0) [self ex:p->opr.op[1] delegate:delegate];
				else if (p->opr.nops > 2) [self ex:p->opr.op[2] delegate:delegate];
					return tempData;
					
				case UNLESS:    if ([self ex:p->opr.op[0] delegate:delegate].val.lValue) [self ex:p->opr.op[1] delegate:delegate];
					return tempData;
					
				case BREAK:		[NSException raise:@"break" format:@""]; return tempData;
				case SWITCH:	[self doSwitch:p delegate:delegate]; return tempData;
				case CASE:		[self doCase:p delegate:delegate]; return tempData;
				case DEFAULT:	[self doDefault:p delegate:delegate]; return tempData;
				case PRINT:
					tempData = [self ex:p->opr.op[0] delegate:delegate];
					if(tempData.type == kFilterPtrType){
						if(tempData.val.pValue) NSLog(@"%d\n", *tempData.val.pValue); 
						else					NSLog(@"<nil ptr>\n"); 
					}
					else NSLog(@"%d\n", tempData.val.lValue); 
					return tempData;
					
				case PRINTH:
					tempData = [self ex:p->opr.op[0] delegate:delegate];
					if(tempData.type == kFilterPtrType){
						if(tempData.val.pValue) NSLog(@"0x%07lx\n", *tempData.val.pValue); 
						else					NSLog(@"<nil ptr>\n"); 
					}
					else NSLog(@"0x%07lx\n", tempData.val.lValue); 
					return tempData;
				case ';':       if (p->opr.nops>=1) [self ex:p->opr.op[0] delegate:delegate]; if (p->opr.nops>=2)return [self ex:p->opr.op[1] delegate:delegate]; else return tempData;
				case '=':      
				{
					tempData = [self ex:p->opr.op[1] delegate:delegate];
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
				}
				case UMINUS: 
					tempData = [self ex:p->opr.op[0] delegate:delegate];
					tempData.val.lValue = -tempData.val.lValue;
					return tempData;
					
				case '+':       tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue + [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case '-':       tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue - [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case '*':       tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue * [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case '/':       tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue / [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case '<':       tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue < [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case '>':       tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue > [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case '^':       tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue ^ [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case '%':       tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue % [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case '|':       tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue | [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case '&':       tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue & [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case '!':       tempData.val.lValue = ![self ex:p->opr.op[0] delegate:delegate].val.lValue; return tempData;
				case '~':       tempData.val.lValue = ~[self ex:p->opr.op[0] delegate:delegate].val.lValue; return tempData;
				case GE_OP:     tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue >= [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case LE_OP:     tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue <= [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case NE_OP:     tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue != [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case EQ_OP:     tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue == [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case LEFT_OP:   tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue << [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case RIGHT_OP:  tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue >> [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case AND_OP:	tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue && [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
				case OR_OP:		tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue || [self ex:p->opr.op[1] delegate:delegate].val.lValue; return tempData;
					
				case RIGHT_ASSIGN: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue>>[self ex:p->opr.op[1] delegate:delegate].val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case LEFT_ASSIGN: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue<<[self ex:p->opr.op[1] delegate:delegate].val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case MUL_ASSIGN: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue * [self ex:p->opr.op[1] delegate:delegate].val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case DIV_ASSIGN: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue / [self ex:p->opr.op[1] delegate:delegate].val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case OR_ASSIGN: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue | [self ex:p->opr.op[1] delegate:delegate].val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case MOD_ASSIGN: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue % [self ex:p->opr.op[1] delegate:delegate].val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case AND_ASSIGN: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue & [self ex:p->opr.op[1] delegate:delegate].val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case XOR_ASSIGN: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue ^ [self ex:p->opr.op[1] delegate:delegate].val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
					
				case kPostInc: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue;
					tempData1 = tempData;
					tempData1.val.lValue++;
					[symbolTable setData:tempData1 forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case kPreInc: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue+1;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case kPostDec: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue;
					tempData1 = tempData;
					tempData1.val.lValue--;
					[symbolTable setData:tempData1 forKey:p->opr.op[0]->ident.key];
					
				case kPreDec: 
					tempData.val.lValue = [self ex:p->opr.op[0] delegate:delegate].val.lValue-1;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
					
					//array stuff
				case kArrayAssign:
				{
					uint32_t* ptr = [self ex:p->opr.op[0] delegate:delegate].val.pValue;
					if(ptr!=0){
						*ptr = [self ex:p->opr.op[1] delegate:delegate].val.lValue;
						tempData.type = kFilterLongType;
						tempData.val.lValue = *ptr;
					}
					else {
						[NSException raise:@"Access Violation" format:@"Nil Pointer"];
					}
				}
					return tempData;
					
				case kLeftArray:
				{
					uint32_t* ptr = [self ex:p->opr.op[0] delegate:delegate].val.pValue;
					if(ptr!=0){
						uint32_t offset = [self ex:p->opr.op[1] delegate:delegate].val.lValue;
						tempData.type = kFilterPtrType;
						tempData.val.pValue = ptr+offset;
					}
					else {
						[NSException raise:@"Access Violation" format:@"Nil Pointer"];
					}
				}
					return tempData;
					
				case kArrayElement:
				{
					uint32_t* ptr = [self ex:p->opr.op[0] delegate:delegate].val.pValue;
					if(ptr!=0){
						uint32_t offset = [self ex:p->opr.op[1] delegate:delegate].val.lValue;
						tempData.type = kFilterLongType;
						tempData.val.lValue = ptr[offset];
					}
					else {
						[NSException raise:@"Access Violation" format:@"Nil Pointer"];
					}
				}
					return tempData;
					
				case kDefineArray:		[self defineArray:p delegate:delegate];  		break;
                case FREEARRAY:			[self freeArray:p delegate:delegate]; 			break;
				case kArrayListAssign:	[self arrayList:p delegate:delegate];           break;
					
				case CURRENTRECORD_IS:
					[symbolTable getData:&tempData forKey:"CurrentRecordPtr"];
					tempData.val.lValue =  [delegate record:tempData.val.pValue isEqualTo:[self ex:p->opr.op[0] delegate:delegate].val.lValue]; 
					return tempData;
					
				case EXTRACTRECORD_ID: 
					tempData.val.lValue =  [delegate extractRecordID:[self ex:p->opr.op[0] delegate:delegate].val.lValue]; 
					return tempData;
					
				case EXTRACTRECORD_LEN: 
					tempData.val.lValue =  [delegate extractRecordLen:[self ex:p->opr.op[0] delegate:delegate].val.lValue]; 
					return tempData;
					
				case EXTRACT_VALUE: 
					tempData.val.lValue =  [delegate extractValue:[self ex:p->opr.op[0] delegate:delegate].val.lValue 
															 mask:[self ex:p->opr.op[1] delegate:delegate].val.lValue
														thenShift:[self ex:p->opr.op[2] delegate:delegate].val.lValue]; 
					return tempData;
					
					
				case SHIP_RECORD:
				{
					uint32_t* ptr = [self ex:p->opr.op[0] delegate:delegate].val.pValue;
					if(ptr) [delegate shipRecord:ptr length:ExtractLength(*ptr)]; 
				}
					break;
					
				case PUSH_RECORD:
				{
					uint32_t stack = [self ex:p->opr.op[0] delegate:delegate].val.lValue;
					uint32_t* ptr  = [self ex:p->opr.op[1] delegate:delegate].val.pValue;
					uint32_t ptrValue  = [self ex:p->opr.op[1] delegate:delegate].val.lValue;
					[delegate pushOntoStack:stack ptrCheck:ptrValue record:ptr]; 
				}
					break;
					
				case POP_RECORD:
					tempData.val.pValue = [delegate popFromStack:[self ex:p->opr.op[0] delegate:delegate].val.lValue];
					return tempData;
					
				case BOTTOM_POP_RECORD:
					tempData.val.pValue = [delegate popFromStackBottom:[self ex:p->opr.op[0] delegate:delegate].val.lValue];
					return tempData;
					
				case SHIP_STACK:
					[delegate shipStack:[self ex:p->opr.op[0] delegate:delegate].val.lValue];
					break;
					
				case DUMP_STACK:
					[delegate dumpStack:[self ex:p->opr.op[0] delegate:delegate].val.lValue];
					break;
					
				case STACK_COUNT:
					tempData.val.lValue = [delegate stackCount:[self ex:p->opr.op[0] delegate:delegate].val.lValue];
					return tempData;
					
				case HISTO_1D:				
					[delegate histo1D:(int)[self ex:p->opr.op[0] delegate:delegate].val.lValue value:[self ex:p->opr.op[1] delegate:delegate].val.lValue];
					break;
					
				case HISTO_2D:	
				{
					uint32_t x = [self ex:p->opr.op[1] delegate:delegate].val.lValue;
					uint32_t y = [self ex:p->opr.op[2] delegate:delegate].val.lValue;
					[delegate histo2D:(int)[self ex:p->opr.op[0] delegate:delegate].val.lValue x:x y:y];
				}
					break;
					
				case STRIPCHART:	
				{
					uint32_t aTime = [self ex:p->opr.op[1] delegate:delegate].val.lValue;
					uint32_t aValue = [self ex:p->opr.op[2] delegate:delegate].val.lValue;
					[delegate stripChart:(int)[self ex:p->opr.op[0] delegate:delegate].val.lValue time:aTime value:aValue];
				}
					break;
					
				case TIME:	
				{
					time_t theTime;
					time(&theTime);
					tempData.val.lValue = (uint32_t)theTime;
				}
					break;
					
					
				case DISPLAY_VALUE:	
					[delegate setOutput:(int)[self ex:p->opr.op[0] delegate:delegate].val.lValue
							  withValue:[self ex:p->opr.op[1] delegate:delegate].val.lValue];
					break;
					
				case RANDOM:
				{
					uint32_t high = [self ex:p->opr.op[0] delegate:delegate].val.lValue;
					uint32_t low  = [self ex:p->opr.op[1] delegate:delegate].val.lValue;
					if(low>high){
						uint32_t temp = high;
						high = low;
						low = temp;
					}
					tempData.val.lValue = rand() % (high - low + 1) + low;
				}
					break;
					
					
				case RESET_DISPLAYS:
					[delegate resetDisplays];
					break;	
					
			}
    }
    return tempData;
}

/* main entry point of the manipulation of the syntax tree */
- (int) filterGraph:(nodeType*)p
{
	int level = 0;
	NSLogFont([NSFont fontWithName:@"Monaco" size:9.0],@"\n%@\n",[self finalPass:[self exNode:p level:level lastChild: NO]]);
    return 0;
}

- (id) exNode:(nodeType*)p level:(int)aLevel lastChild:(BOOL) lastChild
{
    
    if (!p) return @"";
	NSMutableString* line = nil;
	
    switch(p->type) {
        case typeCon: line = [NSMutableString stringWithFormat:@"c(%d)", p->con.value]; break;
        case typeId:  line = [NSMutableString stringWithFormat:@"(%s)", p->ident.key]; break;
        case typeOpr:
            switch(p->opr.oper){
                case kConditional:		line = [NSMutableString stringWithString:@"[Conditional]"];	break;
                case DO:				line = [NSMutableString stringWithString:@"[do]"];			break;
                case WHILE:				line = [NSMutableString stringWithString:@"[while]"];		break;
                case FOR:				line = [NSMutableString stringWithString:@"[for]"];			break;
                case IF:				line = [NSMutableString stringWithString:@"[if]"];			break;
                case UNLESS:			line = [NSMutableString stringWithString:@"[unless]"];		break;
				case SWITCH:			line = [NSMutableString stringWithString:@"[switch]"];		break;
                case CASE:				line = [NSMutableString stringWithString:@"[case]"];		break;
                case DEFAULT:			line = [NSMutableString stringWithString:@"[default]"];		break;
                case PRINT:				line = [NSMutableString stringWithString:@"[print]"];		break;
                case PRINTH:			line = [NSMutableString stringWithString:@"[printhex]"];	break;
                case kPostInc:			line = [NSMutableString stringWithString:@"[postInc]"];		break;
                case kPreInc:			line = [NSMutableString stringWithString:@"[preInc]"];		break;
                case kPostDec:			line = [NSMutableString stringWithString:@"[postDec]"];		break;
                case kPreDec:			line = [NSMutableString stringWithString:@"[prdDec]"];		break;
                case ';':				line = [NSMutableString stringWithString:@"[;]"];			break;
                case '=':				line = [NSMutableString stringWithString:@"[=]"];			break;
                case UMINUS:			line = [NSMutableString stringWithString:@"[-]"];			break;
                case '~':				line = [NSMutableString stringWithString:@"[~]"];			break;
                case '^':				line = [NSMutableString stringWithString:@"[^]"];			break;
                case '%':				line = [NSMutableString stringWithString:@"[%]"];			break;
                case '!':				line = [NSMutableString stringWithString:@"[!]"];			break;
                case '+':				line = [NSMutableString stringWithString:@"[+]"];			break;
                case '-':				line = [NSMutableString stringWithString:@"[-]"];			break;
                case '*':				line = [NSMutableString stringWithString:@"[*]"];			break;
                case '/':				line = [NSMutableString stringWithString:@"[/]"];			break;
                case '<':				line = [NSMutableString stringWithString:@"[<]"];			break;
                case '>':				line = [NSMutableString stringWithString:@"[>]"];			break;
                case LEFT_OP:			line = [NSMutableString stringWithString:@"[<<]"];			break;
                case RIGHT_OP:			line = [NSMutableString stringWithString:@"[<<]"];			break;
				case AND_OP:			line = [NSMutableString stringWithString:@"[&&]"];			break;
				case '&':				line = [NSMutableString stringWithString:@"[&]"];			break;
				case OR_OP:				line = [NSMutableString stringWithString:@"[||]"];			break;
				case '|':				line = [NSMutableString stringWithString:@"[|]"];			break;
				case GE_OP:				line = [NSMutableString stringWithString:@"[>=]"];			break;
                case LE_OP:				line = [NSMutableString stringWithString:@"[<=]"];			break;
                case NE_OP:				line = [NSMutableString stringWithString:@"[!=]"];			break;
                case EQ_OP:				line = [NSMutableString stringWithString:@"[==]"];			break;
				case BREAK:				line = [NSMutableString stringWithString:@"[break]"];		break;
				case CONTINUE:			line = [NSMutableString stringWithString:@"[continue]"];	break;
                case LEFT_ASSIGN:		line = [NSMutableString stringWithString:@"[<<=]"];			break;
                case RIGHT_ASSIGN:		line = [NSMutableString stringWithString:@"[>>=]"];			break;
                case ADD_ASSIGN:		line = [NSMutableString stringWithString:@"[+=]"];			break;
                case SUB_ASSIGN:		line = [NSMutableString stringWithString:@"[-=]"];			break;
                case MUL_ASSIGN:		line = [NSMutableString stringWithString:@"[*=]"];			break;
                case DIV_ASSIGN:		line = [NSMutableString stringWithString:@"[/=]"];			break;
                case OR_ASSIGN:			line = [NSMutableString stringWithString:@"[|=]"];			break;
                case AND_ASSIGN:		line = [NSMutableString stringWithString:@"[&=]"];			break;
                case ',':				line = [NSMutableString stringWithString:@"[,]"];			break;
                case kDefineArray:		line = [NSMutableString stringWithString:@"[kDefineArray]"];break;
                case kLeftArray:		line = [NSMutableString stringWithString:@"[kLeftArray]"];	break;
                case kArrayElement:		line = [NSMutableString stringWithString:@"[arrayElement]"];break;
                case kArrayAssign:		line = [NSMutableString stringWithString:@"[kArrayAssign]"];break;
                case kArrayListAssign:	line = [NSMutableString stringWithString:@"[kArrayListAssign]"];break;
				case FREEARRAY:			line = [NSMutableString stringWithString:@"[free]"];		break;
                case EXTRACTRECORD_LEN:	line = [NSMutableString stringWithString:@"[extractLen]"];	break;
                case CURRENTRECORD_IS:	line = [NSMutableString stringWithString:@"[currentRecordIs]"];	break;
                case EXTRACTRECORD_ID:	line = [NSMutableString stringWithString:@"[exgtractID]"];	break;
                case SHIP_RECORD:		line = [NSMutableString stringWithString:@"[shipRecord]"];	break;
                case PUSH_RECORD:		line = [NSMutableString stringWithString:@"[push]"];		break;
                case POP_RECORD:		line = [NSMutableString stringWithString:@"[pop]"];			break;
                case BOTTOM_POP_RECORD:	line = [NSMutableString stringWithString:@"[bottomPop]"];	break;
                case SHIP_STACK:		line = [NSMutableString stringWithString:@"[shipStack]"];	break;
                case DUMP_STACK:		line = [NSMutableString stringWithString:@"[dumpStack]"];	break;
				case STACK_COUNT:		line = [NSMutableString stringWithString:@"[stackCount]"];	break;
				case HISTO_1D:			line = [NSMutableString stringWithString:@"[histo1D]"];		break;
				case HISTO_2D:			line = [NSMutableString stringWithString:@"[histo2D]"];		break;
				case TIME:				line = [NSMutableString stringWithString:@"[time]"];		break;
				case RANDOM:			line = [NSMutableString stringWithString:@"[random]"];		break;
				case STRIPCHART:		line = [NSMutableString stringWithString:@"[stripChart]"];	break;
				case DISPLAY_VALUE:		line = [NSMutableString stringWithString:@"[displayValue]"];break;
				case RESET_DISPLAYS:	line = [NSMutableString stringWithString:@"[resetDisplays]"];break;
				case EXTRACT_VALUE:		line = [NSMutableString stringWithString:@"[extractValue]"];break;
 				default:				line = [NSMutableString stringWithString:@"[??]"];			break;
            }
            break;
    }
	NSString* prependString = @"";
	int i;
	for(i=0;i<aLevel;i++){
		if(i>=aLevel-1)prependString = [prependString stringByAppendingString:@"|----"];
		else prependString = [prependString stringByAppendingString:@"|    "];
	}
	[line insertString:prependString atIndex:0];
	[line appendString:@"\n"];
    
	int count = 0;
	if (p->type == typeOpr){
		count = p->opr.nops;
	}
	
    /* node is leaf */
    if (count == 0) {
		if(lastChild){
			NSString* suffixString = @"";
			int i;
			for(i=0;i<aLevel;i++){
				if(i<aLevel)suffixString = [suffixString stringByAppendingString:@"|    "];
			}
			[line appendFormat:@"%@\n",suffixString];
		}
        return line;
    }
	aLevel++;
    
    /* node has children */
    int k;
    for (k = 0; k < count; k++) {
        [line appendString: [self exNode:p->opr.op[k] level: aLevel lastChild: k==count-1]];
    }
	return line;
}

- (id) finalPass:(id) string
{
	NSMutableArray* lines = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
	NSMutableString* aLine;
	int r1 = 0;
	while(1) {
		NSRange r = NSMakeRange(r1,2);
		BOOL delete = YES;
		int count = (int)[lines count];
		int i;
		BOOL done = YES;
		for(i=count-1;i>=0;i--){
			aLine = [lines objectAtIndex:i];
			if([aLine length] < NSMaxRange(r))continue;
			done = NO;
			
			if(delete && [[aLine substringWithRange:r] isEqualToString:@"| "]){
				NSMutableString* newString = [NSMutableString stringWithString:aLine];
				[newString replaceCharactersInRange:r withString:@"  "];
				[lines replaceObjectAtIndex:i withObject:newString];
			}
			else if(delete && [[aLine substringWithRange:r] isEqualToString:@"|-"]){
				delete = NO;
			}
			else if(!delete && ![[aLine substringWithRange:NSMakeRange(r1,1)] isEqualToString:@"|"]){
				delete = YES;
			}
		}
		r1 += 5;
		if(done)break;
	}
	return [lines componentsJoinedByString:@"\n"];
}

@end
