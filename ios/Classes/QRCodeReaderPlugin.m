#import "QRCodeReaderPlugin.h"

static NSString *const CHANNEL_NAME = @"qrcode_reader";
static FlutterMethodChannel *channel;

@interface QRCodeReaderPlugin()<AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) UIView *viewPreview;
@property (nonatomic, strong) UIView *qrcodeview;
//@property (nonatomic, strong) UIButton *buttonCancel;
@property (nonatomic, strong) UIButton *buttonPlateNumberPay;
@property (nonatomic, strong) UIButton *buttonStaffIdInput;
@property (nonatomic, strong) UIButton *buttonMyQrCode;
@property (nonatomic, strong) UIButton *buttonBack;
@property (nonatomic) BOOL isReading;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
-(BOOL)startReading;
-(void)stopReading;
@property (nonatomic, retain) UIViewController *viewController;
@property (nonatomic, retain) UIViewController *qrcodeViewController;
@property (nonatomic) BOOL isFrontCamera;
@end

@implementation QRCodeReaderPlugin {
FlutterResult _result;
UIViewController *_viewController;
NSString *_qrCodeScene;
}

float height;
float width;
float landscapeheight;
float portraitheight;


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel 
                                     methodChannelWithName:CHANNEL_NAME 
                                     binaryMessenger:[registrar messenger]];
    UIViewController *viewController =
    [UIApplication sharedApplication].delegate.window.rootViewController;
    QRCodeReaderPlugin* instance = [[QRCodeReaderPlugin alloc] initWithViewController:viewController];
    [registrar addMethodCallDelegate:instance channel:channel];
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary *args = (NSDictionary *)call.arguments;
    self.isFrontCamera = [[args objectForKey: @"frontCamera"] boolValue];

    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"readQRCode" isEqualToString:call.method]) {
        NSDictionary *dic = call.arguments;
        NSString *qrCodeScene = dic[@"qrCodeScene"];
        _qrCodeScene = qrCodeScene;
        [self showQRCodeView:call];
        _result = result;
    } else if ([@"stopReading" isEqualToString:call.method]) {
        [self stopReading];
        result(@"stopped");
    }else {
        result(FlutterMethodNotImplemented);
    }
}


- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _viewController.view.backgroundColor = [UIColor clearColor];
        _viewController.view.opaque = NO;
        [[ NSNotificationCenter defaultCenter]addObserver: self selector:@selector(rotate:)
                                              name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}


- (void)showQRCodeView:(FlutterMethodCall*)call {
    _qrcodeViewController = [[UIViewController alloc] init];
    [_viewController presentViewController:_qrcodeViewController animated:NO completion:nil];
    [self loadViewQRCode];
    [self viewQRCodeDidLoad];
    [self startReading];
}


- (void)closeQRCodeView {
    [_qrcodeViewController dismissViewControllerAnimated:YES completion:^{
        [channel invokeMethod:@"onDestroy" arguments:nil];
    }];
}


-(void)loadViewQRCode {
    portraitheight = height = [UIScreen mainScreen].applicationFrame.size.height;
    landscapeheight = width = [UIScreen mainScreen].applicationFrame.size.width;
    if(UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])){
        landscapeheight = height;
        portraitheight = width;
    }
    _qrcodeview= [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height) ];
    _qrcodeview.opaque = NO;
    _qrcodeview.backgroundColor = [UIColor whiteColor];
    _qrcodeViewController.view = _qrcodeview;
}


- (void)viewQRCodeDidLoad {
    _viewPreview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height+height/10) ];
    _viewPreview.backgroundColor = [UIColor whiteColor];
    [_qrcodeViewController.view addSubview:_viewPreview];
    // 取消按钮
//    _buttonCancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    _buttonCancel.frame = CGRectMake(width/2-width/8, height-height/20, width/4, height/20);
//    [_buttonCancel setTitle:@"CANCEL"forState:UIControlStateNormal];
//    [_buttonCancel addTarget:self action:@selector(stopReading) forControlEvents:UIControlEventTouchUpInside];
//    [_qrcodeViewController.view addSubview:_buttonCancel];
    
    [self setupMaskView];

    
    // 车牌付按钮
    _buttonPlateNumberPay = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _buttonPlateNumberPay.frame = CGRectMake(63,504,120,40);
    _buttonPlateNumberPay.layer.backgroundColor = [UIColor colorWithRed:245/255.0 green:166/255.0 blue:35/255.0 alpha:1.0].CGColor;
    _buttonPlateNumberPay.layer.cornerRadius = 4;
    [_buttonPlateNumberPay setTitle:@"车牌付" forState:UIControlStateNormal];
    [_buttonPlateNumberPay setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_buttonPlateNumberPay addTarget:self action:@selector(onPlateNumberPay) forControlEvents:UIControlEventTouchUpInside];
//    [_qrcodeViewController.view addSubview:_buttonPlateNumberPay];
    
    // 员工ID输入按钮
    _buttonStaffIdInput = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _buttonStaffIdInput.frame = CGRectMake(193,504,120,40);
    _buttonStaffIdInput.layer.backgroundColor = [UIColor colorWithRed:245/255.0 green:113/255.0 blue:46/255.0 alpha:1.0].CGColor;
    _buttonStaffIdInput.layer.cornerRadius = 4;
    [_buttonStaffIdInput setTitle:@"输入员工ID" forState:UIControlStateNormal];
    [_buttonStaffIdInput setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_buttonStaffIdInput addTarget:self action:@selector(onStaffIdInput) forControlEvents:UIControlEventTouchUpInside];
//    [_qrcodeViewController.view addSubview:_buttonStaffIdInput];
    
    // 我的二维码按钮
    _buttonMyQrCode = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _buttonMyQrCode.frame = CGRectMake(270,53,90,22);
    [_buttonMyQrCode setTitle:@"我的二维码" forState:UIControlStateNormal];
    [_buttonMyQrCode setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_buttonMyQrCode addTarget:self action:@selector(onMyQrCode) forControlEvents:UIControlEventTouchUpInside];
//    [_qrcodeViewController.view addSubview:_buttonMyQrCode];
    
    if ([@"bindingGasStation" isEqualToString:_qrCodeScene]) {
        // do nothing
    } else if ([@"fueling" isEqualToString:_qrCodeScene]) {
        [_qrcodeViewController.view addSubview:_buttonStaffIdInput];
        _buttonStaffIdInput.frame = CGRectMake(128,504,120,40);
        [_qrcodeViewController.view addSubview:_buttonMyQrCode];
    } else if ([@"fuelingWithPlateNumberPay" isEqualToString:_qrCodeScene]) {
        [_qrcodeViewController.view addSubview:_buttonPlateNumberPay];
        [_qrcodeViewController.view addSubview:_buttonStaffIdInput];
        [_qrcodeViewController.view addSubview:_buttonMyQrCode];
    }
    
    // 扫一扫
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(161,53,54,22);
    label.numberOfLines = 0;
    [_qrcodeViewController.view addSubview:label];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"扫一扫"attributes: @{NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Regular" size: 18],NSForegroundColorAttributeName: [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0]}];
    
    label.attributedText = string;
    label.textAlignment = NSTextAlignmentCenter;
    label.alpha = 1.0;
    
    // 返回
    _buttonBack = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _buttonBack.frame = CGRectMake(15,53,54,22);
    [_buttonBack setTitle:@"返回" forState:UIControlStateNormal];
    [_buttonBack setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_buttonBack addTarget:self action:@selector(stopReading) forControlEvents:UIControlEventTouchUpInside];
    [_qrcodeViewController.view addSubview:_buttonBack];
    
    _captureSession = nil;
    _isReading = NO;
}

- (void)setupMaskView {
    portraitheight = height = [UIScreen mainScreen].applicationFrame.size.height;
    landscapeheight = width = [UIScreen mainScreen].applicationFrame.size.width;
    // 设置统一的视图颜色和视图的透明度
    UIColor *color = [UIColor blackColor];
    float alpha = 0.7;
    float qrCodeWidth = 260.0;
    // 状态栏高度
    CGRect statusRect = [[UIApplication sharedApplication] statusBarFrame];
    float statusBarHeight = statusRect.size.height;
    // 设置扫描区域外部上部的视图
    UIView *topView = [[UIView alloc] init];
    topView.frame = CGRectMake(0, statusBarHeight, landscapeheight, (portraitheight-statusBarHeight-qrCodeWidth)/2.0-statusBarHeight);
    topView.backgroundColor = color;
    topView.alpha = alpha;
    // 设置扫描区域外部左边的视图
    UIView *leftView = [[UIView alloc] init];
    leftView.frame = CGRectMake(0, statusBarHeight+topView.frame.size.height, (landscapeheight-qrCodeWidth)/2.0,qrCodeWidth);
    leftView.backgroundColor = color;
    leftView.alpha = alpha;
    // 设置扫描区域外部右边的视图
    UIView *rightView = [[UIView alloc] init];
    rightView.frame = CGRectMake((landscapeheight-qrCodeWidth)/2.0+qrCodeWidth,statusBarHeight+topView.frame.size.height, (landscapeheight-qrCodeWidth)/2.0,qrCodeWidth);
    rightView.backgroundColor = color;
    rightView.alpha = alpha;
    // 设置扫描区域外部底部的视图
    UIView *botView = [[UIView alloc] init];
    botView.frame = CGRectMake(0,statusBarHeight+qrCodeWidth+topView.frame.size.height,landscapeheight,portraitheight-statusBarHeight-qrCodeWidth-topView.frame.size.height + 100);
    botView.backgroundColor = color;
    botView.alpha = alpha;
    // 将设置好的扫描二维码区域之外的视图添加到视图图层上
    [_qrcodeViewController.view addSubview:topView];
    [_qrcodeViewController.view addSubview:leftView];
    [_qrcodeViewController.view addSubview:rightView];
    [_qrcodeViewController.view addSubview:botView];
}


- (BOOL)startReading {
    if (_isReading) return NO;
    _isReading = YES;
    NSError *error;
    AVCaptureDevice *captureDevice;
    if ([self isFrontCamera]) {
        captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType: AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                                                mediaType: AVMediaTypeVideo
                                                                                position: AVCaptureDevicePositionFront];
    } else {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }

    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    [_captureSession startRunning];
    return YES;
}


-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            _result([metadataObj stringValue]);
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            _isReading = NO;
        }
    }
}


- (void) rotate:(NSNotification *) notification{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == 1) {
        height = portraitheight;
        width = landscapeheight;
//        _buttonCancel.frame = CGRectMake(width/2-width/8, height-height/20, width/4, height/20);
    } else {
        height = landscapeheight;
        width = portraitheight;
//        _buttonCancel.frame = CGRectMake(width/2-width/8, height-height/10, width/4, height/20);
    }
    _qrcodeview.frame = CGRectMake(0, 0, width, height) ;
    _viewPreview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height+height/10) ];
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    [_qrcodeViewController viewWillLayoutSubviews];
}


-(void)stopReading{
    [_captureSession stopRunning];
    _captureSession = nil;
    [_videoPreviewLayer removeFromSuperlayer];
    _isReading = NO;
    [self closeQRCodeView];
    _result(nil);
}

-(void)onPlateNumberPay {
    [_captureSession stopRunning];
    _captureSession = nil;
    [_videoPreviewLayer removeFromSuperlayer];
    _isReading = NO;
    [self closeQRCodeView];
    _result(@"plateNumberPay");
}

-(void)onStaffIdInput {
    [_captureSession stopRunning];
    _captureSession = nil;
    [_videoPreviewLayer removeFromSuperlayer];
    _isReading = NO;
    [self closeQRCodeView];
    _result(@"staffId");
}

-(void)onMyQrCode {
    [_captureSession stopRunning];
    _captureSession = nil;
    [_videoPreviewLayer removeFromSuperlayer];
    _isReading = NO;
    [self closeQRCodeView];
    _result(@"onMyQrCode");
}

@end
