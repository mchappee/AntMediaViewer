//
//  ViewController.m
//  AntMedia
//
//  Created by Matthew Chappee on 1/21/22.
//

#import "ViewController.h"
#import "AppDelegate.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en1"
#define IOS_ETH         @"en0"
//#define IOS_VPN       @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

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
        
    self.controller = [[AVPlayerViewController alloc] init];
    
    self.StreamCollection.layer.cornerRadius = 10;
    self.VoDCollection.layer.cornerRadius = 10;
    self.RetrieveSnap.hidden = true;
    
    self.StreamCollection.delegate = self;
    self.VoDCollection.delegate = self;
    self.StreamCollection.dataSource = self;
    self.VoDCollection.dataSource = self;
    
    self.avplaying = false;
    
    self.streamclass = @"LiveApp";
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"baseurl"]) {
        self.baseurl = [[NSUserDefaults standardUserDefaults] stringForKey:@"baseurl"];
        [self loadStreams];
    } else {
        self.AddServerImg.hidden = false;
        
    }
        
    
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog (@"View Appeared");
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"baseurl"]) {
        self.baseurl = [[NSUserDefaults standardUserDefaults] stringForKey:@"baseurl"];
        self.NoServer.hidden = true;
        [self loadStreams];
        [self.StreamCollection reloadData];
        [self.VoDCollection reloadData];
        self.AddServerImg.hidden = true;
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
    
    NSMutableArray *wallstreams = [[NSMutableArray alloc] init];
    for (id stream in self.streams) {
        NSString *status = [stream objectForKey:@"status"];
        if ([status isEqualToString:@"broadcasting"])
            [wallstreams addObject:stream];
    }
    
    self.streams = wallstreams;
    [self.StreamCollection reloadData];
    
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
        long currentindex = (self.nowplaying - 2000);
        long nextindex = currentindex + 1;
        if (nextindex < [self.vod count]) {
            //NSLog(@"index=%ld count=%ld", nextindex, [self.vod count]);
            self.nowplaying++;
            NSString *streamname = [self.vod[nextindex] objectForKey:@"filePath"];
            NSString *streamurl = [NSString stringWithFormat:@"%@/%@/%@", self.baseurl, self.streamclass, streamname];
            AVPlayer *avplayer = [AVPlayer playerWithURL:[NSURL URLWithString:streamurl]];
            self.controller.player = avplayer;
            [avplayer play];
        }
    } else {
        long currentindex = (self.nowplaying - 1000);
        long nextindex = currentindex + 1;
        if (nextindex < [self.streams count]) {
            //NSLog(@"index=%ld count=%ld nowplaying=%ld", index, [self.streams count], self.nowplaying);
            NSString *status = [self.streams[nextindex] objectForKey:@"status"];
            if ([status isEqualToString:@"broadcasting"]) {
                
                self.nowplaying++;
                NSString *streamname = [self.streams[nextindex] objectForKey:@"streamId"];
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
            avplayer.preventsDisplaySleepDuringVideoPlayback = true;
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
                avplayer.preventsDisplaySleepDuringVideoPlayback = true;
                [avplayer play];
            }
        }
    }
}

- (void) PlayVideo: (NSString *)streamurl {
    self.avplaying = true;
    self.avplayer = [AVPlayer playerWithURL:[NSURL URLWithString:streamurl]];
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

    UITapGestureRecognizer *plusbutton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(snapshotbuttondown:)];
    plusbutton.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypePlayPause]];
    [self.controller.view addGestureRecognizer:plusbutton];
    
    self.controller.player = self.avplayer;
    self.avplayer.preventsDisplaySleepDuringVideoPlayback = true;
    self.snapshotOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:NULL];
    [self.avplayer.currentItem addOutput:self.snapshotOutput];
    [self.avplayer play];

}


- (void) removeOverlay {
    [self.snaplabel removeFromSuperview];
}
    
- (void) snapshotbuttondown:  (UIGestureRecognizer *)sender {
    UIImage *image = nil;
    image = [self takeSnapshot];
    self.snaplabel = [[UILabel alloc] init];
    CGRect frame = CGRectMake(200, 200, 1000, 200);
    //UIFont(name:"ArialRoundedMTBold", size: 20.0)
    [self.snaplabel setFont:[UIFont fontWithName:@"Hiragino Sans W3" size:100]];
    self.snaplabel.frame = frame;
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(removeOverlay) userInfo:nil repeats:false];
    
    if (image) {
        AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        ad.screenshot = image;
        
        NSString *ip = [self getIPAddress2:true];
        self.URLLabel.text = [NSString stringWithFormat:@"You have a Screen Shot!  You can download it by pointing a web browser at: http://%@:8080", ip];
        self.URLLabel.hidden = false;
        [self.ScreenShotImg setImage:image];
        self.ScreenShotImg.hidden = false;
        
        self.snaplabel.text = @"Snapshot Taken";
        [self.controller.contentOverlayView addSubview:self.snaplabel];
        NSLog(@"stream got image");
        NSError *error;
        NSURL *mp3path = [[NSBundle mainBundle] URLForResource:@"camera" withExtension:@"mp3"];
        AVAudioPlayer *cam = [[AVAudioPlayer alloc] initWithContentsOfURL:mp3path  error:&error];
        if (error)
            NSLog(@"stream error %@", [error description]);
        
        self.RetrieveSnap.hidden = false;
        [cam prepareToPlay];
        [cam play];
        self.snapshot = image;
    } else {
        self.snaplabel.text = @"Snapshot Failed";
        [self.controller.contentOverlayView addSubview:self.snaplabel];
        
    }
    
}

- (UIImage *)takeSnapshot {
    
    CMTime time = [self.snapshotOutput itemTimeForHostTime:CACurrentMediaTime()];
    if ([self.snapshotOutput hasNewPixelBufferForItemTime:time]) {
        CVPixelBufferRef lastSnapshotPixelBuffer = [self.snapshotOutput copyPixelBufferForItemTime:time itemTimeForDisplay:NULL];
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:lastSnapshotPixelBuffer];
        CIContext *context = [CIContext contextWithOptions:NULL];
        CGRect rect = CGRectMake(0,
                                0,
                                CVPixelBufferGetWidth(lastSnapshotPixelBuffer),
                                CVPixelBufferGetHeight(lastSnapshotPixelBuffer));
        CGImageRef cgImage = [context createCGImage:ciImage fromRect:rect];
        return [UIImage imageWithCGImage:cgImage];
    }
        
    return nil;
}

- (void)StreamTapped:(UITapGestureRecognizer*)sender {
    if (self.streams) {
        NSString *streamname = [self.streams[sender.view.tag - 1000] objectForKey:@"streamId"];
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

- (IBAction)RetrieveSnapDown:(id)sender {
    [self performSegueWithIdentifier:@"ssseg" sender:nil];
}

- (IBAction)WonderwallDown:(id)sender {
    [self performSegueWithIdentifier:@"wallseg" sender:nil];
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

- (NSString *)getIPAddress {

    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];

                }

            }

            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;

}

- (NSString *)getIPAddress2:(BOOL)preferIPv4 {
        NSArray *searchArray = preferIPv4 ?
                                @[ IOS_ETH @"/" IP_ADDR_IPv4, IOS_ETH @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
                                @[ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;

        NSDictionary *addresses = [self getIPAddresses];
        NSLog(@"addresses: %@", addresses);

        __block NSString *address;
        [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
            {
                address = addresses[key];
                if(address) *stop = YES;
            } ];
        return address ? address : @"0.0.0.0";
    }

    - (NSDictionary *)getIPAddresses
    {
        NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];

        // retrieve the current interfaces - returns 0 on success
        struct ifaddrs *interfaces;
        if(!getifaddrs(&interfaces)) {
            // Loop through linked list of interfaces
            struct ifaddrs *interface;
            for(interface=interfaces; interface; interface=interface->ifa_next) {
                if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                    continue; // deeply nested code harder to read
                }
                const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
                char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
                if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                    NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                    NSString *type;
                    if(addr->sin_family == AF_INET) {
                        if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                            type = IP_ADDR_IPv4;
                        }
                    } else {
                        const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                        if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                            type = IP_ADDR_IPv6;
                        }
                    }
                    if(type) {
                        NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                        addresses[key] = [NSString stringWithUTF8String:addrBuf];
                    }
                }
            }
            // Free memory
            freeifaddrs(interfaces);
        }
        return [addresses count] ? addresses : nil;
    }
@end
