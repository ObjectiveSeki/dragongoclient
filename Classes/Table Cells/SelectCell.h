//
//  SelectCell.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/30/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PickerTableViewCell.h"

@interface SelectCell : UITableViewCell {
}

@property(nonatomic, strong) NSArray *options;
@property(nonatomic, strong) NSArray *selectedOptions;
@property(nonatomic, strong) NSArray *sizes;
@property(nonatomic, assign) BOOL active;
@property(nonatomic, copy) void (^onChanged)(PickerTableViewCell *pickerCell);

@end
