//
//  Game.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import	"Move.h"

@interface Game : NSObject {
	int gameId;
	NSString * sgfUrl;
	NSString * opponent;
	NSString * time;
	MovePlayer color;
}

@property(nonatomic, retain) NSString * sgfUrl;
@property(nonatomic, retain) NSString * opponent;
@property(nonatomic, retain) NSString * time;
@property(nonatomic) int gameId;
@property(nonatomic) MovePlayer color;

- (NSString *)sgfString;
- (void)playMove:(Move *)move lastMove:(Move *)move comment:(NSString *)comment;
@end
