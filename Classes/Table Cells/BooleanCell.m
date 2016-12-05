
#import "BooleanCell.h"


@implementation BooleanCell

- (id)init {
    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([self class])])) {
        [self awakeFromNib];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    UISwitch *theSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    self.toggleSwitch = theSwitch;
    self.accessoryView = theSwitch;
    [theSwitch addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (IBAction)switchToggled:(id)sender {
    if (self.onChanged) {
        self.onChanged(self);
    }
}


@end
