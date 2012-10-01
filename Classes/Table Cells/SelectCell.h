//
//  SelectCell.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/30/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SelectCell;

@interface SelectCell : UITableViewCell <UIPickerViewDelegate, UIPickerViewDataSource> {
	IBOutlet UILabel *label;
	IBOutlet UILabel *value;
	UIPickerView *picker;
	NSArray *options;
	NSArray *selectedOptions;
	NSArray *sizes;
    UITableView *parentTableView; // weak, temporary reference
	SEL changedSelector;
    int pickerViewHeight;
    int tableViewHeight;
    CGFloat movementOffset;
    void (^onChanged)(SelectCell *selectCell);
}

@property(nonatomic, strong) IBOutlet UILabel *label;
@property(nonatomic, strong) IBOutlet UILabel *value;
@property(nonatomic, strong) UIPickerView *picker;
@property(nonatomic, strong) NSArray *options;
@property(nonatomic, strong) NSArray *selectedOptions;
@property(nonatomic, strong) NSArray *sizes;
@property(nonatomic) SEL changedSelector;
@property(nonatomic, copy) void (^onChanged)(SelectCell *selectCell);

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component;
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component;
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component;
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;

- (NSString *)selectedValueInComponent:(NSInteger)component;

@end
