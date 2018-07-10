/*
    File:		ORTRS1Model.h
 
    Description:	CAMAC LeCroy TR8818 Transient Recorder System
 				with MM8106 Memory Object Definition
 
                        SUPERCLASS = ORCamacIOCard
 
    Author:		F. McGirt
    
    Copyright:		Copyright 2003 F. McGirt.  All rights reserved.
    
    Change History:     2/3/03 First Version
                        12/27/04 Converted to ObjC for use in the ORCA project. MAH CENPA University of Washington
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

 
#pragma mark ¥¥¥Imported Files
#import "ORCamacIOCard.h"
#import "ORDataTaker.h"

@interface ORTRS1Model : ORCamacIOCard <ORDataTaker> {
    @private
        unsigned long	dataId;
        unsigned short	controlRegister;
        unsigned char	offsetRegister;
		BOOL			firstTime;
		int				expectedNumberDataBytes;
		unsigned long*  dataBuffer;
		
		//place to cache some stuff for alittle more speed.
        unsigned long 	crateAndStationId;
        unsigned short cachedStation;
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;
        
#pragma mark ¥¥¥Accessors
- (unsigned short) offsetRegister;
- (void) setOffsetRegister:(unsigned short)aOffsetRegister;
- (unsigned short) controlRegister;
- (void) setControlRegister:(unsigned short)aControlRegister;
- (unsigned short) readControlRegister;
- (void) writeControlRegister:(unsigned short) theControlRegister;
- (void) readSingleSample:(unsigned char*) aSingleSample;
- (unsigned short) readOffsetRegister;
- (void) writeOffsetRegister:(unsigned char) theOffsetRegister;


#pragma mark ¥¥¥HW Access
- (void) initBoard;
- (unsigned char) readModuleID;
- (void) armTrigger;
- (void) internalTrigger;
- (BOOL) digitizeWaveform:(unsigned short*)data dataSize:(unsigned int) dataSize;
- (void) enableRead;
- (void) readDigitizer:(unsigned short*)theData maxLength:(unsigned int) theLength;
- (void) enableLAM;
- (void) disableLAM;
- (BOOL) testLAM;
- (void) clearLAM;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORTRS1ModelOffsetRegisterChanged;
extern NSString* ORTRS1ModelControlRegisterChanged;
