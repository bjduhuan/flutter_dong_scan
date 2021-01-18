//
//  SDScanViewController.m
//  SDScanDemo
//
//  Created by 王巍栋 on 2020/6/29.
//  Copyright © 2020 骚栋. All rights reserved.
//

#import "SDScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SDScanMaskView.h"
#import "SDScanHeader.h"

@interface SDScanViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property(nonatomic,strong)SDScanConfig *config;
@property(nonatomic,strong)AVCaptureDevice *device;
@property(nonatomic,strong)AVCaptureSession *session;
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;

@property(nonatomic,strong)SDScanMaskView *maskView;
@property(nonatomic,strong)NSMutableArray *metadataObjectTypeArray;

@end

@implementation SDScanViewController

- (instancetype)initWithConfig:(SDScanConfig *)scanConfig {

    if (self = [super init]) {
        self.config = scanConfig;
    }
    return self;
}

- (void)viewDidLoad {

    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self startRunCameraScanAction];
    [self.view addSubview:self.maskView];
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

#pragma mark - 懒加载

- (SDScanMaskView *)maskView {

    if (_maskView == nil) {
        _maskView = [[SDScanMaskView alloc] initWithFrame:self.view.bounds config:self.config];
        __weak typeof(self) weakSelf = self;
        _maskView.exitBlock = ^{
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        };
         _maskView.albumBlock = ^{
            [weakSelf openAlbum];
        };
    }
    return _maskView;
}

-(void)openAlbum{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
	NSLog(@"camera error");
	return;
}
    UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.modalPresentationStyle = UIModalPresentationOverFullScreen;
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

// 控制器不会自己dismiss 需要我们手动在相应的地方实现
// 这两个代理方法只会收到其中一个，取决于用户的点击情况
//结束采集之后 之后怎么处理都在这里写 通过Infokey取出相应的信息  Infokey可在进入文件中查看
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    //查看是视频还是照片  public.image 或 public.movie
    NSString * mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]) {//照片
    UIImage *pickedImage = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    CIImage *detectImage = [CIImage imageWithData:UIImagePNGRepresentation(pickedImage)];

    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
    CIQRCodeFeature *feature = (CIQRCodeFeature *)[detector featuresInImage:detectImage options:nil].firstObject;

    // [picker dismissViewControllerAnimated:YES completion:^{
    //     if (feature.messageString) {
    //         [self handleCodeString:feature.messageString];
    //     }
    // }];
    if (feature.messageString) {
        if (self.config.resultBlock != nil) {
            self.config.resultBlock(feature.messageString);
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    }

}

//用户点击了取消
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}





- (NSMutableArray *)metadataObjectTypeArray {

    if (_metadataObjectTypeArray == nil) {
        _metadataObjectTypeArray = [NSMutableArray arrayWithArray:@[AVMetadataObjectTypeAztecCode,
                                                                    AVMetadataObjectTypeCode128Code,
                                                                    AVMetadataObjectTypeCode39Code,
                                                                    AVMetadataObjectTypeCode39Mod43Code,
                                                                    AVMetadataObjectTypeCode93Code,
                                                                    AVMetadataObjectTypeEAN13Code,
                                                                    AVMetadataObjectTypeEAN8Code,
                                                                    AVMetadataObjectTypePDF417Code,
                                                                    AVMetadataObjectTypeQRCode,
                                                                    AVMetadataObjectTypeUPCECode,
                                                                    AVMetadataObjectTypeInterleaved2of5Code,
                                                                    AVMetadataObjectTypeITF14Code,
                                                                    AVMetadataObjectTypeDataMatrixCode]];
    }
    return _metadataObjectTypeArray;
}

#pragma mark - 扫描相关

// 开始扫描
- (void)startRunCameraScanAction {

    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    AVCaptureMetadataOutput * metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;

    [self.session addInput:input];
    [self.session addOutput:metadataOutput];

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.backgroundColor = [UIColor yellowColor].CGColor;
    [self.view.layer addSublayer:self.previewLayer];

    metadataOutput.metadataObjectTypes = [NSArray arrayWithArray:self.metadataObjectTypeArray];

    [self.session startRunning];
}

// 扫描结果
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {

    if (metadataObjects.count > 0) {
        [self.session stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = metadataObjects.firstObject;
        if (self.config.resultBlock != nil) {
            self.config.resultBlock(metadataObject.stringValue);
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end

