//
//  WonderWall.m
//  Ant Media Viewer
//
//  Created by Matthew Chappee on 1/25/22.
//

#import "WonderWall.h"

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
                 blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
                alpha:1.0]

@interface WonderWall ()

@end

@implementation WonderWall

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog([self.streams description]);
    self.wallstreams = [[NSMutableArray alloc] init];
    self.streamarray = [[NSMutableArray alloc] init];
    
    for (id stream in self.streams) {
        NSString *status = [stream objectForKey:@"status"];
        if ([status isEqualToString:@"broadcasting"])
            [self.wallstreams addObject:stream];
    }
    
    // Fill out the rest of the screen with dupes.
    int closest = [self closestNumber:(int)[self.wallstreams count] :3];
    if (closest < [self.wallstreams count])
        closest = closest + 3;
    
    int b = 0;
    for (int a = (int)[self.wallstreams count]; a < closest; a++) {
        [self.wallstreams addObject:self.wallstreams[b]];
        b++;
    }
    
    NSLog(@"Count: %ld Rounded: %i", [self.wallstreams count], (int)round (([self.wallstreams count] / 3)));
    
    int xpos = 0;
    int ypos = 0;
    int a = 0;
    long tag = 0;
    
    CGFloat vidwidth = (self.view.bounds.size.width / 3);
    CGFloat vidheight = (self.view.bounds.size.height / 3);
    
    for (id stream in self.wallstreams) {
        CGRect frame = CGRectMake (ypos, xpos, vidwidth, vidheight );
        ypos = ypos + vidwidth;
        NSLog(@"%@", NSStringFromCGRect (frame));
        
        NSString *streamname = [stream objectForKey:@"streamId"];
        NSString *streamurl = [NSString stringWithFormat:@"%@/%@/streams/%@.m3u8", self.baseurl, self.streamclass, streamname];
        [self.streamarray addObject:streamurl];
        
        //[self createVideo:streamurl:frame:tag];
        AVPlayerViewController *avc = [[AVPlayerViewController alloc] init];
        AVPlayer *avplayer = [AVPlayer playerWithURL:[NSURL URLWithString:streamurl]];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avctapped:)];
        singleTap.numberOfTapsRequired = 1;
        avc.view.tag = tag;
        
        [avc.view setUserInteractionEnabled:YES];
        [avc.view addGestureRecognizer:singleTap];
        
        avc.player = avplayer;
        avc.view.frame = frame;
        
        [self.view addSubview:avc.view];
        [self addChildViewController:avc];
        
        [avplayer play];
        
        a++;
        tag++;
        
        if (a == 3) {
            xpos = xpos + vidheight;
            ypos = 0;
            a = 0;
        }
    }
}

// Credit: https://www.geeksforgeeks.org/find-number-closest-n-divisible-m/
- (int) closestNumber:(int)n :(int)m {

    // find the quotient
    int q = n / m;
     
    // 1st possible closest number
    int n1 = m * q;
     
    // 2nd possible closest number
    int n2 = (n * m) > 0 ? (m * (q + 1)) : (m * (q - 1));
     
    // if true, then n1 is the required closest number
    if (abs(n - n1) < abs(n - n2))
        return n1;
     
    // else n2 is the required closest number
    return n2;
}


- (void) avctapped:(UIGestureRecognizer *)sender {
    
    CGFloat vidwidth = (self.view.bounds.size.width / 1.5);
    CGFloat vidheight = (self.view.bounds.size.height / 1.5);
    int vpos = (self.view.bounds.size.width - vidwidth) / 2;
    int hpos = (self.view.bounds.size.height - vidheight) / 2;
    
    NSString *streamurl = self.streamarray[sender.view.tag];
    NSLog(@"streamurl %@", streamurl);
    
    CGRect frame = CGRectMake (vpos, hpos, vidwidth, vidheight );
    NSLog(@"streamframe: %@", NSStringFromCGRect (frame));
    
    AVPlayerViewController *avc = [[AVPlayerViewController alloc] init];
    AVPlayer *avplayer = [AVPlayer playerWithURL:[NSURL URLWithString:streamurl]];
    [avc.view setUserInteractionEnabled:YES];
    
    avc.player = avplayer;
    //avc.view.frame = frame;
    [self presentViewController:avc animated:YES completion:nil];
    //[self.view addSubview:avc.view];
    //[self addChildViewController:avc];
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    
    UIView *selectedview = context.nextFocusedView;
    UIView *prevselectedview = context.previouslyFocusedView;
    
    self.selectedview = selectedview;
    
    selectedview.layer.borderWidth = 5.0;
    selectedview.layer.borderColor = UIColorFromRGB(0x24682b).CGColor;
    selectedview.layer.shadowColor = [UIColor blackColor].CGColor;

    prevselectedview.layer.borderWidth = 0.0;
    prevselectedview.layer.shadowRadius = 0.0;
    prevselectedview.layer.shadowOpacity = 0;
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
