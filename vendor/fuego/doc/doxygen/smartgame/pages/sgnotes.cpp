/** @page sgnotes Notes for the SmartGame Library

@section sgnotessystem System Header

SgSystem.h includes platform-dependent macros. To ensure a consistent global
definition of these macros, SgSystem.h should be included as the first include
file in every cpp file, but not in any header file.

@section sgnotesinit Initialization

SgInit() / SgFini() must be called before / after using any classes to
initialize global variables. */

