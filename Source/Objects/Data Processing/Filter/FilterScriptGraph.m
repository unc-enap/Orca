//
//  FilterScriptGraph.m
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
#include <string.h>
#import "StatusLog.h"

#include "FilterScript.h"
#include "FilterScript.tab.h"

/* recursive drawing of the syntax tree */
id exNode(nodeType *p, int level, BOOL lastOne);
id finalPass(id string);

/*****************************************************************************/

/* main entry point of the manipulation of the syntax tree */
int filterGraph (nodeType *p ) 
{
	int level = 0;
	NSLogFont([NSFont fontWithName:@"Monaco" size:9.0],@"\n%@\n",finalPass( exNode (p, level, NO)));
    return 0;
}

id exNode(nodeType *p, int aLevel, BOOL lastChild)
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
        [line appendString: exNode (p->opr.op[k], aLevel, k==count-1)];
    }
	return line;
}

id finalPass(id string)
{
	NSMutableArray* lines = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
	NSMutableString* aLine;
	int r1 = 0;
	while(1) {
		NSRange r = NSMakeRange(r1,2);
		BOOL delete = YES;
		int count = [lines count];
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
