//
//  ORIpeV4SLTDefs.h
//  Orca
//
//  Created by Mark Howe on Tues Sept 29 2009.
//  Copyright (c) 2009 CENPA, University of North Carolina. All rights reserved.
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


#define SLT_HW_VER317 0x20 // Mar 2005 changes/ fixes of dead/veto counter?!
#define SLT_HW_VER310 0x19

#define SLT_HW_VER SLT_HW_VER310
#define SLT_HW_VER_MAX SLT_HW_VER317

// Number of memory pages
#define SLT_PAGES 64

/*  Mask for the IR controller on the Slt board:
  * The interrupt "NextPage" is generated if a next page
  * signal occures.
  */
#define SLT_IRMASK_NXPG       0x0001

/*  Mask for the IR controller on the Slt board:
  * The interrupt "Warning AllPagesFull" is
  * generated if the actual page
  * pointer is set to the last free page. The
  * next trigger will stop the data aquisition.
  */
#define SLT_IRMASK_WAR_PGFULL 0x0002

/*  Mask for the IR controller on the Slt board:
  * The interrupt "Error Loading Flt FPGAs"
  * is generated if an error
  * occures while the configuration of the
  * FPGAs on the Flt boards.
  */
#define SLT_IRMASK_ERR_FLT    0x0004

/*  Mask for the IR controller on the Slt board:
  * The interrupt "Error Configuration"
  * is generated if the command
  * configure FPGAs is given on a system without
  * an confuration error?!
  */
#define SLT_IRMASK_ERR_CONF   0x0008

/*  Mask for the IR controller on the Slt board:
  * The interrupt "Error Sensor OutOfRange" is generated if one
  * of the sensors leaves the allowed range.
  */
#define SLT_IRMASK_ERR_SC     0x0010

/*  ?
  */
#define SLT_IRMASK_ERR_CFPGA  0x0020
/*  ?
  */
#define SLT_IRMASK_ERR_TFPGA  0x0040


/*  Mask for the IR controller on the Slt board:
  * The interrupt "Error PageFull" is generated if all pages
  * are full. The data aquisition has been stopped
  * in this case and needs to be restarted
  * manually after some pages have been cleared.
  */
#define SLT_IRMASK_ERR_PGFULL 0x0080

/*  Mask for the IR controller on the Slt board:
  * The interrupt "PageLost" is generated if an next
  * page occures before an acknowledge for
  * last occurence of the trigger has been received.
  * If this warning occures, it is necessary
  * to analyse the page status register for
  * the filled pages. At least one page number will not
  * be returned with the acknoledge vector.
  */
#define SLT_IRMASK_WAR_PGLOST 0x0100


/*  Mask for the IR controller on the Slt board:
  * An interrupt is generated if at least one
  * of the two FPGA errors occure.
  * In both cases the synchronisation with the
  * second strobe signal failed.
  * This mask includes Error CFPGA Sync and
  * Error TFPGA Sync
  */
#define SLT_IRMASK_ERR_SYNC   0x0060


/*  Mask for the IR controller on the Slt board:
  * An interrupt is generated if any of
  * the page controller interrupts is generated.
  * This mask includes "NextPage", "Warning AllPagesFull",
  * "Error AllPagesFull" and "Warning PageLost".
  *
  */
#define SLT_IRMASK_PGCTRL     0x0183

/*  Values of the trigger source use with the
  * Slt time stamps.
  */
#define SLT_TRIGGER_SW    0x01  // Software
#define SLT_TRIGGER_I_N   0x07  // Internal + Neighbors
#define SLT_TRIGGER_LEFT  0x04  // left neighbor
#define SLT_TRIGGER_RIGHT 0x02  // right neighbor
#define SLT_TRIGGER_INT   0x08  // Internal
#define SLT_TRIGGER_EXT   0x10  // External


/*  Time Stamp Record Types used with the
  * Slt counters (see shipSltTimestamp).
  */
  
#define kUnknownType		0
#define kSecondsCounterType	1
#define kVetoCounterType	2
#define kDeadCounterType	3
#define kRunCounterType		4

/*  Time Stamp Record Types used with the
  * Slt time stamps (see shipSltTimestamp). Used with the Counter Type above ...
  */
#define kStartRunType		1
#define kStopRunType		2
#define kStartSubRunType	3
#define kStopSubRunType		4


