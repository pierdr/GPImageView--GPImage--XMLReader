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
    NSString* mediaURL;
    NSMutableData* mediaData;
    int mediaType;
    int status;
    
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
        [self downloadMediaWithUrl:url andMediaType:IMAGE];
    }
    
}
#pragma mark VIDEO
-(void)playVideo:(NSString*)url{
    if(videoPlayer!=nil)
    {
        [videoPlayer pause];
    }
    if(url!=nil)
    {
        mediaURL = [GPMediaView getUniquePath:url];
    }
    else
    {
        mediaURL = [GPMediaView getUniquePath:mediaURL];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:mediaURL])
    {
        /* --- Set Cached Video --- */
        NSURL* tmpUrl = [NSURL fileURLWithPath:mediaURL];
        if(videoPlayer==nil)
        {
            videoPlayer = [[AVPlayer alloc] initWithURL:tmpUrl];
            _videoLayer = [AVPlayerLayer playerLayerWithPlayer:videoPlayer];
            videoPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
            _videoLayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
            
            //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        }
        else
        {
            [videoPlayer cancelPendingPrerolls];
            AVPlayerItem* itemTmp = [[AVPlayerItem alloc] initWithURL:tmpUrl];
            [videoPlayer replaceCurrentItemWithPlayerItem:itemTmp];
        }
        
        if(![self.layer.sublayers containsObject:_videoLayer])
        {
            [self.layer addSublayer: _videoLayer];
        }
        [videoPlayer play];
    }
    /* --- Download Image from URL --- */
    else
    {
        /* --- Switch to main thread If not in main thread URLConnection wont work --- */
        [self downloadMediaWithUrl:url andMediaType:VIDEO];
    }
}

#pragma mark AUDIO
-(void)playAudio:(NSString*)url andNumLoops:(int)num{
    if(_audioPlayer!=nil)
    {
        [_audioPlayer stop];
    }
    if(url!=nil)
    {
        mediaURL = [GPMediaView getUniquePath:url];
    }
    else
    {
        mediaURL = [GPMediaView getUniquePath:mediaURL];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:mediaURL])
    {
        /* --- Set Cached Video --- */
        NSURL* tmpUrl = [NSURL fileURLWithPath:mediaURL];
        
            _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:tmpUrl
                                                                           error:nil];
            _audioPlayer.numberOfLoops = num; //-1 Infinite
            
            [_audioPlayer play];

        
        
    }
    /* --- Download Image from URL --- */
    else
    {
        /* --- Switch to main thread If not in main thread URLConnection wont work --- */
        [self downloadMediaWithUrl:url andMediaType:AUDIO];
    }
    
        }
#pragma mark GENERAL
-(void)downloadMediaWithUrl:(NSString*)url andMediaType:(int)type
{
    if(status==DOWNLOADING)
    {
        return;
    }
    mediaType = type;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        mediaURL = url;
        
        NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        
        NSURLConnection *con = [[NSURLConnection alloc] initWithRequest:req
                                                               delegate:self
                                                       startImmediately:NO];
        
        [con scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSRunLoopCommonModes];
        
        [con start];
        status = DOWNLOADING;
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
    status = IDLE;
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
    switch (mediaType) {
        case IMAGE:
            /* --- set Image Data --- */
            [self setImage:[UIImage imageWithData:mediaData]];
            
            /* --- Get Cache Image --- */
            if (isCacheImage) {
                [mediaData writeToFile:[GPMediaView getUniquePath:mediaURL]
                            atomically:YES];
            }

            break;
        case VIDEO:
            [mediaData writeToFile:[GPMediaView getUniquePath:mediaURL]
                        atomically:YES];
            [self playVideo:nil];
            break;
        case AUDIO:
            [mediaData writeToFile:[GPMediaView getUniquePath:mediaURL]
                        atomically:YES];
            
            break;
        default:
            break;
    }
    status = IDLE;
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
