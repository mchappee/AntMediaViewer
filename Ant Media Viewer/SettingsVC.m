//
//  SettingsVC.m
//  AntMedia
//
//  Created by Matthew Chappee on 1/22/22.
//

#import "SettingsVC.h"

@interface SettingsVC ()

@end

@implementation SettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"baseurl"]) {
        self.BaseURL.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"baseurl"];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"About to close");
    NSString *valueToSave = self.BaseURL.text;
    [[NSUserDefaults standardUserDefaults] setObject:valueToSave forKey:@"baseurl"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)TestDown:(id)sender {
    NSURL *createurl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/LiveApp/rest/v2/version", self.BaseURL.text]];
    NSData *data = [NSData dataWithContentsOfURL:createurl];
    
    if (data) {
        self.successfulconn.hidden = false;
        self.failedconn.hidden = true;
    } else {
        self.failedconn.hidden = false;
        self.successfulconn.hidden = true;
    }
}
@end
