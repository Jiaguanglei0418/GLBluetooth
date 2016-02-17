//
//  CentralViewController.m
//  01- bluetooth
//
//  Created by jiaguanglei on 16/2/16.
//  Copyright © 2016年 roseonly. All rights reserved.
//

/**
 *  中心管理模式 控制器
 ## BLE中心模式流程
 - 1.建立中心角色
 - 2.扫描外设(Discover Peripheral)
 - 3.连接外设(Connect Peripheral)
 - 4.扫描外设中的服务和特征(Discover Services And Characteristics)
 * 4.1 获取外设的services
 * 4.2 获取外设的Characteristics,获取characteristics的值,,获取Characteristics的Descriptor和Descriptor的值
 - 5.利用特征与外设做数据交互(Explore And Interact)
 - 6.订阅Characteristic的通知
 - 7.断开连接(Disconnect)
 */
#import "CentralViewController.h"
// BLE 框架
#import <CoreBluetooth/CoreBluetooth.h>

@interface CentralViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate>

/** 中心管理者 */
PROPERTYSTRONG(CBCentralManager, cMgr)
/** 连接到的外设 */
PROPERTYSTRONG(CBPeripheral, cPeriphery)


@end

@implementation CentralViewController
/**
 *  懒加载
 *
 *  @ 需要调用完成对象初始化
 */
- (CBCentralManager *)cMgr
{
    if (!_cMgr) {
        _cMgr = [[CBCentralManager alloc] initWithDelegate:self
                                                     queue:dispatch_get_main_queue()
                                                options:nil];
    }
    return _cMgr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"CentralViewController";
    
    // 在ios5之前, 再通过以下方法设置背景时, 有闪屏bug
    //    self.view.backgroundColor = [UIColor colorWithPatternImage:<#(nonnull UIImage *)#>];
    //    // 解决方案
    //    self.view.layer.contents = (id)[UIColor colorWithPatternImage:[UIImage imageNamed:xxx]];
    // 0. 创建管理者对象
#pragma mark -
#pragma mark - - 1.建立中心角色
    [self cMgr];
    
}

// 通常在此需要 断开连接外设
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 此处断开连接外设
    [self yf_dismissConnectedWithPeripheral:self.cPeriphery];
}

#pragma mark - CBCentralManagerDelegate
/**
 *  @1 只要中心管理者初始化, 就会触发此方法
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) { // 开启
        case CBCentralManagerStateUnknown: { // 未知
            LogRed(@"CBCentralManagerState--- Unknown");
            break;
        }
        case CBCentralManagerStateResetting: { // 重置
             LogRed(@"CBCentralManagerState--- Resetting");
            break;
        }
        case CBCentralManagerStateUnsupported: { // 不支持
            LogRed(@"CBCentralManagerState--- Unsupported");
            break;
        }
        case CBCentralManagerStateUnauthorized: { // 未授权
            LogRed(@"CBCentralManagerState--- Unauthorized");
            break;
        }
        case CBCentralManagerStatePoweredOff: { // 关闭
            LogRed(@"CBCentralManagerState---- PoweredOff");
            break;
        }
        case CBCentralManagerStatePoweredOn: { // 开启
            LogRed(@"CBCentralManagerState---  PoweredOn");
#pragma mark -
#pragma mark - - 2.扫描外设(Discover Peripheral)
            // 1. 搜索外设
            [self.cMgr scanForPeripheralsWithServices:nil // 通过某些服务, 筛选外设
                                              options:nil];
            break;
        }
    }
}


/*!
 *  @method centralManager:willRestoreState:
 **/
- (void)centralManager:(CBCentralManager *)central
      willRestoreState:(NSDictionary<NSString *, id> *)dict{
    
}

/*!  *****@2 常用方法 - 发现外设触发此方法
 *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
 *
 */
- (void)centralManager:(CBCentralManager *)central // 中心管理者
 didDiscoverPeripheral:(CBPeripheral *)peripheral // 外设
     advertisementData:(NSDictionary<NSString *, id> *)advertisementData // 外设携带的数据
                  RSSI:(NSNumber *)RSSI // 外设信号强度
{
    /**
    peripheral -  <CBPeripheral: 0x1666faa0, identifier = E57942BE-7941-DC11-1CD9-CEA1725456DF, name = (null), state = disconnected>
     advertisementData - {
     kCBAdvDataIsConnectable = 0;
     kCBAdvDataManufacturerData = <75004204 018020fc 8f90a492 9bfe8f90 a4929a01 00000000 0000>;
     }
     */
    LogYellow(@"%@\n -- %@\n --%@\n --%@\n", central, peripheral, advertisementData, RSSI);
    // 需要对连接到的设备进行过滤
    // 1. 信号强度(大于35)
    // 2. 设备名(前缀 "0") [peripheral.name hasPrefix:@"0"] &&
    if((ABS(RSSI.integerValue) > 35)){
        // 在此处对我们的 advertisementData, 进行处理
        
        // 此处应该讲得到的外设存储到可变数组中
        // 以下对一个外设处理:
        // 让外设的生命周期 == VC
        self.cPeriphery = peripheral;
#pragma mark -
#pragma mark - - 3.连接外设(Connect Peripheral)
        // 发现外设之后进行连接
        [self.cMgr connectPeripheral:self.cPeriphery options:nil];
    }
}

/*! *****@3  中心管理者成功连接外设后, 会触发此方法
 *  @method centralManager:didConnectPeripheral:
 *
 */
- (void)centralManager:(CBCentralManager *)central // 中心管理者
  didConnectPeripheral:(CBPeripheral *)peripheral // 外设
{
    
    LogBlue(@"%@\n --- %@", central, peripheral);
    // 连接成功后可以进行数据交互
    // 3.1 获取外设的服务
    self.cPeriphery.delegate = self;
#pragma mark -
#pragma mark - - 4.扫描外设中的服务和特征(Discover Services And Characteristics)
    // 3.2 外设发现所有服务, nil代表不过滤
    // 触发: - (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
    [self.cPeriphery discoverServices:nil];
}

/*! *** 外设连接失败
 *  @method centralManager:didFailToConnectPeripheral:error:
 
 */
- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(nullable NSError *)error{
    LogGreen(@"error - %@ ", error);
}

/*! *** 断开连接
 *  @method centralManager:didDisconnectPeripheral:error:
 *
  */
- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(nullable NSError *)error{
     LogGreen(@"error - %@ ", error);
}


#pragma mark - CBPeripheryDelegate
/**
 *  外设发现服务 触发此代理方法
 */
#warning 以下方法中只要error, 都要容错处理
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    // 容错处理
   [self dealError:error];
#pragma mark - -   * 4.1 获取外设的services
    // 遍历外设的所有服务
    for (CBService *service in peripheral.services) {
        // 发现服务后, 让外设发现服务内部 特征
        // 触发: - (void)peripheral: didDiscoverCharacteristicsForService: error:
        [peripheral discoverCharacteristics:nil forService:service];
    }
    LogGreen(@"%@", peripheral);
}

/**
 *  发现外设服务里面特征后 触发此代理方法
 *
 *  @param peripheral 外设
 *  @param service    服务
 *  @param error      错误
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    [self dealError:error];
#pragma mark - -   * 4.2 获取外设的Characteristics和Descriptor

    for (CBCharacteristic *character in service.characteristics) {
        // 获取特征对应的描述
        // 触发: - didUpdateValueForDescriptor
        [peripheral discoverDescriptorsForCharacteristic:character];
        // 获取特征的值
        // 触发: - didUpdateValueForCharacteristic:
        [peripheral readValueForCharacteristic:character];
        
#warning 在此处调用写入数据方法
//        [self yf_peripheral:peripheral didWriteData:<#(NSData *)#> forCharacteristic:character];
    }
    
}


/**
 *  更新特征的时候就会 触发此方法
 *
 *  @param peripheral     外设
 *  @param characteristic 对应的服务的特征
 *  @param error          错误
 */
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    LogRed(@"%s", __FUNCTION__);
    [self dealError:error];

    for (CBDescriptor *descriptor in characteristic.descriptors) {
        // 获取特征描述值
        // 触发: - didDiscoverDescriptorsForCharacteristic
        [peripheral readValueForDescriptor:descriptor];
    }
}

/**
 *  更新特征的描述的值时, 触发此方法
 *
 *  @param peripheral 外设
 *  @param descriptor 外设对应服务的特征的描述
 *  @param error      错误
 */
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForDescriptor:(CBDescriptor *)descriptor
             error:(NSError *)error
{
    
     LogRed(@"%s", __FUNCTION__);
    [self dealError:error];

    // 当前描述更新时, 直接调用此方法
    [peripheral readValueForDescriptor:descriptor];
}


/**
 *  发现外设服务特征中的描述, 触发此方法
 *
 *  @param peripheral     外设
 *  @param characteristic 服务对应的特征
 *  @param error          错误
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    LogRed(@"%s", __FUNCTION__);
    [self dealError:error];
    // 此处读取描述即可
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        [peripheral readValueForDescriptor:descriptor];
    }
}

// 容错处理
- (void)dealError:(NSError *)error
{
    if (error) {
        LogRed(@"error - %@", error.localizedDescription);
        return;
    }
}


#pragma mark  自定义方法
#pragma mark -
#pragma mark - - 5.利用特征与外设做数据交互(Explore And Interact)
/**
 *  外设 写数据到特征中
 * [注意]: 需要判断, 特征的属性是否支持写入
 */
- (void)yf_peripheral:(CBPeripheral *)peripheral
         didWriteData:(NSData *)data
    forCharacteristic:(nonnull CBCharacteristic *)charcteristic
{
    /**
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast												= 0x01,
     CBCharacteristicPropertyRead													= 0x02,
     CBCharacteristicPropertyWriteWithoutResponse									= 0x04,
     CBCharacteristicPropertyWrite													= 0x08,
     CBCharacteristicPropertyNotify													= 0x10,
     CBCharacteristicPropertyIndicate												= 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites								= 0x40,
     CBCharacteristicPropertyExtendedProperties										= 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)		= 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)	= 0x200
     };
     */
    LogYellow(@"char.pro = %d", charcteristic.properties);
    // 由于枚举属性是 NS_OPTIONS类型, 所有一个枚举可能对应多个类型, 判断不能用 = , 应该用&(包含)
    if (charcteristic.properties & CBCharacteristicPropertyWrite) {
        // 核心代码 ---
        [peripheral writeValue:data // 写入的数据
             forCharacteristic:charcteristic // 特征
                          type:CBCharacteristicWriteWithResponse]; // 通过此响应记录是否成功写入
    }
}

#pragma mark -
#pragma mark - - 6.订阅Characteristic的通知
// 订阅通知和取消订阅
// [注意]: 一般根据项目的具体需求确定, 以下方法在哪调用
- (void)yf_peripheral:(CBPeripheral *)peripheral regNotifyWithCharacteristic:(nonnull CBCharacteristic *)charcteristic
{
    // 外设为特征 订阅通知
    // 触发: - didUpdateValueForCharacteristic:方法
    [peripheral setNotifyValue:YES forCharacteristic:charcteristic];
}

- (void)yf_peripheral:(CBPeripheral *)peripheral cancelNotifyWithCharacteristic:(nonnull CBCharacteristic *)charcteristic
{
    // 外设为特征 取消订阅通知
    // 触发: - didUpdateValueForCharacteristic:方法
    [peripheral setNotifyValue:NO forCharacteristic:charcteristic];
}


#pragma mark -
#pragma mark - - 7.断开连接(Disconnect)
- (void)yf_dismissConnectedWithPeripheral:(CBPeripheral *)peripheral
{
    // 停止扫描
    [self.cMgr stopScan];
    
    // 断开连接
    [self.cMgr cancelPeripheralConnection:peripheral];
}

@end
