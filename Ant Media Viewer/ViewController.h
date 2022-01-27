//
//  ViewController.h
//  AntMedia
//
//  Created by Matthew Chappee on 1/21/22.
//

#import <UIKit/UIKit.h>
#import "StreamCell.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVPlayerViewController.h>

@interface ViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *StreamCollection;
@property (weak, nonatomic) IBOutlet UICollectionView *VoDCollection;
@property (weak, nonatomic) IBOutlet UIButton *LiveAppButon;
@property (weak, nonatomic) IBOutlet UIButton *WebRTCButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *AppSegments;
@property (weak, nonatomic) IBOutlet UIButton *Settings;
@property (weak, nonatomic) IBOutlet UILabel *NoServer;
@property (weak, nonatomic) IBOutlet UIButton *RetrieveSnap;
@property (weak, nonatomic) IBOutlet UIImageView *AddServerImg;
@property (weak, nonatomic) IBOutlet UILabel *URLLabel;
@property (weak, nonatomic) IBOutlet UIImageView *GenericAntBubble;
@property (weak, nonatomic) IBOutlet UIImageView *ScreenShotImg;


- (IBAction)AppSegChange:(id)sender;
- (IBAction)SettingsDown:(id)sender;
- (IBAction)WonderwallDown:(id)sender;
- (IBAction)RetrieveSnapDown:(id)sender;

@property NSArray *streams;
@property NSArray *vod;
@property NSString *baseurl;
@property NSString *streamclass;
@property Boolean avplaying;
@property AVPlayer *avplayer;
@property AVPlayerViewController *controller;
@property long nowplaying;
@property AVPlayerItemVideoOutput *snapshotOutput;
@property UIImage *snapshot;
@property UILabel *snaplabel;

@end

