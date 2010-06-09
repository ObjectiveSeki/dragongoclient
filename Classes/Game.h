//
//  Game.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import	"Stone.h"

@interface Game : NSObject {
	int gameId;
	NSString * sgfUrl;
	NSString * opponent;
	NSString * time;
	StonePlayer color;
}

@property(nonatomic, retain) NSString * sgfUrl;
@property(nonatomic, retain) NSString * opponent;
@property(nonatomic, retain) NSString * time;
@property(nonatomic) int gameId;
@property(nonatomic) StonePlayer color;

- (NSString *)sgfString;
- (void)playMove:(Stone *)move lastMove:(Stone *)move comment:(NSString *)comment;
@end
