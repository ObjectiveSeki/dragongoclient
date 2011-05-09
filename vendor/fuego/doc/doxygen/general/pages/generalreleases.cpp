/** @page generalreleases How to make a release

This is a short HOWTO for maintainers how to do a Fuego release.

-# Run <tt>make distcheck</tt> to check that the compilation, the unit tests,
   and a VPATH build work
-# Select a version number for the release. Since version 1.0, Fuego uses
   version numbers of the form x.y in which every major release (new release
   from the SVN trunk) increases x and sets y to 0, and every minor release
   (from a bugfix branch of a major release) increases y.
-# Change the version in the second argument of the AM_INIT_AUTOMAKE macro in
   configure.ac and update the current section header in NEWS
-# Commit the changes
-# Tag the current version.
   Example 1: for release 1.3 in the bugfix branch of version 1.0, the
   command would be:
@verbatim
svn copy  \
https://fuego.svn.sourceforge.net/svnroot/fuego/branches/VERSION_1_FIXES  \
https://fuego.svn.sourceforge.net/svnroot/fuego/tags/VERSION_1_3 \
-m "Tag release 1.3"
@verbatim
@endverbatim
   Example 2: for release 2.0 (a new major release), the command would be:
@verbatim
svn copy  \
https://fuego.svn.sourceforge.net/svnroot/fuego/trunk  \
https://fuego.svn.sourceforge.net/svnroot/fuego/tags/VERSION_2_0 \
-m "Tag release 2.0"
@endverbatim
-# Run <tt>autoreconf -i</tt> in the root directory of Fuego and then
   <tt>make dist</tt>. The file release is now in the current directory
-# If the release is a new major release, create a bugfix branch.
   Example: for release 2.0, the command would be:
@verbatim
svn copy  \
https://fuego.svn.sourceforge.net/svnroot/fuego/trunk  \
https://fuego.svn.sourceforge.net/svnroot/fuego/branches/VERSION_2_FIXES \
-m "Create bugfix branch for version 2"
@endverbatim
-# Change the version in configure.ac to a development version and add a new
   section header in NEWS ("Current development version").
   The version string to be used for untagged development versions from the SVN
   repository is by convention the version of the last release with ".SVN"
   appended (e.g. 2.3.SVN; this indicates an undefined code revision somewhere
   in the SVN repository between release 2.3 and 2.4).
   After a new major release, you need to change the version string in both the
   trunk and the new bugfix branch.
   To distinguish between trunk and bugfix branch, the first development
   version in the bugfix branch has a ".0.SVN" appended (e.g. 3.0.0.SVN to
   distinguish it from undefined revisions in the trunk named 3.0.SVN)
-# Commit the changes.
-# Upload the file release to SourceForge */
