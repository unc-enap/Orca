/***************************************************************************
    ORAugerDefs.h  -  description

    begin                : Fri Aug 3, 2007
    copyright            : (C) 2007 by Andreas Kopmann
    email                : kopmann@ipe.fzk.de
 ***************************************************************************/


/** @mainpage IPE-DAQ Electronics Object for Orca
 * 
 * The IPE-DAQ electronics are a flexible data aqusition developed 
 * for the requirement of high energy physics experiments.
 * The first application was the Auger Observatory Fluorescence Detector. 
 * Core of the electronics is a digital trigger board based on FPGA 
 * technology. The programable logic allow to implement application
 * specific trigger logic. 
 *  
 * The KATRIN implementation is intended to detect the step height in noisy the ADC 
 * signals. Three modes of operation allow to record ADC traces of 
 * up to 6ms length, collect events data containing timestamp and energy up to
 * a sum trigger rate of 2-4 kHz and to determine energy histograms for even
 * higher rates.
 *
 * The IPE-DAQ Electronics consist of three parts:
 *   - Crate (ORAugerCrateModel)
 *   - One Central Configuration board (ORAugerSLTModel)
 *   - Up to 20 Trigger boards (ORAugerFLTModel)
 *
 */


/** @page changelog ChangeLog
 *
 * Version of the IPE-DAQ driver for KATRIN 
 * Format of the version is major numer.minor number-release.
 * The release will be incremented with any modification.
 *
 * Next:
 * - Merge nTPC and KATRIN design in Hardware/IPE
 * - Compensate the filter length!!!
 * - Data object for DeadTime
 * - Objects for histograms in Flt data stream
 * - Implementation of cFP-Interface
 * - Avoid error messages overflow in run mode
 *
 *
 * History:
 * - 1.1-7 - Added endian support for intel hosts.
 *            - Added conversion between host and network byte order.
 *            - Fixed bug in conversion of 64bit firewire address to high and
 *              low word.
 *              16.10.07 (ak)
 * - 1.1-6 - Bug fix in debug mode readout loop
 *            - Move access pointer reset outside the loop. 
 *              This is necessary if more than one event come at the same time
 *            - Changed ratio between energy and threshold to 1 (was 2 before)
 *            - Added energy shift mode
 *              21.9.07 (ak)
 * - 1.1-5 - Flt general design and cleanup
 *			  - separated the run mode readout code into methods in prep for 
 *				additions needed for fpga version with multiplicity trigger.
 *				(unrelated to KATRIN -- will be used for nTPC project, but code
 *				 must be compatible across projects)
 * - 1.1-4 - Flt dialog design:
 *            - Integrated hitrate parameter in channel section
 *            - Avoid error messages overflow in run mode#
 *              7.8.07 (ak)
 * - 1.1-3 - Changed display of Measure mode
 *            - Display of hitrate versus threshold.
 *            - Changed name of measure mode to Hitrate mode
 *            - Changed display of thresholds to energy scale (Hw: energy = threshold * 2)
 *            - Fixed inhibit source in Slt dialog (changed external and software)
 *            - Reorganized channel parameter in Flt dialog
 *            - Skipped double buffer in debug mode
 *            6.8.07 (ak) 
 * - 1.1-2 - Added threshold scan for Measure mode
 *            - Enhanced measure mode. The threshold is varied to estimate
 *              the energy distribution. This mode is intended for high rates
 *              that can not be managed by the other modes
 *            - Added overflow checks for run mode
 *            - Added simulation mode
 *           31.7.07 (ak)
 * - 1.0-1 - First working dirver for the IPE-DAQ electronics, that is able
 *           to handle all modes (debug, run and measure). 
 *           The ORCA documentation extended for the IPE-DAQ modules.
 *           Feature:
 *            - 22 ADC input channel with 12bit x 10MHz
 *            - Central run control (per software and external hardware signal) for all FLTs
 *            - Measurement of dead time caused by inhibit phases
 *            - Central software trigger for all FLTs
 *            - Trigger algorithm of programmable length that determines the step height
 *            - Measurement of trigger rate
 *            - Event buffer for 1024 events (energy, timestamps) in run mode
 *            - Debug mode to record ADC traces of up to 6.4ms length
 *           19.7.07 (ak)
 *
 *   
 */
 
 
/** Version of the IPE-DAQ object.
  * The version number is independand fron the Orca version. */ 
#define ORAUGER_VERSION @"1.1-7"


