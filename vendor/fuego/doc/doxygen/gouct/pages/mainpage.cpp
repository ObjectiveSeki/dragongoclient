/** @mainpage

    @section gouctoverview Overview

    The GoUct library contains a Monte-Carlo tree search Go player based on
    class SgUctSearch from the SmartGame library. Important classes are:
    - GoUctSearch - Derived from SgUctSearch; implements the basic game state
      functions of SgUctSearch for the game of Go.
    - GoUctGlobalSearch - Derived from GoUctSearch; this is the actual search
      engine; the playout policy can be configured as a template parameter.
    - GoUctPlayer - The player; the search can be configured as a template
      parameter; the main Fuego engine uses this player with GoUctGlobalSearch
      as the search and GoUctPlayoutPolicy as the playout policy.

    @section gouctdependencies Dependencies

    - %GtpEngine
    - SmartGame
    - Go
  
    @section gouctdocumentation Documentation

    - @ref gouctgtpcommands "GTP Commands (from GoUctCommands)"
    - @ref gouctbookbuildergtpcommands "GTP Commands (from
      GoUctBookBuilderCommands)" */

