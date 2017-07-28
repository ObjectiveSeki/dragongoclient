//
//  PickerTableViewCell.m
//  DGS
//
//  Created by Justin Weiss on 7/26/17.
//  Copyright © 2017 Justin Weiss. All rights reserved.
//

#import "PickerTableViewCell.h"

@implementation PickerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setOptions:(NSArray *)options {
    if (_options != options) {
        _options = options;
        [self.picker reloadAllComponents];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [self.delegate pickerTableViewCell:self didSelectRow:row inComponent:component];
}

- (void)setSelectedOptions:(NSArray *)selectedOptions {
    for(int i = 0; i < [selectedOptions count]; i++) {
        NSUInteger row = [(self.options)[i] indexOfObject:(selectedOptions)[i]];
        [self.picker selectRow:row inComponent:i animated:NO];
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return (self.options)[component][row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    CGFloat size;
    if (self.sizes) {
        size = [(self.sizes)[component] floatValue];
    } else {
        size = self.picker.frame.size.width / [self.options count];
    }
    return size;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 40.0;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return [self.options count];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [(self.options)[component] count];
}

- (NSInteger)selectedRowInComponent:(NSInteger)component {
    return [self.picker selectedRowInComponent:component];
}

- (NSString *)selectedValueInComponent:(NSInteger)component {
    return (self.options)[component][[self.picker selectedRowInComponent:component]];
}

- (NSInteger)selectedRow {
    NSAssert([self numberOfComponentsInPickerView:self.picker] == 1, @"Trying to use selectedRow on a multi-component UIPickerView.");
    return [self selectedRowInComponent:0];
}

- (NSString *)selectedValue {
    NSAssert([self numberOfComponentsInPickerView:self.picker] == 1, @"Trying to use selectedValue on a multi-component UIPickerView.");
    return [self selectedValueInComponent:0];
}
@end
