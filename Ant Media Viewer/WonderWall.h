//
//  WonderWall.h
//  Ant Media Viewer
//
//  Created by Matthew Chappee on 1/25/22.
//

#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WonderWall : ViewController

@property UIView *selectedview;
@property NSMutableArray *streamarray;
@property NSMutableArray *wallstreams;
@property NSMutableArray *avplayers;
@property NSTimer *timer;

@end

NS_ASSUME_NONNULL_END
