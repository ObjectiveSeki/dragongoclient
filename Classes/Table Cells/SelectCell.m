//
//  SelectCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/30/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "SelectCell.h"

@interface SelectCell ()
@property(nonatomic, assign) UIColor *oldDetailLabelColor;
@end

@implementation SelectCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        _oldDetailLabelColor = self.detailTextLabel.textColor;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.oldDetailLabelColor = self.detailTextLabel.textColor;
}

- (void)setActive:(BOOL)active {
    _active = active;
    [self tintColorDidChange];
}

- (void)tintColorDidChange {
    if (self.active) {
        self.detailTextLabel.textColor = [self tintColor];
    } else if (self.oldDetailLabelColor) {
        self.detailTextLabel.textColor = self.oldDetailLabelColor;
    }
}

@end
