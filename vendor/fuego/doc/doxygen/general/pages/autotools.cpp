/** @page generalautotools Building Fuego using GNU Autotools

@section generalautotoolsdistro Building from a distribution (released version)

@verbatim
./configure
make
@endverbatim

<tt>./configure --help</tt> returns a full list of options.
If the GCC compiler is used, the optimization level 3 makes Fuego faster
(the default CXXFLAGS on GCC-based systems are usually "-g -O2"). Therefore,
a recommended build configuration would be:

@verbatim
env CXXFLAGS="-g -O3" ./configure
make
@endverbatim

To compile for debugging (no optimization, assertions enabled), use

@verbatim
env CXXFLAGS="-g" ./configure --enable-assert=yes
make
@endverbatim

@section generalautotoolssvn Building a development version checked out from SVN

@verbatim
aclocal
autoheader
autoreconf -i
@endverbatim

The above commands need to be run only initially. Then the compilation works
as in the previous section. After adding or removing files or doing other
changes to <tt>configure.ac</tt> or a <tt>Makefile.am</tt>, you need to run
<tt>autoreconf</tt> again before doing a make. A better way is to configure
your makefiles with <tt>./configure --enable-maintainer-mode</tt>. Then a
make will automatically check, if <tt>configure.ac</tt> or a
<tt>Makefile.am</tt> have changed and recreate the makefiles before the
compilation if necessary.

There is also a script <tt>setup-build.sh</tt> in the root directory that
sets up some commonly used build targets in the subdirectory fuego/build,
such that they can be used in parallel without recreating the build
configuration (using so-called VPATH builds). Simply type <tt>make</tt> in the
according subdirectory. This script can also be used to recreate the makefiles
after changes to <tt>configure.ac</tt> or a <tt>Makefile.am</tt>.

@section generalautotoolsinstall Installing Fuego

After building, the executable is in fuegomain/fuego. It is a GTP engine
that can be used with GUIs like GoGui. Fuego can also be installed on
the system with the following command:

@verbatim
sudo make install
@endverbatim

@section generalautotoolscheck Running tests

The following command compiles and runs the unit tests (and also runs
other tests):

@verbatim
make check
@endverbatim

@section generalautotoolvpath Building debug and release version

Assuming that you want to build a debug and release version in different
directories. This is called a VPATH-build. In this example, we choose
<tt>fuego/build/autotools/debug</tt> and
<tt>fuego/build/autotools/release</tt> as the build directories:
@verbatim
cd fuego
mkdir -p build/autotools/debug
cd build/autotools/debug
env CXXFLAGS=-g ../../../configure --enable-assert --enable-optimize=no

cd ../../../
mkdir -p build/autotools/release
cd build/autotools/release
../../../configure
@endverbatim
Then the command <tt>make</tt> should be run in
<tt>fuego/build/autotools/debug</tt> or
<tt>fuego/build/autotools/release</tt>.

@section generalautotoollinks Further documentation links

- <a href="http://www.freesoftwaremagazine.com/books/autotools_a_guide_to_autoconf_automake_libtool">Autotools: a practitioner's guide to Autoconf, Automake and Libtool</a>
- <a href="http://sources.redhat.com/autobook/autobook/autobook_toc.html">GNU Autoconf, Automake, and Libtool</a>
  (some of the examples are not yet updated to newer versions of Autotools;
  still a useful reference)
- GNU Autotools manuals:
  <a href="http://www.gnu.org/software/automake/manual/html_node/index.html">Automake</a>,
  <a href="http://www.gnu.org/software/autoconf/manual/html_node/index.html">Autoconf</a>,
  <a href="http://www.gnu.org/software/libtool/manual/html_node/index.html">Libtool</a> */

