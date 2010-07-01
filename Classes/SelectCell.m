//
//  SelectCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/30/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "SelectCell.h"


@implementation SelectCell

@synthesize label;
@synthesize value;
@synthesize picker;
@synthesize parentView;
@synthesize options;
@synthesize selectedOptions;
@synthesize changedSelector;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

	if (selected && !self.picker) {
		[super setSelected:YES animated:animated];
		self.picker = [[[UIPickerView alloc] initWithFrame:CGRectMake(0, 264, self.parentView.frame.size.width, self.parentView.frame.size.height)] autorelease];
		self.picker.showsSelectionIndicator = YES;
		[[[UIApplication sharedApplication] keyWindow] addSubview:self.picker];
		self.picker.dataSource = self;
		self.picker.delegate = self;
		for(int i = 0; i < [self.selectedOptions count]; i++) {
			int row = [[self.options objectAtIndex:i] indexOfObject:[self.selectedOptions objectAtIndex:i]];
			[self.picker selectRow:row inComponent:i animated:NO];
		}
		// Configure the view for the selected state
	} else {
		[super setSelected:NO animated:animated];
		[self.picker removeFromSuperview];
		self.picker = nil;
	}
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	if (self.changedSelector) {
		[[UIApplication sharedApplication] sendAction:self.changedSelector to:nil from:self forEvent:nil];
	}
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [[self.options objectAtIndex:component] objectAtIndex:row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
	return self.picker.frame.size.width / [self.options count];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
	return 40.0;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return [self.options count];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return [[self.options objectAtIndex:component] count];
}


- (void)dealloc {
	self.label = nil;
	self.value = nil;
	[self.picker removeFromSuperview];
	self.picker = nil;
	self.selectedOptions = nil;
    [super dealloc];
}


@end
