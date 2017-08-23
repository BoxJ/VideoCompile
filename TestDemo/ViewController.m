//
//  ViewController.m
//  TestDemo
//
//  Created by jingliang on 2017/8/11.
//  Copyright © 2017年 井良. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"------>%@",[NSDate date]);
    AVAsset *_videoAsset=[AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"1234" ofType:@"mp4"]]];
    //创建AVMutableComposition
    AVMutableComposition *avMComposition = [[AVMutableComposition alloc] init];
    
    //创建AVMutableCompositionTrack
    AVMutableCompositionTrack *avMTrack = [avMComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [avMTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, _videoAsset.duration) ofTrack:[[_videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    AVMutableCompositionTrack *avMTrackAudio = [avMComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray *audioAssetTraks = [_videoAsset tracksWithMediaType:AVMediaTypeAudio];
    if (audioAssetTraks.count) { //有声音轨道的话 添加声音轨道
        [avMTrackAudio insertTimeRange:CMTimeRangeMake(kCMTimeZero, _videoAsset.duration) ofTrack:[audioAssetTraks objectAtIndex:0] atTime:kCMTimeZero error:nil];
    }
    
    AVMutableVideoCompositionInstruction *avMComI = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    avMComI.timeRange = CMTimeRangeMake(kCMTimeZero, _videoAsset.duration);
    
    //AVMutableVideoCompositionLayerInstruction 视频追踪和定位
    AVMutableVideoCompositionLayerInstruction *avMVComLayerI = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:avMTrack];
    AVAssetTrack *avAssetTrack = [[_videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    UIImageOrientation videoAssetOrientation_up  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait  = NO;
    CGAffineTransform videoTransform = avAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        videoAssetOrientation_up = UIImageOrientationRight;
        isVideoAssetPortrait = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        videoAssetOrientation_up =  UIImageOrientationLeft;
        isVideoAssetPortrait = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        videoAssetOrientation_up =  UIImageOrientationUp;
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        videoAssetOrientation_up = UIImageOrientationDown;
    }
    [avMVComLayerI setTransform:avAssetTrack.preferredTransform atTime:kCMTimeZero];
    [avMVComLayerI setOpacity:0.0 atTime:_videoAsset.duration];
    
    avMComI.layerInstructions = [NSArray arrayWithObjects:avMVComLayerI,nil];
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    
    CGSize naturalSize;
    if(isVideoAssetPortrait){
        naturalSize = CGSizeMake(avAssetTrack.naturalSize.height, avAssetTrack.naturalSize.width);
    } else {
        naturalSize = avAssetTrack.naturalSize;
    }
    
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:avMComI];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    
    
    [self addLayerWithVideoComposition:mainCompositionInst size:naturalSize];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *videoPath =  [documentsDirectory stringByAppendingPathComponent:
                            [NSString stringWithFormat:@"My-change-%d.mov",arc4random() % 1000]];
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    
    //视频压缩
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:avMComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=url;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        [self exportDidFinish:exporter];
    }];
    
}
-(void)addLayerWithVideoComposition:(AVMutableVideoComposition *)mainCompositionInst size:(CGSize)naturalSize
{
//    根layer
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height); //这里的宽和高为视频的宽和高.
//    创建背景Layer
    CALayer *backgroundLayer = [CALayer layer];
    backgroundLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    backgroundLayer.backgroundColor=[UIColor orangeColor].CGColor;

//    图片层
    UIImageView *imageV=[[UIImageView alloc] initWithFrame:CGRectMake(40.0, 790.0, 100.0, 100.0)];
    imageV.layer.cornerRadius=10.0;
    imageV.layer.masksToBounds=YES;
    imageV.image=[UIImage imageNamed:@"Icon-60"];
//    文字层
    CATextLayer *textLayer=[CATextLayer layer];
    textLayer.fontSize = 30;
    textLayer.foregroundColor=(__bridge CGColorRef _Nullable)([UIColor whiteColor]);
    textLayer.string=@"足记-海底捞文化";
    textLayer.frame=CGRectMake(180.0, 825.0, 380.0,44.0);
    
//    第二个文字
    CATextLayer *textLayer1=[CATextLayer layer];
    textLayer1.fontSize = 22;
    textLayer1.foregroundColor=(__bridge CGColorRef _Nullable)([UIColor whiteColor]);
    textLayer1.string=@"2017-8-11 星期五";
    textLayer1.frame=CGRectMake(naturalSize.width/3.0*2.0, 30.0, naturalSize.width/2.0,36.0);
//    视频层
    CALayer *videoLayer = [CALayer layer];
    videoLayer.cornerRadius=30.0;
    videoLayer.masksToBounds=YES;
    CGFloat videoWidth=naturalSize.width/3.0*2.0;
    CGFloat videoHeight=videoWidth/9.0*16.0;
    CGFloat startX=(naturalSize.width-videoWidth)/3.0;
    CGFloat startY=(naturalSize.height-videoHeight)/3.0;
    videoLayer.frame = CGRectMake(startX*2.0, startY*1.0,videoWidth, videoHeight);
//  添加各个层
    [parentLayer addSublayer:backgroundLayer];
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:textLayer];
    [parentLayer addSublayer:textLayer1];
    [parentLayer addSublayer:imageV.layer];
//    告诉系统videolayer层是播放视频的
    mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

- (void)exportDidFinish:(AVAssetExportSession *)session {
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSLog(@"------>%@",[NSDate date]);
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
        if ([lib videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [lib writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {

                    } else {

                    }
                });
            }];
        }
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
