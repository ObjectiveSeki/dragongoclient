
#ifdef __OBJC__
    #import "TestFlight.h"
    #import "Keys.h"
#endif

#define CACHING 1

#if defined (CONFIGURATION_Debug)
#define DEBUG 1
#define DEVELOPMENT_DGS
#define PUSH_ENABLED
#define PUSH_HOST @"192.168.0.8:3000"

// set to '1' to see SGFs that test various aspects of
// the board view.
//#define TEST_GAMES 1
#endif

#if defined (CONFIGURATION_Adhoc)
#define TESTFLIGHT_UUID_TRACKING
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

// Wrap TestFlight calls in TF() to only call them when TestFlight keys are set
#ifdef TESTFLIGHT_APP_TOKEN
#   define TF(testflight_call) { (testflight_call); }
#   define NSLog(__FORMAT__, ...) TFLog((@"%s [Line %d] " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   warning You must define TestFlight app tokens in Keys.h to get TestFlight functionality.
#   define TF(...)
#endif

#define S(fmt, ...) [NSString stringWithFormat:(fmt), ##__VA_ARGS__]
