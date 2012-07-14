//
//  CachingGameServer.h
//  DGSPhone
//
//  Wraps a class that conforms to the GameServerProtocol, but provides local
//  caching of games and moves to reduce network activity and enable offline
//  play.
//

#import <Foundation/Foundation.h>
#import "GameServerProtocol.h"

@interface CachingGameServer : NSObject<GameServerProtocol>

@property(nonatomic, retain) id<GameServerProtocol> gameServer;

- (id)initWithGameServer:(id<GameServerProtocol>)aGameServer;

// Creates the database (if necessary) representing the cache store, 
// and opens the connection. This must be called before calling any other
// methods on this class.
+ (void)checkAndCreateDatabase;

// Closes the database connection. This should be called before the app closes.
+ (void)closeDatabase;

@end
