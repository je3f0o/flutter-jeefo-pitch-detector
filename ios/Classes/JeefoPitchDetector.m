//
//  JeefoPitchDetector.m
//  objc
//
//  Created by Batkhishig on 2023.04.01.
//

#import "JeefoPitchDetector.h"
#import "FFTPitchAnalyser/include/jeefo_pitch_detector.h"

@interface JeefoPitchDetector ()

@property (nonatomic, strong) AVAudioEngine *audio_engine;
@property (nonatomic, assign) BOOL is_activated;

@end

const AVAudioFrameCount NUM_SAMPLES = 1024;

@implementation JeefoPitchDetector

+ (instancetype)shared {
    static JeefoPitchDetector *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JeefoPitchDetector alloc] init];
    });
    instance.confidenceThreshold = 0.95f;
    return instance;
}

- (void)activateWithThreshold:(float)threshold completion:(void (^)(BOOL result))completion {
    __block BOOL result = NO;
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]) {
        case AVAuthorizationStatusAuthorized:
            [self start];
            result = YES;
            break;
        case AVAuthorizationStatusNotDetermined: {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (granted) {
                    [self start];
                    result = YES;
                }
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            break;
        }
        default:
            result = NO;
            break;
    }

    if (result == YES) {
        AVAudioInputNode *inputNode = self.audio_engine.inputNode;
        AVAudioFormat *hwFormat = [inputNode inputFormatForBus:0];
        jpd_init(NUM_SAMPLES, hwFormat.sampleRate, JeefoPitchDetector.shared.confidenceThreshold);
        self.is_activated = YES;
    }

    completion(result);
}

- (void)deactivateWithCompletion:(void (^)(BOOL result))completion {
    [self.audio_engine stop];
    AVAudioInputNode *inputNode = self.audio_engine.inputNode;
    [inputNode removeTapOnBus:0];
    self.is_activated = NO;

    jpd_destroy();
    completion(YES);
}

- (void)start {
    AVAudioInputNode *inputNode = self.audio_engine.inputNode;
    AVAudioFormat *hwFormat = [inputNode inputFormatForBus:0];
    AVAudioFormat *inputFormat = [
        [AVAudioFormat alloc]
        initWithCommonFormat:AVAudioPCMFormatFloat32
        sampleRate:hwFormat.sampleRate
        channels:1
        interleaved:YES
    ];
//  NSLog(@"Input Format: %@", inputFormat);
//  NSLog(@"Hardware Format: %@", hwFormat);

    if (!inputFormat) {
        NSLog(@"Error: Unable to create AVAudioFormat");
    } else {
        [inputNode installTapOnBus:0 bufferSize:NUM_SAMPLES format:inputFormat block:^(AVAudioPCMBuffer *buffer, AVAudioTime *time) {
            if (!self.is_activated) return;

            float values[10];
            float* b = buffer.floatChannelData[0];
            jpd_get_values_from_float(b, values);

            if (values[0] > 0) {
                self.pitch      = values[0];
                self.confidence = values[1];
            }
        }];
    }

    [self.audio_engine startAndReturnError:nil];
}

- (instancetype)init {
    _audio_engine = [[AVAudioEngine alloc] init];
    _is_activated = false;
    return [super init];
}

- (void)dealloc {
    jpd_destroy();
}

@end