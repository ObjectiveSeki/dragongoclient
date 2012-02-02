//
//  DbHelper.h
//  DGSPhone
//
//  Created by adam miller on 11/24/11.
//

#import <Foundation/Foundation.h>

#import "GameServerProtocol.h"

@interface DbHelper : NSObject

+ (void)loadUnknownSGF:(id<GameServerProtocol>)gs;
+ (void)setGameTheirTurn:(int)gameId;
+ (void)setAllTheirTurn;
+ (Game *)gameFromResults:(sqlite3_stmt *)stmt;
+ (Game *)gameFromId:(int)gameId;

@end
