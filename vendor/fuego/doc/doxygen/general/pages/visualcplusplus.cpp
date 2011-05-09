/** @page generalvisualcplusplus Building Fuego with Visual C++

    @section generalvisualcplusplussupport Support for Visual C++

    Recent versions of Fuego should compile with Visual C++. However,
    currently the compilation with Visual C++ is not regularly tested.

    @section generalvisualcplusplusproject How to create a project file

    Here is how to create a Visual C++ project for Fuego. It assumes that
    Visual C++ is installed on your system.

    -# Check out the Fuego code from SVN. On Windows,
    <a href="http://tortoisesvn.tigris.org/">TortoiseSVN</a> is an excellent
    SVN client.
	-# Determine whether you want to compile Fuego for a 32-bit or 64-bit system.
	The Fuego source code can be compiled for either version, but will require either the 32-bit
	or 64-bit version of the Boost Libraries depending on which one you choose.
    -# Download the <a href="http://www.boost.org/">Boost Libraries</a> and compile the desired version
	(32-bit or 64-bit) with Visual C++. (Alternatively you may be able to download a pre-compiled package from
	<a href="http://boost.teeks99.com/">Thomas Kent's site</a>)
    For example, with Boost version 1.45, download and unpack
    @c boost_1_45_0.7z from
    http://sourceforge.net/projects/boost/files/boost/1.45.0/ . For the 32-bit version compile it from a CMD prompt
    with
    @verbatim
    bootstrap
    .\bjam @endverbatim
    This should create static libraries, for example:
    @verbatim
    boost_1_45_0\bin.v2\libs\thread\build\msvc-10.0\release\link-static\threading-multi\libboost_thread-vc100-mt-gd-1_45.lib @endverbatim
	For the 64-bit version, compile it from a CMD prompt
	with
	@verbatim
	bjam --toolset=msvc-10.0 address-model=64 --build-type=complete @endverbatim
    -# Create a new solution named Fuego with Visual C++. The type should be:
    Console Application from existing files. Add all header and cpp files from
    the subdirectories @c gtpengine, @c smartgame, @c go, @c gouct and
    @c fuegomain by dragging and dropping them into the solution explorer
    window (you might want to create subfolders in the solution explorer for
    the different Fuego libraries for better organization).
	-# Select the platform you want to use (32-bit or 64-bit) for your build from the Build->Configuration Manager...
	menu.  It may be necessary to create a new x64 platform option using the dropdown box.
    -# Add the directories @c gtpengine, @c smartgame, @c go, @c gouct from
    the Fuego source directory to Additional Include Directories in the
    Project properties (right click on the project in the solution explorer
    to get to the Project properties).
    -# Add the subdirectories for all necessary boost libraries to
    Additional Linker Libraries in the project properties. This needs to
    be done differently for Debug and Release configuration.
    -# Copy @c fuego/book/book.dat to the Debug and Release subdirectories
    of the project directory.
    -# If you are compiling as a 32-bit program you may want to set the /LARGEADDRESSAWARE flag to YES.  This allows up to
	~3.5 GB of memory usage (as opposed to 2 GB) and can be found under Project Properties-> Configuration Properties->Linker->System->Enable Large Addresses.
    -# You should now be able to compile Fuego and use it in GoGui by
    attaching the executable Fuego.exe in the project build directory.

    @section generalvisualcplusplusmisc Other hints

    -# Enable Insert Spaces in the Tab Settings of the editor in the project
    settings (see @ref generalstyle).
    -# Enable additional optimization options for the release version:
    Maximize Speed, Favor fast code, Whole program optimization
*/

