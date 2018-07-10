//
//  ORFecDaughterCardModel.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORSNOCard.h"

#define kRp1Min 	0.0
#define kRp1Max 	5.0
#define kRp1Step 	((kRp1Max-kRp1Min)/255.0)

#define kRp2Min 	-3.3
#define kRp2Max 	0.0
#define kRp2Step 	((kRp2Max-kRp2Min)/255.0)

#define kVliMin		-1.0
#define kVliMax 	1.0
#define kVliStep 	((kVliMax-kVliMin)/255.0)

#define kVsiMin		-2.0
#define kVsiMax 	0.0
#define kVsiStep 	((kVsiMax-kVsiMin)/255.0)

#define kVtMin		-1.0
#define kVtMax 		1.0
#define kVtStep 	((kVtMax-kVtMin)/255.0)

#define kVbMin		-2.0
#define kVbMax 		4.0
#define kVbStep 	((kVbMax-kVbMin)/255.0)

@interface ORFecDaughterCardModel :  ORSNOCard 
{
	@private
		unsigned char rp1[2];	//RMPUP --ramp voltage up 	(0V to +3.3V)
		unsigned char rp2[2];	//RMP   --ramp voltage down (-3.3V to 0V)
		unsigned char vli[2];	//VLI					   	(-1V to 1V)
		unsigned char vsi[2];	//VSI						(-2V to 0V)
		unsigned char vt[8];	//VTH --ecal+corr	(-1V to 1V) channel related
        unsigned char _vt_ecal[8]; //VTH  --value from ECAL
        unsigned char _vt_zero[8]; //VTH  --zero from ECAL
        short _vt_corr[8]; //VTH  --ORCA correction on top of ECAL
        unsigned char _vt_safety; // min num clicks above zero    
		unsigned char vb[16]; //VBAL --balance voltage	(-2V to 4V)
		
		//channel related
		unsigned char ns100width[8];
		unsigned char ns20width[8];
		unsigned char ns20delay[8];
		unsigned char tac0trim[8]; //tac_trim
		unsigned char tac1trim[8]; //scmos
		short	cmosRegShown;
		BOOL	setAllCmos;
		BOOL	showVolts;
		NSString* comments;
}

@property (nonatomic,assign) unsigned char vt_safety;

#pragma mark •••Initialization

- (uint32_t) boardIDAsInt;

#pragma mark •••Accessors
- (NSString*)	comments;
- (void)		setComments:(NSString*)aComments;
- (BOOL) showVolts;
- (void) setShowVolts:(BOOL)aShowVolts;
- (BOOL) setAllCmos;
- (void) setSetAllCmos:(BOOL)aSetAllCmos;
- (short) cmosRegShown;
- (void) setCmosRegShown:(short)aCmosRegShown;
- (unsigned char) rp1:(short)anIndex;
- (void) setRp1:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) rp2:(short)anIndex;
- (void) setRp2:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) vli:(short)anIndex;
- (void) setVli:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) vsi:(short)anIndex;
- (void) setVsi:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) vt:(short)anIndex;
- (void) setVt:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) vt_ecal:(short)anIndex;
- (void) setVt_ecal:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) vt_zero:(short)anIndex;
- (void) setVt_zero:(short)anIndex withValue:(unsigned char)aValue;
- (short) vt_corr:(short)anIndex;
- (void) setVt_corr:(short)anIndex withValue:(short)aValue;
- (unsigned char) vb:(short)anIndex;
- (void) setVb:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) ns100width:(short)anIndex;
- (void) setNs100width:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) ns20width:(short)anIndex;
- (void) setNs20width:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) ns20delay:(short)anIndex;
- (void) setNs20delay:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) tac0trim:(short)anIndex;
- (void) setTac0trim:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) tac1trim:(short)anIndex;
- (void) setTac1trim:(short)anIndex withValue:(unsigned char)aValue;
- (void) loadDefaultValues;
- (void) silentUpdateVt:(short)anIndex;

#pragma mark ====Converter Methods
- (void) setRp1Voltage:(short)n withValue:(float)value;
- (float) rp1Voltage:(short) n;
- (void) setRp2Voltage:(short)n withValue:(float)value;
- (float) rp2Voltage:(short) n;
- (void) setVliVoltage:(short)n withValue:(float)value;
- (float) vliVoltage:(short) n;
- (void) setVsiVoltage:(short)n withValue:(float)value;
- (float) vsiVoltage:(short) n;
- (void) setVtVoltage:(short)n withValue:(float)value;
- (float) vtVoltage:(short) n;
- (void) setVbVoltage:(short)n withValue:(float)value;
- (float) vbVoltage:(short) n;
- (unsigned char) vb:(short)ch egain:(short)gain;

//Added by Christopher Jones 
- (NSMutableDictionary*) pullFecDaughterInformationForOrcaDB;

#pragma mark •••Hardware Access
- (NSString*) performBoardIDRead:(short) boardIndex;
- (void) readBoardIds;
- (void) setVtToHw;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


#pragma mark •••External String Definitions
extern NSString* ORDCModelEverythingChanged;
extern NSString* ORDCModelCommentsChanged;
extern NSString* ORDCModelShowVoltsChanged;
extern NSString* ORDCModelSetAllCmosChanged;
extern NSString* ORDCModelCmosRegShownChanged;
extern NSString* ORDCModelRp1Changed;
extern NSString* ORDCModelRp2Changed;
extern NSString* ORDCModelVliChanged;
extern NSString* ORDCModelVsiChanged;
extern NSString* ORDCModelVtChanged;
extern NSString* ORDCModelVbChanged;
extern NSString* ORDCModelNs100widthChanged;
extern NSString* ORDCModelNs20widthChanged;
extern NSString* ORDCModelNs20delayChanged;
extern NSString* ORDCModelTac0trimChanged;
extern NSString* ORDCModelTac1trimChanged;
extern NSString* ORDBLock;

