//
//  SelectCell.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/30/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SelectCell : UITableViewCell <UIPickerViewDelegate, UIPickerViewDataSource> {
	IBOutlet UILabel *label;
	IBOutlet UILabel *value;
	UIPickerView *picker;
	NSArray *options;
	NSArray *selectedOptions;
	NSArray *sizes;
	SEL changedSelector;
}
@property(nonatomic, retain) IBOutlet UILabel *label;
@property(nonatomic, retain) IBOutlet UILabel *value;
@property(nonatomic, retain) UIPickerView *picker;
@property(nonatomic, retain) NSArray *options;
@property(nonatomic, retain) NSArray *selectedOptions;
@property(nonatomic, retain) NSArray *sizes;
@property(nonatomic) SEL changedSelector;

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component;
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component;
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component;
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;

- (NSString *)selectedValueInComponent:(NSInteger)component;

@end
