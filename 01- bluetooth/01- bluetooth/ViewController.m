//
//  ViewController.m
//  01- bluetooth
//
//  Created by jiaguanglei on 16/2/16.
//  Copyright © 2016年 roseonly. All rights reserved.
//

#import "ViewController.h"

// GameKit框架, 连接蓝牙
#import <GameKit/GameKit.h>


//#import <SpriteKit/SpriteKit.h>
//#import <SceneKit/SceneKit.h>
@interface ViewController ()<GKPeerPickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>


PROPERTYSTRONG(GKSession, session)

@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@property (weak, nonatomic) IBOutlet UIButton *connectBtn;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;

- (IBAction)connectMethod:(id)sender;
- (IBAction)sendMethod:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 创建按钮
    self.iconView.userInteractionEnabled = YES;
    [self.iconView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chooseIcon:)]];
}


#pragma mark - GKPeerPickerControllerDelegate
/* Notifies delegate that the peer was connected to a GKSession. -- 成功连接设备
 */
- (void)peerPickerController:(GKPeerPickerController *)picker // 搜索框
              didConnectPeer:(NSString *)peerID // 连接设备
                   toSession:(GKSession *)session // 连接会话, 通过会话可以进行数据传输
{
    LogRed(@"%s, line = %d", __FUNCTION__, __LINE__);
    
    // 1. 关闭搜索框
    [picker dismiss];
    
    // 2. 创建会话
    self.session = session;
    
    // 3.设置接收数据
    // 设置完接受者之后,接收数据会触发: SEL = -receiveData:fromPeer:inSession:context:
    [self.session setDataReceiveHandler:self withContext:nil];
}

/**
 *  监听建立连接
 *
 */
- (IBAction)connectMethod:(id)sender {
    /**
     "Use MCBrowserViewController from the MultipeerConnectivity framework"
     
     */
    GKPeerPickerController *ppc = [[GKPeerPickerController alloc] init];
    
    ppc.delegate = self;
    
    [ppc show];

}


#pragma mark - UIImagePickerViewControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // 将取出图片赋值给imageviews
//    self.iconView.image = info[UIImagePickerControllerOriginalImage];
}
/**
 *  在相册选取图片
 *
 */
- (void)chooseIcon:(id)sender {
    //
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        LogRed(@"没有相册");
        return;
    }
    
    // 创建相册
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    
    [self presentViewController:picker animated:YES completion:nil];
}




/**
 *  监听发送数据
 *
 */
- (IBAction)sendMethod:(id)sender {
    // 1. 判断要发送的数据是否存在
    if(!self.iconView.image) return;
    
    // 2. 发送数据
//    [self.session sendData:UIImagePNGRepresentation(self.iconView.image)
//                   toPeers:xxx // 传入已经连接的所有设备
//              withDataMode:GKSendDataReliable
//                     error:nil];
    NSError *error = nil;
    BOOL suc = [self.session sendDataToAllPeers:UIImagePNGRepresentation(self.iconView.image) withDataMode:GKSendDataReliable error:&error];
    if (!suc) {
        LogGreen(@"%@", error);
    }
}


#pragma mark - 蓝牙设备接收到数据时,就会调用
- (void)receiveData:(NSData *)data // 数据
           fromPeer:(NSString *)peer // 来自哪个设备
          inSession:(GKSession *)session // 连接会话
            context:(void *)context
{
    // 将接收到的数据展示在屏幕上
    self.iconView.image = [UIImage imageWithData:data];
    
    // 将图片存入相册
    UIImageWriteToSavedPhotosAlbum(self.iconView.image, nil, nil, nil);
}
@end
