//
//  PickerTableViewCellDelegate.h
//  DGSPhone
//
//  Created by Justin Weiss on 7/27/17.
//  Copyright © 2017 Justin Weiss. All rights reserved.
//

#ifndef PickerTableViewCellDelegate_h
#define PickerTableViewCellDelegate_h

@class PickerTableViewCell;

@protocol PickerTableViewCellDelegate <NSObject>

- (void)pickerTableViewCell:(PickerTableViewCell *)pickerCell didSelectRow:(NSInteger)row inComponent:(NSInteger)component;

@end

#endif /* PickerTableViewCellDelegate_h */
