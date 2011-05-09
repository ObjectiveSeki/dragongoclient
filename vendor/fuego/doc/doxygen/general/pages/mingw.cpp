/** @page generalmingw Building Fuego with MinGW

    @section generalmingwsupport Support for MinGW

    Recent versions of Fuego can be compiled with
    <a href="http://www.mingw.org">MinGW</a> on Windows.
    Currently, using MinGW is the best option for building a high-performance
    Windows version of Fuego, because the version compiled with Visual C++
    is about 15 percent slower.
    
    Using <a href="http://www.cygwin.com">Cygwin</a> instead of MinGW is
    another option, but there are currently bugs in the Boost libraries if
    built with Cygwin that make pondering and the automatic detection of
    number of cores not work in the Cygwin version of Fuego (last tested
    with Cygwin GCC version 3.4.4).

    @section generalmingwcompile How to compile Fuego with MinGW

    Here are the necessary steps to compile Fuego with MinGW. There are some
    workarounds for problems that may not be necessary in future versions
    of MinGW. The version used were MinGW GCC version 4.5.0 and Boost 1.45.0.
    
    -# Check out the Fuego code from SVN or download a distribution of Fuego.
    On Windows, <a href="http://tortoisesvn.tigris.org/">TortoiseSVN</a> is
    an excellent SVN client. 
	-# Determine whether you want to compile Fuego for a 32-bit or 64-bit system.
	The Fuego source code can be compiled for either version, but will require either the 32-bit
	or 64-bit versions of the Boost Libraries and MinGW depending on which one you choose.
    -# Install MinGW and MSYS using the MinGW installer. (For 64-bit you will need <a href="http://mingw-w64.sourceforge.net/">MinGW-w64</a>, but this is not yet tested)
    -# Download the source for the <a href="http://www.boost.org/">Boost
    libraries</a> and (if not already included in the Boost download) a pre-compiled version of BJam (e.g. 
    boost-jam-3.1.18-1-ntx86.zip). Unpack the files and copy bjam.exe in the
    Boost source directory.
    -# Compile Boost with MinGW in the MSYS shell with the following command
    (this compiles only the libraries used by Fuego):
    @verbatim
    bjam.exe --toolset=gcc --layout=tagged --with-thread \
      --with-program_options --with-filesystem --with-system \
      --with-date_time --with-test --prefix=/usr install @endverbatim
    This should create static libraries, for example:
    @verbatim
    /usr/lib/libboost_thread-mt.a @endverbatim
    -# Compile Fuego in the MSYS shell.  Note that if you are compiling as a 32-bit program you may want to set the /LARGEADDRESSAWARE flag to YES. This allows up to
	~3.5 GB of memory usage (as opposed to 2 GB) and can be done by adding 
	@verbatim
	LDFLAGS="-Wl,--large-address-aware" @endverbatim
	between env and CXXFLAGS below.
    @verbatim
    cd fuego
    mkdir mingw
    cd mingw
    env CXXFLAGS="-O3 -ffast-math -DBOOST_THREAD_USE_LIB -static-libgcc -static-libstdc++" \
      ../configure \
      --with-boost-thread=boost_thread-mt \
      --with-boost-program-options=boost_program_options-mt \
      --with-boost-date-time=boost_date_time-mt \
      --with-boost-filesystem=boost_filesystem-mt \
      --with-boost-system=boost_system-mt \
      --with-boost-unit-test-framework=boost_unit_test_framework-mt
    make @endverbatim
    The explicit boost library options are currently necessary because the automatic
    detection of the library fails. The macro BOOST_THREAD_USE_LIB is a workaround
    for a compilation problem with Boost 1.45.0 that may not be necessary in the future.
    This should create an executable named fuegomain/fuego.exe.
    -# Copy the file fuego/book/book.dat into the directory of fuego.exe
*/

