//
//  GPMediaView.m
//
//  Created by Gaurav D. Sharma & Piyush Kashyap
//  Modified by Pierluigi Dalla Rosa @binaryfutures
//
//

#import "GPMediaView.h"


#define TMP NSTemporaryDirectory()

@implementation GPMediaView
{
    //NSMutableData *mediaData;
    
    //NSMutableData *videoData;
    //NSMutableData *audioData;
    
   /* NSString *mediaURL;
    
    NSString *videoURL;
    NSString *audioURL;*/
    NSString* mediaURL;
    NSMutableData* mediaData;
    
}
@synthesize isCacheImage, showActivityIndicator;

@synthesize defaultImage, videoPlayer;

+ (NSString*)getUniquePath:(NSString*)  urlStr
{
    NSMutableString *tempImgUrlStr = [NSMutableString stringWithString:[urlStr substringFromIndex:7]];
    
    [tempImgUrlStr replaceOccurrencesOfString:@"/" withString:@"-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [tempImgUrlStr length])];
    
    // Generate a unique path to a resource representing the image you want
    NSString *filename = [NSString stringWithFormat:@"%@",tempImgUrlStr] ;
    
    // [[something unique, perhaps the image name]];
    NSString *uniquePath = [TMP stringByAppendingPathComponent: filename];
    
    return uniquePath;
}
#pragma mark IMAGE
- (void)setImageFromURL:(NSString*)url
{
    [self setImageFromURL:url
    showActivityIndicator:showActivityIndicator
            setCacheImage:isCacheImage];
}


- (void)setImageFromURL:(NSString*)url
  showActivityIndicator:(BOOL)isActivityIndicator
          setCacheImage:(BOOL)cacheImage
{
    
    mediaURL = [GPMediaView getUniquePath:url];
    
    showActivityIndicator = isActivityIndicator;
    
    isCacheImage = cacheImage;
    
    if (isCacheImage && [[NSFileManager defaultManager] fileExistsAtPath:mediaURL])
    {
        /* --- Set Cached Image --- */
        mediaData = [[NSMutableData alloc] initWithContentsOfFile:mediaURL];
        
        [self setImage:[[UIImage alloc] initWithData:mediaData]];
        
    }
    /* --- Download Image from URL --- */
    else
    {
        if (showActivityIndicator) {
            
            UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            
            activityIndicator.tag = 786;
            
            [activityIndicator startAnimating];
            
            [activityIndicator setHidesWhenStopped:YES];
            
            CGRect myRect = self.frame;
            
            CGRect newRect = CGRectMake(myRect.size.width/2 -12.5f,myRect.size.height/2 - 12.5f, 25, 25);
            
            [activityIndicator setFrame:newRect];
            
            [self addSubview:activityIndicator];
            
        }
        
        /* --- set Default image Until Image will not load --- */
        if (defaultImage) {
            [self setImage:defaultImage];
        }
        
        /* --- Switch to main thread If not in main thread URLConnection wont work --- */
        [self downloadMediaWithUrl:mediaURL];
    }
    
}
#pragma mark VIDEO
-(void)playVideo:(NSString*)url{
    if(videoPlayer==nil)
    {
        videoPlayer=[[AVPlayer alloc]init];
    }
    else
    {
        [videoPlayer pause];
    }
    
    mediaURL = [GPMediaView getUniquePath:url];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:mediaURL])
    {
        /* --- Set Cached Video --- */
        NSURL* tmpUrl = [NSURL fileURLWithPath:mediaURL];
        videoPlayer = [videoPlayer initWithURL:tmpUrl];
        _videoLayer = [AVPlayerLayer playerLayerWithPlayer:videoPlayer];
        videoPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        _videoLayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        [self.layer addSublayer: _videoLayer];
        
        [videoPlayer play];
    }
    /* --- Download Image from URL --- */
    else
    {
        /* --- Switch to main thread If not in main thread URLConnection wont work --- */
        [self downloadMediaWithUrl:mediaURL];
    }
}
#pragma mark AUDIO
-(void)playAudio:(NSString*)url{
    
}
#pragma mark GENERAL
-(void)downloadMediaWithUrl:(NSString*)url
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        mediaURL = url;
        
        NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        
        NSURLConnection *con = [[NSURLConnection alloc] initWithRequest:req
                                                               delegate:self
                                                       startImmediately:NO];
        
        [con scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSRunLoopCommonModes];
        
        [con start];
        
        if (con) {
            mediaData = [NSMutableData new];
        }
        else {
            NSLog(@"GPImageView Image Connection is NULL");
        }
    });
}

#pragma mark - NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [mediaData setLength:0];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [mediaData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    NSLog(@"Error downloading");
    
    mediaData = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    /* --- hide activity indicator --- */
    if (showActivityIndicator)
    {
        UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[self viewWithTag:786];
        
        [activityIndicator stopAnimating];
        
        [activityIndicator removeFromSuperview];
    }
    
    /* --- set Image Data --- */
    [self setImage:[UIImage imageWithData:mediaData]];
    
    /* --- Get Cache Image --- */
    if (isCacheImage) {
        [mediaData writeToFile:[GPMediaView getUniquePath:mediaURL]
                    atomically:YES];
    }
    
    mediaData = nil;
    
}
#pragma mark RESET
-(void)resetView{
    self.image = nil;
    [videoPlayer pause];
    [_videoLayer removeFromSuperlayer];
    
    [self setNeedsDisplay];
   
}

@end
