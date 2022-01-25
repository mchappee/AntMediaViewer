//
//  ViewController.m
//  AntMedia
//
//  Created by Matthew Chappee on 1/21/22.
//

#import "ViewController.h"

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
                 blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
                alpha:1.0]

@interface ViewController ()

@end

@implementation ViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //[[self.Settings imageView] setContentMode: UIViewContentModeScaleAspectFit];
    //[self.Settings setbackgroundImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateNormal];
    //[self.Settings setImage:[UIImage imageNamed:stretchImage] forState:UIControlStateNormal];
    
    self.controller = [[AVPlayerViewController alloc] init];
    
    self.StreamCollection.layer.cornerRadius = 10;
    self.VoDCollection.layer.cornerRadius = 10;
    
    self.StreamCollection.delegate = self;
    self.VoDCollection.delegate = self;
    self.StreamCollection.dataSource = self;
    self.VoDCollection.dataSource = self;
    
    self.avplaying = false;
    
    //self.baseurl = @"https://appmonster.org:5443";
    //self.baseurl = @"http://192.168.1.204:5080";
    self.streamclass = @"LiveApp";
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"baseurl"]) {
        self.baseurl = [[NSUserDefaults standardUserDefaults] stringForKey:@"baseurl"];
        [self loadStreams];
    } else
        self.NoServer.hidden = false;
        
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog (@"View Appeared");
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"baseurl"]) {
        self.baseurl = [[NSUserDefaults standardUserDefaults] stringForKey:@"baseurl"];
        self.NoServer.hidden = true;
        [self loadStreams];
        [self.StreamCollection reloadData];
        [self.VoDCollection reloadData];
    } else
        self.NoServer.hidden = false;
}

- (void) loadStreams {
    NSURL *createurl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/rest/v2/broadcasts/list/0/50", self.baseurl, self.streamclass]];
    NSData *data = [NSData dataWithContentsOfURL:createurl];
    if (data)
        self.streams = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    else
        self.streams = nil;
    
    createurl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/rest/v2/vods/list/0/50", self.baseurl, self.streamclass]];
    data = [NSData dataWithContentsOfURL:createurl];
    if (data)
        self.vod = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    else
        self.vod = nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *streamid = @"StreamCell";
    static NSString *vodid = @"VoDCell";
    
    if (collectionView.tag == 30) {
        StreamCell *streamcell = [collectionView dequeueReusableCellWithReuseIdentifier:streamid forIndexPath:indexPath];
        id stream = self.streams[indexPath.item];
        
        streamcell.tag = (indexPath.item + 1000);
        if ([stream objectForKey:@"name"] != [NSNull null])
            streamcell.streamname.text = [stream objectForKey:@"name"];
        else
            streamcell.streamname.text = [stream objectForKey:@"streamId"];
        
        streamcell.streamduration.text = [stream objectForKey:@"type"];
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(StreamTapped:)];
        singleTap.numberOfTapsRequired = 1;
        [streamcell setUserInteractionEnabled:YES];
        [streamcell addGestureRecognizer:singleTap];

        return streamcell;
    }
    
    if (collectionView.tag == 40) {
        
        StreamCell *streamcell = [collectionView dequeueReusableCellWithReuseIdentifier:vodid forIndexPath:indexPath];
        id stream = self.vod[indexPath.item];
        streamcell.tag = (indexPath.item + 2000);
        
        if ([stream objectForKey:@"vodName"] != [NSNull null])
            streamcell.streamname.text = [stream objectForKey:@"vodName"];
        else
            streamcell.streamname.text = [stream objectForKey:@"streamName"];
        
        NSNumber *d = [stream objectForKey:@"duration"];
        NSString *dur = [NSString stringWithFormat:@"%lds",([d integerValue] / 1000)];
        streamcell.streamduration.text = dur;
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(VodTapped:)];
        singleTap.numberOfTapsRequired = 1;
        [streamcell setUserInteractionEnabled:YES];
        [streamcell addGestureRecognizer:singleTap];
        
        return streamcell;
    }
    
    return nil;
}

- (void)VideoSwipedRight:(UISwipeGestureRecognizer*)sender {
    
    if (self.nowplaying > 1999) {
        long index = (self.nowplaying - 2000) + 1;
        if ((index - 1) <= [self.vod count]) {
            NSLog(@"index=%ld count=%ld", index, [self.vod count]);
            self.nowplaying++;
            NSString *streamname = [self.vod[index] objectForKey:@"filePath"];
            NSString *streamurl = [NSString stringWithFormat:@"%@/%@/%@", self.baseurl, self.streamclass, streamname];
            AVPlayer *avplayer = [AVPlayer playerWithURL:[NSURL URLWithString:streamurl]];
            self.controller.player = avplayer;
            [avplayer play];
        }
    } else {
        long index = (self.nowplaying - 1000) + 1;
        if ((index - 1) <= [self.streams count]) {
            NSString *status = [self.streams[index] objectForKey:@"status"];
            if ([status isEqualToString:@"broadcasting"]) {
                NSLog(@"index=%ld count=%ld", index, [self.streams count]);
                self.nowplaying++;
                NSString *streamname = [self.streams[index] objectForKey:@"name"];
                NSString *streamurl = [NSString stringWithFormat:@"%@/%@/streams/%@.m3u8", self.baseurl, self.streamclass, streamname];
                NSLog(@"playing stream %@", streamurl);
                AVPlayer *avplayer = [AVPlayer playerWithURL:[NSURL URLWithString:streamurl]];
                self.controller.player = avplayer;
                [avplayer play];
            }
        }
    }
}

- (void)VideoSwipedLeft:(UISwipeGestureRecognizer*)sender {
    
    if (self.nowplaying > 1999) {
        long index = (self.nowplaying - 2000) - 1;
        if (index >= 0) {
            NSLog(@"l index=%ld count=%ld", index, [self.vod count]);
            self.nowplaying--;
            NSString *streamname = [self.vod[index] objectForKey:@"filePath"];
            NSString *streamurl = [NSString stringWithFormat:@"%@/%@/%@", self.baseurl, self.streamclass, streamname];
            AVPlayer *avplayer = [AVPlayer playerWithURL:[NSURL URLWithString:streamurl]];
            self.controller.player = avplayer;
            [avplayer play];
        }
    } else {
        long index = (self.nowplaying - 1000) - 1;
        if (index >= 0) {
            NSString *status = [self.streams[index] objectForKey:@"status"];
            if ([status isEqualToString:@"broadcasting"]) {
                NSLog(@"l index=%ld count=%ld", index, [self.streams count]);
                self.nowplaying--;
                NSString *streamname = [self.streams[index] objectForKey:@"name"];
                NSString *streamurl = [NSString stringWithFormat:@"%@/%@/streams/%@.m3u8", self.baseurl, self.streamclass, streamname];
                NSLog(@"playing stream %@", streamurl);
                AVPlayer *avplayer = [AVPlayer playerWithURL:[NSURL URLWithString:streamurl]];
                self.controller.player = avplayer;
                [avplayer play];
            }
        }
    }
}

- (void) PlayVideo: (NSString *)streamurl {
    self.avplaying = true;
    AVPlayer *avplayer = [AVPlayer playerWithURL:[NSURL URLWithString:streamurl]];
    //self.controller = [[AVPlayerViewController alloc] init];
    [self presentViewController:self.controller animated:YES completion:nil];
    
    UISwipeGestureRecognizer *swiperight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(VideoSwipedRight:)];
    swiperight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.controller.view setUserInteractionEnabled:YES];
    [self.controller.view addGestureRecognizer:swiperight];
    
    UISwipeGestureRecognizer *swipeleft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(VideoSwipedLeft:)];
    swipeleft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.controller.view setUserInteractionEnabled:YES];
    [self.controller.view addGestureRecognizer:swipeleft];

    self.controller.player = avplayer;
    avplayer.preventsDisplaySleepDuringVideoPlayback = true;
    [avplayer play];

}

- (void)StreamTapped:(UITapGestureRecognizer*)sender {
    if (self.streams) {
        NSString *streamname = [self.streams[sender.view.tag - 1000] objectForKey:@"name"];
        NSString *streamurl = [NSString stringWithFormat:@"%@/%@/streams/%@.m3u8", self.baseurl, self.streamclass, streamname];
        NSLog(@"Playing %@", streamurl);
        self.nowplaying = sender.view.tag;
        [self PlayVideo:streamurl];
    }
}

- (void)VodTapped:(UITapGestureRecognizer*)sender {
    if (self.streams) {
        NSString *streamname = [self.vod[sender.view.tag - 2000] objectForKey:@"filePath"];
        NSString *streamurl = [NSString stringWithFormat:@"%@/%@/%@", self.baseurl, self.streamclass, streamname];
        NSLog(@"Playing %@", streamurl);
        self.nowplaying = sender.view.tag;
        [self PlayVideo:streamurl];
    }
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    
    if (context.nextFocusedView == self.Settings) {
        NSLog(@"Next focused item is the botton");
        self.Settings.layer.borderWidth = 2.0;
        self.Settings.layer.borderColor = UIColorFromRGB(0x24682b).CGColor;
        self.Settings.layer.shadowColor = [UIColor blackColor].CGColor;
    } else {
        self.Settings.layer.borderWidth = 0.0;
        self.Settings.layer.shadowRadius = 0.0;
        self.Settings.layer.shadowOpacity = 0;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context
withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
        
    NSIndexPath *PrevindexPath = context.previouslyFocusedIndexPath;
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:PrevindexPath];
    cell.contentView.layer.borderWidth = 0.0;
    cell.contentView.layer.shadowRadius = 0.0;
    cell.contentView.layer.shadowOpacity = 0;
    
    NSIndexPath *indexPath = context.nextFocusedIndexPath;
    cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.contentView.layer.borderWidth = 2.0;
    cell.contentView.layer.borderColor = UIColorFromRGB(0x24682b).CGColor;
    cell.contentView.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.contentView.layer.shadowRadius = 10.0;
    cell.contentView.layer.shadowOpacity = 0.9;
    cell.contentView.layer.shadowOffset = CGSizeMake(0, 0);
    
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically | UICollectionViewScrollPositionCenteredHorizontally animated:true];
    
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(CGRectGetWidth(collectionView.frame), ((CGRectGetHeight(collectionView.frame)) / 10));
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (collectionView.tag == 30)
        return [self.streams count];
    if (collectionView.tag == 40)
        return [self.vod count];
    
    return 0;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
        
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id)coordinator {
    
    // best call super just in case
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (IBAction)SettingsDown:(id)sender {
    [self performSegueWithIdentifier:@"SettingsSeg" sender:nil];
}

- (IBAction)AppSegChange:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
    NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
    
    switch (selectedSegment) {
        case 0:
            self.streamclass = @"LiveApp";
            [self loadStreams];
            [self.StreamCollection reloadData];
            [self.VoDCollection reloadData];
            break;
        case 1:
            self.streamclass = @"WebRTCApp";
            [self loadStreams];
            [self.StreamCollection reloadData];
            [self.VoDCollection reloadData];
            break;
        case 2:
            // Add support for other apps, maybe.
            break;
    }

}
@end
