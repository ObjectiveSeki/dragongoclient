//
//  Player.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/20/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import "Player.h"

@implementation Player

+ (Player *)currentPlayer {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"currentPlayer"]];
}

+ (void)setCurrentPlayer:(Player *)player {
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:player]
                                              forKey:@"currentPlayer"];
}

- (BOOL)rated {
    return ([self.ratingStatus isEqualToString:@"RATED"] || [self.ratingStatus isEqualToString:@"INIT"]);
}

- (void)encodeWithCoder:(NSCoder *)encoder 
{
    [encoder encodeObject:self.userId forKey:@"userId"];
    [encoder encodeObject:self.ratingStatus forKey:@"ratingStatus"];
    [encoder encodeObject:self.handle forKey:@"handle"];
    [encoder encodeObject:self.name forKey:@"name"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    self = [super init];
    if (self) {
        self.userId = [decoder decodeObjectForKey:@"userId"];
        self.ratingStatus = [decoder decodeObjectForKey:@"ratingStatus"];
        self.handle = [decoder decodeObjectForKey:@"handle"];
        self.name = [decoder decodeObjectForKey:@"name"];
    }
    return self;
}

@end
