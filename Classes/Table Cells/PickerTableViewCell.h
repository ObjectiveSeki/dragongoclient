//
//  PickerTableViewCell.h
//  DGS
//
//  Created by Justin Weiss on 7/26/17.
//  Copyright © 2017 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PickerTableViewCellDelegate.h"

@class SelectCell;

@interface PickerTableViewCell : UITableViewCell <UIPickerViewDelegate, UIPickerViewDataSource>

@property(nonatomic, strong) IBOutlet UIPickerView *picker;
@property(nonatomic, strong) NSArray *options;
@property(nonatomic, strong) NSArray *sizes;
@property(nonatomic, weak) id<PickerTableViewCellDelegate> delegate;
@property(nonatomic, copy) void (^onChanged)(SelectCell *cell, PickerTableViewCell *pickerCell);

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component;
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component;
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component;
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;

- (NSInteger)selectedRowInComponent:(NSInteger)component;
- (NSString *)selectedValueInComponent:(NSInteger)component;

- (void)setSelectedOptions:(NSArray *)selectedOptions;

// Returns the selected value for single-component pickers

- (NSInteger)selectedRow;
- (NSString *)selectedValue;

@end
