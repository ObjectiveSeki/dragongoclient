//
//  ExpandingLabelCell.h
//  DGSPhone
//
//  Created by Justin Weiss on 7/15/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExpandingLabelCell : UITableViewCell

+ (CGFloat)heightForString:(NSString *)string width:(CGFloat)width;

@end
