//
//  TintedLabel.m
//  DGS
//
//  Created by Justin Weiss on 7/28/17.
//  Copyright © 2017 Justin Weiss. All rights reserved.
//

#import "TintedLabel.h"

@implementation TintedLabel

- (void)layoutSubviews {
    [self tintColorDidChange];
}

- (void)tintColorDidChange {
    self.textColor = self.tintColor;
}

@end
