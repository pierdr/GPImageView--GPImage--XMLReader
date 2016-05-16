//
//  GPMediaView.h
//
//  Created by Gaurav D. Sharma & Piyush Kashyap
//  Modified by Pierluigi Dalla Rosa @binaryfutures
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define AUDIO       1
#define VIDEO       2
#define IMAGE       3
#define IDLE        4
#define DOWNLOADING 5


@interface GPMediaView : UIImageView

@property (nonatomic) BOOL isCacheImage, showActivityIndicator;

@property (nonatomic, strong) UIImage *defaultImage;

/* --- Img from URL --- */
+ (NSString*)getUniquePath:(NSString*)urlStr;

- (void)setImageFromURL:(NSString*)url;

- (void)setImageFromURL:(NSString*)url
  showActivityIndicator:(BOOL)isActivityIndicator
          setCacheImage:(BOOL)cacheImage;

/* --- Vid from URL --- */
@property (nonatomic, strong)   AVPlayer*       videoPlayer;
@property (nonatomic,strong)    AVPlayerLayer*  videoLayer;
-(void)playVideo:(NSString*)url;


/* --- Audio from URL --- */
-(void)playAudio:(NSString*)url;

/* --- Reset --- */
-(void)resetView;


@end
