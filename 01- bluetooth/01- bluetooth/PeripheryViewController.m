//
//  PeripheryViewController.m
//  01- bluetooth
//
//  Created by jiaguanglei on 16/2/16.
//  Copyright © 2016年 roseonly. All rights reserved.
//

/**
 *  外围管理模式 控制器
 1.引入CoreBluetooth框架,初始化peripheralManager
 2.设置peripheralManager中的内容
 3.开启广播advertising
 4.对central的操作进行响应
     4.1 读characteristics请求
     4.2 写characteristics请求
     4.4 订阅和取消订阅characteristics
 */

#import "PeripheryViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString *const Service0StrUUID = @"FFF0";
static NSString *const Service1StrUUID = @"FFE0";

static NSString *const notiyCharacteristicStrUUID = @"FFF1";
static NSString *const readwriteCharacteristicStrUUID = @"FFF2";
static NSString *const readonlyCharacteristicStrUUID = @"FFE1";

static NSString *const LocalNameKey = @"XMGPeripheral";

@interface PeripheryViewController ()<CBPeripheralManagerDelegate>

/** 外设管理者对象 */
PROPERTYSTRONG(CBPeripheralManager, pMgr)
/** 服务数组 */
PROPERTYSTRONG(NSMutableArray, services)

PROPERTYSTRONG(NSTimer, timer)
@end

@implementation PeripheryViewController
// 懒加载
- (NSMutableArray *)services
{
    if (!_services) {
        _services = [NSMutableArray array];
    }
    return _services;
}

- (CBPeripheralManager *)pMgr
{
    if (!_pMgr) {
        _pMgr = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:nil];
    }
    return _pMgr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.title = @"PeripheryViewController";
#pragma mark -
#pragma mark - 1.初始化peripheralManager
    // 1. 创建外设对象
    [self pMgr];
}

#pragma mark - CBPeripheralManagerDelegate
/**
 *  pMgr对象初始化时, 触发此方法
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    switch (peripheral.state) {
        case CBPeripheralManagerStateUnknown: {
            LogRed(@"CBPeripheralManagerStateUnknown");
            break;
        }
        case CBPeripheralManagerStateResetting: {
            LogRed(@"CBPeripheralManagerStateResetting");
            break;
        }
        case CBPeripheralManagerStateUnsupported: {
            LogRed(@"CBPeripheralManagerStateUnsupported");
            break;
        }
        case CBPeripheralManagerStateUnauthorized: {
            LogRed(@"CBPeripheralManagerStateUnauthorized");
            break;
        }
        case CBPeripheralManagerStatePoweredOff: {
            LogRed(@"CBPeripheralManagerStatePoweredOff");
            break;
        }
        case CBPeripheralManagerStatePoweredOn: { // PoweredOn状态下, 开启搜索
            LogRed(@"CBPeripheralManagerStatePoweredOn");
#pragma mark -
#pragma mark -  2.设置peripheralManager中的内容
            // 2. 设置pMgr中的服务,特征等内容
            [self yf_setuppMgr];
            break;
        }
    }
}


/*!
 *  @method peripheralManager:willRestoreState:
 *
 *  @param peripheral	The peripheral manager providing this information.
 *  @param dict			A dictionary containing information about <i>peripheral</i> that was preserved by the system at the time the app was terminated.
 *
 *  @discussion			For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
 *						the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
 *						Bluetooth system.
 *
 *  @seealso            CBPeripheralManagerRestoredStateServicesKey;
 *  @seealso            CBPeripheralManagerRestoredStateAdvertisementDataKey;
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary<NSString *, id> *)dict
{

}


/*!  ****  开启广播: 添加服务到pMgr时, 触发此方法
 *  @method peripheralManager:didAddService:error:
 *
 *  @param peripheral   The peripheral manager providing this information.
 *  @param service      The service that was added to the local database.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method returns the result of an @link addService: @/link call. If the service could
 *                      not be published to the local database, the cause will be detailed in the <i>error</i> parameter.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(nullable NSError *)error
{
    // 添加了两次
    static int i = 0;
    if (!error) {
        i++;
    }
    // 当第二次进入方法时候,代表两个服务添加完毕,此时要用到2,由于没有扩展性,所以新增了可变数组,记录添加的服务数量
    // CBAdvertisementDataLocalNameKey是由硬件产品决定的
    // CBAdvertisementDataServiceUUIDsKey此处的内容是所有服务的UUID,数组最好是通过可变数组中存储的已经添加的服务数组来确定(KVC)
    if (i == self.services.count) {
        // 广播内容
        NSDictionary *advertDict = @{CBAdvertisementDataServiceUUIDsKey: [self.services valueForKeyPath:@"UUID"],
                                     CBAdvertisementDataLocalNameKey:LocalNameKey};
#pragma mark -
#pragma mark -  3.开启广播advertising
        // 发出广播,会触发peripheralManagerDidStartAdvertising:error:
        [peripheral startAdvertising:advertDict];
    }
}


/*! 开启广播会触发 - 此代理方法
 *  @method peripheralManagerDidStartAdvertising:error:
 *
 *  @param peripheral   The peripheral manager providing this information.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method returns the result of a @link startAdvertising: @/link call. If advertisement could
 *                      not be started, the cause will be detailed in the <i>error</i> parameter.
 *
 */
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(nullable NSError *)error
{
    LogGreen(@"_%s", __FUNCTION__);
    
}

#pragma mark -
#pragma mark -  4.对central的操作进行响应
/*! 4.1 读characteristics请求
 *  外设收到读的请求, 然后读特征的值赋给request
 *  @method peripheralManager:didReceiveReadRequest:
 *
 *  @param peripheral   The peripheral manager requesting this information.
 *  @param request      A <code>CBATTRequest</code> object.
 *
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request for a characteristic with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link must be called.
 *
 *  @see                CBATTRequest
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    // 判断是否可读
    if(request.characteristic.properties & CBCharacteristicPropertyRead){
        NSData *data = request.characteristic.value;
        
        request.value = data;
        // 对请求作出响应
        [self.pMgr respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [self.pMgr respondToRequest:request withResult:CBATTErrorReadNotPermitted];
    }
}

/*! 4.1 读characteristics请求
 *  外设收到写的请求, 然后读requ的值赋给特征
 *  @method peripheralManager:didReceiveWriteRequests:
 *
 *  @param peripheral   The peripheral manager requesting this information.
 *  @param requests     A list of one or more <code>CBATTRequest</code> objects.
 *
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request or command for one or more characteristics with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link should be called exactly once. If <i>requests</i> contains
 *                      multiple requests, they must be treated as an atomic unit. If the execution of one of the requests would cause a failure, the request
 *                      and error reason should be provided to <code>respondToRequest:withResult:</code> and none of the requests should be executed.
 *
 *  @see                CBATTRequest
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    CBATTRequest *request = requests.firstObject;
    
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        NSData *data = request.value;
        
        // 此处赋值转类型, 否则报错
        CBMutableCharacteristic *mchar = (CBMutableCharacteristic *)request.characteristic;
        mchar.value = data;
        
        // 对成功作出响应
        [self.pMgr respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [self.pMgr respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}

#pragma mark - 订阅和取消订阅characteristics
/* 订阅
 *  @method peripheralManager:central:didSubscribeToCharacteristic:
 *
 *  @param peripheral       The peripheral manager providing this update.
 *  @param central          The central that issued the command.
 *  @param characteristic   The characteristic on which notifications or indications were enabled.
 *
 *  @discussion             This method is invoked when a central configures <i>characteristic</i> to notify or indicate.
 *                          It should be used as a cue to start sending updates as the characteristic value changes.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    LogYellow(@"订阅了%@的数据", characteristic.UUID);
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                      target:self
                                                    selector:@selector(yf_sendData:)
                                                    userInfo:characteristic repeats:YES];
    self.timer = timer;
    self.timer.fireDate = [NSDate date];
    /* 另一种方法 */
    //    NSTimer *testTimer = [NSTimer timerWithTimeInterval:2.0
    //                                                 target:self
    //                                               selector:@selector(yf_sendData:)
    //                                               userInfo:characteristic
    //                                                repeats:YES];
    //    [[NSRunLoop currentRunLoop] addTimer:testTimer forMode:NSDefaultRunLoopMode];
}

/*! 取消订阅特性
 *  @method peripheralManager:central:didUnsubscribeFromCharacteristic:
 *
 *  @param peripheral       The peripheral manager providing this update.
 *  @param central          The central that issued the command.
 *  @param characteristic   The characteristic on which notifications or indications were disabled.
 *
 *  @discussion             This method is invoked when a central removes notifications/indications from <i>characteristic</i>.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
     LogYellow(@"取消订阅了%@的数据", characteristic.UUID);
    // 暂停
    self.timer.fireDate = [NSDate distantFuture];
}

/*! 订阅状态改变会触发此方法
 *  @method peripheralManagerIsReadyToUpdateSubscribers:
 *
 *  @param peripheral   The peripheral manager providing this update.
 *
 *  @discussion         This method is invoked after a failed call to @link updateValue:forCharacteristic:onSubscribedCentrals: @/link, when <i>peripheral</i> is again
 *                      ready to send characteristic value updates.
 *
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    LogYellow(@"%s", __FUNCTION__);
}


#pragma mark - 私有方法
// 2. 设置外设管理者对象 pMgr
/**
 *  设置peripheralManager中的内容
 
 创建characteristics及其description,
 创建service,把characteristics添加到service中,
 再把service添加到peripheralManager中
 */
- (void)yf_setuppMgr
{
    // 1. 特征描述的UUID
    CBUUID *characteristicUserDescriptionUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    // 特征通知的UUID
    CBUUID *notifyCharacteristicUUID = [CBUUID UUIDWithString:notiyCharacteristicStrUUID];
    // 特征的读写UUID
    CBUUID *readwriteCharacteristicUUID = [CBUUID UUIDWithString:readwriteCharacteristicStrUUID];
    // 特征的只读UUID
    CBUUID *readonlyCharacteristicUUID = [CBUUID UUIDWithString:readonlyCharacteristicStrUUID];
    // 服务的UUID
    CBUUID *ser0UUID = [CBUUID UUIDWithString:Service0StrUUID];
    CBUUID *ser1UUID = [CBUUID UUIDWithString:Service1StrUUID];
    
    // 2. 初始化一个特征描述
    CBMutableDescriptor *des0 = [[CBMutableDescriptor alloc] initWithType:characteristicUserDescriptionUUID value:@"test1"];
    
    // 3.1 可通知的特征
    CBMutableCharacteristic *notifyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:notifyCharacteristicUUID // UUID
                                                                                       properties:CBCharacteristicPropertyNotify // 枚举:通知
                                                                                            value:nil // 数据先不传
                                                                                      permissions:CBAttributePermissionsReadable]; // 枚举:可读
    // 3.2 可读写的特征
    CBMutableCharacteristic *readwriteCharacteristic = [[CBMutableCharacteristic alloc] initWithType:readwriteCharacteristicUUID
                                                                                          properties:CBCharacteristicPropertyWrite // 读写
                                                                                               value:nil
                                                                                         permissions:CBAttributePermissionsWriteable];
    [readwriteCharacteristic setDescriptors:@[des0]];
    
    // 3.3 只读特征
    CBMutableCharacteristic *readonlyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:readonlyCharacteristicUUID
                                                                                         properties:CBCharacteristicPropertyRead
                                                                                              value:nil permissions:CBAttributePermissionsReadable];
    
    
    // 4. 初始化服务ser0
    CBMutableService *ser0 = [[CBMutableService alloc] initWithType:ser0UUID primary:YES];
    // 为服务器设置2个特征
    ser0.characteristics = @[notifyCharacteristic, readwriteCharacteristic];
    // 将服务添加到数组中
    [self.services addObject:ser0];
    
    // 初始化服务ser1
    CBMutableService *ser1 = [[CBMutableService alloc] initWithType:ser1UUID primary:YES];
    // 为服务器设置2个特征
    ser0.characteristics = @[readonlyCharacteristic];
    [self.services addObject:ser1];
    
    // 5. 将服务 添加到外设管理者对象中
    // 触发代理方法: - peripheralManager:didAddService:error:
    if (self.services.count) {
        for (CBMutableService *service in self.services) {
            [self.pMgr addService:service];
        }
    }
    
}


/**
 *  计时器每隔2s, 调用一次
 */
- (BOOL)yf_sendData:(NSTimer *)timer
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"yy:MM:dd:HH:mm:ss";
    
    NSString *now = [format stringFromDate:[NSDate date]];
    LogYellow(@"now = %@", now);
    
    // 执行回应central通知数据
    return [self.pMgr updateValue:[now dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:timer.userInfo onSubscribedCentrals:nil];
}

- (void)dealloc
{
    [self.timer invalidate];
    self.timer = nil;
}
@end
