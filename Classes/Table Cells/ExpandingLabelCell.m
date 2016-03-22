//
//  ExpandingLabelCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 7/15/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "ExpandingLabelCell.h"

#define MARGIN_X 20
#define MARGIN_Y 12

@implementation ExpandingLabelCell

- (void)layoutSubviews {
    CGRect textLabelBounds = self.textLabel.bounds;
    textLabelBounds.size.height = [[self class] heightForString:self.textLabel.text width:self.bounds.size.width] - (2 * MARGIN_Y);
    self.textLabel.bounds = textLabelBounds;
    [super layoutSubviews];
}

+ (CGFloat)heightForString:(NSString *)string width:(CGFloat)width {
    CGRect rect = [string boundingRectWithSize:CGSizeMake(width - 2 * MARGIN_X, 1000)
                                       options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                    attributes:nil
                                       context:nil];
    return rect.size.height + 2 * MARGIN_Y;
}

@end
