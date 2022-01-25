//
//  StreamCell.h
//  AntMedia
//
//  Created by Matthew Chappee on 1/22/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StreamCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *streamname;
@property (weak, nonatomic) IBOutlet UILabel *streamduration;

@end

NS_ASSUME_NONNULL_END
