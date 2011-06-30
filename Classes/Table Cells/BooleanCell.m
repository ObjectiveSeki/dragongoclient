
#import "BooleanCell.h"


@implementation BooleanCell

@synthesize toggleSwitch;
@synthesize onChanged;

- (id)init {
    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([self class])])) {
        UISwitch *theSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		self.toggleSwitch = theSwitch;
		self.accessoryView = theSwitch;
        [theSwitch addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
		self.selectionStyle = UITableViewCellSelectionStyleNone;
        [theSwitch release];
    }
    return self;
}

- (IBAction)switchToggled:(id)sender {
    if (self.onChanged) {
        self.onChanged(self);
    }
}

- (void)dealloc {
	self.toggleSwitch = nil;
	self.onChanged = nil;
    [super dealloc];
}

@end
