//
//  SettingsVC.h
//  AntMedia
//
//  Created by Matthew Chappee on 1/22/22.
//

#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SettingsVC : ViewController

@property (weak, nonatomic) IBOutlet UITextField *BaseURL;
@property (weak, nonatomic) IBOutlet UILabel *failedconn;
@property (weak, nonatomic) IBOutlet UILabel *successfulconn;
- (IBAction)TestDown:(id)sender;

@end

NS_ASSUME_NONNULL_END
