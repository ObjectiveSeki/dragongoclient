#define CACHING 1

#if defined (CONFIGURATION_Debug)
#define DEBUG 1
//#define DEVELOPMENT_DGS
#define PUSH_ENABLED
#define PUSH_HOST @"dgs.uberweiss.net:3000"
#define PUSH_USE_SSL NO
#define REMOTE_LOGGING
//#define INVITES_ENABLED

// set to '1' to see SGFs that test various aspects of
// the board view.
//#define TEST_GAMES 1
#endif

#if defined (CONFIGURATION_Adhoc)
#define TESTFLIGHT_UUID_TRACKING
#define PUSH_ENABLED
#define PUSH_HOST @"dgs.uberweiss.net"
#define PUSH_USE_SSL YES
#define REMOTE_LOGGING
#endif

#if defined (CONFIGURATION_Release)
#define PUSH_ENABLED
#define PUSH_HOST @"dgs.uberweiss.net"
#define PUSH_USE_SSL YES
#endif

#ifdef DEVELOPMENT_DGS
#	define SERVER_CLASS @"DGSDev"
#else
#	define SERVER_CLASS @"DGS"
#endif

#ifdef CACHING
#   import "CachingGameServer.h"
#   define GenericGameServer CachingGameServer
#else
#   define GenericGameServer NSClassFromString(SERVER_CLASS)
#endif

#if defined (CONFIGURATION_Release)
#define NSLog(...)
#endif

#define S(fmt, ...) [NSString stringWithFormat:(fmt), ##__VA_ARGS__]
