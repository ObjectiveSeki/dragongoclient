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

@property(nonatomic, strong) id<GameServerProtocol> gameServer;

- (id)initWithGameServer:(id<GameServerProtocol>)aGameServer;

@end
