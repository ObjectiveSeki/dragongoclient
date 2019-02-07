//
//  TintedLabel.m
//  DGS
//
//  Created by Justin Weiss on 7/28/17.
//  Copyright © 2017 Justin Weiss. All rights reserved.
//

#import "TintedLabel.h"

@interface TintedLabel ()
@property(nonatomic, retain) UIColor *oldTintColor;
@end

@implementation TintedLabel

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.textColor = self.tintColor;
        _oldTintColor = self.tintColor;
    }
    return self;
}

- (void)tintColorDidChange {
    if ([self.textColor isEqual:self.oldTintColor]) {
        self.textColor = self.tintColor;
        self.oldTintColor = self.tintColor;
    }
}

@end
