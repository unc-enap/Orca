//
//  OR1dFit.h
//  Orca
//
//  Created by Mark Howe on 2/13/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
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
@interface NSObject (OR1dFitDataSourceMethods)
- (int)   numberPointsInPlot:(id)aPlot;
- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y;
- (BOOL)  plotterShouldShowRoi:(id)aPlot;
- (id)    plotView;
- (id)    topPlot;
- (id)    roi;
- (id)    xScale;
- (id)    yScale;
@end


@interface OR1dFit : NSObject {
	NSDictionary*	fitLableAttributes;
    id				dataSource;
	BOOL			serviceAvailable;
	NSArray*		fit;
	int				maxChannel;
	int				minChannel;
	int				fitType;
	int				fitOrder;
	NSString*		fitString;
	NSString*		fitFunction;
	BOOL     fitValid;
	NSArray* fitParams;
	NSArray* fitParamNames;
	NSArray* fitParamErrors;
	NSNumber* chiSquare;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;

#pragma mark ***Accessors
- (void)	setDataSource:(id)ds;
- (id)		dataSource ;
- (BOOL) serviceAvailable;
- (BOOL)	  fitExists;
- (long) minChannel;
- (void) setMinChannel:(long)aChannel;
- (long) maxChannel;
- (void) setMaxChannel:(long)aChannel;
- (int) fitType;
- (void) setFitType:(int)aValue;
- (int) fitOrder;
- (void) setFitOrder:(int)aValue;
- (NSString*)	fitFunction;		 
- (void)		setFitFunction:(NSString*)aString;
- (NSString*)	fitString;		 
- (void)		setFitString:(NSString*)aString;
- (NSArray*)	fitParams;		 
- (void)		setFitParams:(NSArray*)anArray;
- (NSArray*)	fitParamNames;  
- (void)		setFitParamNames:(NSArray*)anArray;
- (NSArray*)	fitParamErrors ;
- (void)		setFitParamErrors:(NSArray*)anArray;
- (NSNumber*)	chiSquare;	 
- (void)		setChiSquare:(NSNumber*)aValue;

#pragma mark ***Fit Handling
- (void) doGaussianFit;	
- (void) doExponentialFit;				
- (void) doPolynomialFit:(int)aFitOrder;	
- (void) doLandauFit;	
- (void) doArbitraryFit:(NSString*)aFitFunction;	

- (void) doFit;
- (void) removeFit;
- (void) processResponse:(NSDictionary*)aResponse;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* OR1dFitChanged;
extern NSString* OR1dFitTypeChanged;
extern NSString* OR1dFitOrderChanged;
extern NSString* OR1dFitFunctionChanged;
extern NSString* OR1dFitStringChanged;
