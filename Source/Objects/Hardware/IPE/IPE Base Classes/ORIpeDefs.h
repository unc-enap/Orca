/***************************************************************************
    ORIpeDefs.h  -  description

    begin                : Fri Aug 3, 2007
    copyright            : (C) 2007 by Andreas Kopmann
    email                : kopmann@ipe.fzk.de
 ***************************************************************************/

/*
Doxygen documentation:
- generate the documentation in a shell with:
  doxygen Orca.doxygen
- read the documentation by opening Orca-api/html/index.html in a html-Browser
*/


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
 *   - Crate (ORIpeCrateModel)
 *   - One Central Configuration board (ORIpeSLTModel)
 *   - Up to 20 Trigger boards (ORIpeFLTModel)
 *
 *
 *   <br><br><br><br><sub> Source of this documentation: ORIpeDefs.h</sub>
 */


/** @page changelog ChangeLog
 *
 * Version of the IPE-DAQ driver for KATRIN 
 * Format of the version is major numer.minor number-release.
 * The release will be incremented with any modification.
 *
 * Next:
 * - Check firewire address scheme: According to Apple information
 *   The upper address should be 0xffff. The parameter FWAddress.nodeId 
 *   is not used?! 
 * - Stop update of slt status, if there is no firewire connection!
 * - Merge IPE and KATRIN designs
 *   Include version information for the object again?!
 *   Ideal would be a combination with the hardware version display?!
 * - Compensate the filter length!!!
 * - Data object for DeadTime
 * - Objects for histograms in Flt data stream - and OrcaRoot decoder
 * - Implementation of cFP-Interface
 * - Avoid error messages overflow in run mode
 *
 *
 * History:
 * - 1.2-13 - Katrin FLT
 *            - from this version on (Orca svn revision > 986) old FPGA configurations won't be supported any more
 *              to simplify detection of FPGA configurations
 *            - feature bitfield and versionRevisionRegister content will be stored in the .Orca file; reading the register
 *              will write out messages only if detecting another configuration
 *              11.06.08 (-tb-)
 * - 1.2-12 - Katrin FLT dialog
 *            - First official release of the histogramming FGPA configuration (crate shipped to UW end of April):
 *              Version/Revision/Feature register on FLT (enables auto detection of FPGA configurations);
 *              PostTriggerTime setting in FLT;
 *              Onboard histogramming with page toggle
 *            - Starting hw histogramming moved to SLT (reason: syncronized startup) and made with broadcast
 *            - A lot of extensions in the FLT histogramming tab.
 *            - Pbus simulation mode: basic simulation of histogramming functionality.
 *            - Number of channels in histogram FPGA configuration: 4
 *            - Number of channels in standard and veto FPGA configuration: 20
 *              16.5.08 (-tb-)
 * - 1.2-11 - Slt Decoder for Trigger data
 *            - Changed from histogram2D to the data2D display type
 *              24.4.08 (ak)
 * - 1.2-10 - Katrin FLT dialog
 *            - tabs "Histogram" and "Veto" added (requires appropriate FPGA version)
 *            - in "Settings" a new mode "DAQ Run Mode" was added
 *              7.3.08 (-tb-)
 * - 1.2-9 - KatrinSLT dialog
 *            - Fixed readout windows of ADC traces with more than one trigger
 *              7.3.08 (ak)
 *            - Added KatrinSLT dialog that only contains the Katrin relevant settings.
 *            - Added the full trigger data to the multiplicity data set.
 *              Added some very simple graphical display.
 *            - Moved swapping of waveform elements from model to the decoder (KatrinFLT)
 *              Note: The format of the run files recorded with PowerPC CPUs will change.
 *              3.3.08 (ak)
 * - 1.1-8 - Acceleration of Slt memory readout: 
 *            - The Slt memory access was implementted by single access
 *              instead of using faster block transfer. 
 *              After changing to block mode the rates are consisted with Auger!
 *            - Added selectable display of event loop performance and trigger data.
 *            - Added parameter for the length of the readout windows (0..100us).
 *              This is a second parameter to customize the readout speed.
 *              10.12.07 (ak) 
 * - 1.1-7 - Added endian support for intel macs
 *            - Added conversion between host and network byte order in firewire base class
 *            - Fixed copy of 64bit firewire address to high and low word.
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
 *   <br><br><br><br><sub> Source of this documentation: ORIpeDefs.h</sub>
 */
 
 
/** @page addingconfigvariables Adding configuration variables
 *  Configuration variables are variables, which are attributes of the model and should
 *  be stored in the Orca configuration file (e.g. fltMode, daqRunMode, ...). Usually they
 *  have a representation in the controller (the GUI). E.g. "daqRunMode" has a counter part in the controller,
 *  "fltMode" has not.
 *  As example, in the comments for - (int) ORKatrinFLTModel::histoBinWidth there is a checklist of all coding tasks which are
 *  necessary to add a new configuration variable.
 *
 *   
 *   <br><br><br><br><sub> Source of this documentation: ORIpeDefs.h</sub>
 */


/** Version of the IPE-DAQ object.
  * The version number is independent from the Orca version. */ 
#define ORIPE_VERSION @"1.2-13"


