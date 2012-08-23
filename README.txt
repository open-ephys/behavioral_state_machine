Files to run behavioral state machine (BSM).  BSM are designed to control behavior, mainly through analog/digital input/output device.  Each 'state' in a machine can trigger a set of outputs (both digital and/or analog).  Inputs are automatically tracked (and saved).  Logic functions defined when the machine should transition between states.  As all functions are evaluated in Matlab, general functionality is inherited.

Run 'BSMGUI' to use the graphical interface.  As almost nothing exists in GUI itself, functions can be called in turn from command line (unknown improvement in speed).  Currently runs ~300Hz on a midline i5 (note that this only effects response to inputs, not the outputs themselves which run in the background).

As BSM currently uses session-based interface to the NIDAQ, BSM requires newer Matlab versions (most cards are supported after 2011b).

BSMs are defined via XML file.  Examples and schema are provided in the 'BSM XML' subdirectory.

To add:
* Need to improve documentation.
* Support for multiple BSMs running simultaneously.
* Graphical interface for creating/editing BSMs.
* Build in calibrations of analog outputs with physical devices (i.e. water/laser delivery).
* Add support for controlling video screens. 
