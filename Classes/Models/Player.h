//
//  Player.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/20/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Player : NSObject <NSCoding>

+ (Player *)currentPlayer;
+ (void)setCurrentPlayer:(Player *)player;

@property (nonatomic, retain) NSNumber *userId;
@property (nonatomic, retain) NSString *ratingStatus;
@property (nonatomic, retain) NSString *handle;
@property (nonatomic, retain) NSString *name;


@property (nonatomic, readonly) BOOL rated;

@end
