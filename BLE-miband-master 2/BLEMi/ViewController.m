//
//  ViewController.m
//  blueToothTestDemo
//
//  Created by apple on 8/7/16.
//  Copyright © 2016年 mark. All rights reserved.
//

#import "ViewController.h"

//4个字节Bytes 转 int
unsigned int  TCcbytesValueToInt(Byte *bytesValue) {
    unsigned int  intV;
    intV = (unsigned int ) ( ((bytesValue[3] & 0xff)<<24)
                            |((bytesValue[2] & 0xff)<<16)
                            |((bytesValue[1] & 0xff)<<8)
                            |(bytesValue[0] & 0xff));
    return intV;
}


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activeID;
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;
@property (weak, nonatomic) IBOutlet UITextView *resultTextV;

@end

@implementation ViewController

- (IBAction)stopShakeAction:(id)sender {
    if (thePerpher && theSakeCC) {
        Byte zd[1] = {0};
        NSData *theData = [NSData dataWithBytes:zd length:1];
        [thePerpher writeValue:theData forCharacteristic:theSakeCC type:CBCharacteristicWriteWithoutResponse];
    }
}

//震动
- (IBAction)shakeBankAction:(id)sender {
    if (thePerpher && theSakeCC) {
        Byte zd[1] = {2};
        NSData *theData = [NSData dataWithBytes:zd length:1];
        [thePerpher writeValue:theData forCharacteristic:theSakeCC type:CBCharacteristicWriteWithoutResponse];

    }
    
}

//断开连接Action
- (IBAction)disConnectAction:(id)sender {
    if(thePerpher)
    {
        [theManager cancelPeripheralConnection:thePerpher];
        thePerpher = nil;
        theSakeCC = nil;
        self.title = @"设备连接已断开";

    }
}

//开始连接action
- (IBAction)startConnectAction:(id)sender {
    
    if (theManager.state==CBCentralManagerStatePoweredOn) {
        NSLog(@"主设备蓝牙状态正常，开始扫描外设...");
        self.title = @"扫描小米手环...";
        //nil表示扫描所有设备
        [theManager scanForPeripheralsWithServices:nil options:nil];
        [self.activeID startAnimating];
        self.connectBtn.enabled = NO;
        self.resultTextV.text = @"";

    }

    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    theManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    self.connectBtn.enabled = NO;

}

#pragma mark -当前蓝牙主设备状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (central.state==CBCentralManagerStatePoweredOn) {
        self.title = @"蓝牙已就绪";
        self.connectBtn.enabled = YES;
    }else
    {
        self.title = @"蓝牙未准备好";
        [self.activeID stopAnimating];
        switch (central.state) {
            case CBCentralManagerStateUnknown:
                NSLog(@">>>CBCentralManagerStateUnknown");
                break;
            case CBCentralManagerStateResetting:
                NSLog(@">>>CBCentralManagerStateResetting");
                break;
            case CBCentralManagerStateUnsupported:
                NSLog(@">>>CBCentralManagerStateUnsupported");
                break;
            case CBCentralManagerStateUnauthorized:
                NSLog(@">>>CBCentralManagerStateUnauthorized");
                break;
            case CBCentralManagerStatePoweredOff:
                NSLog(@">>>CBCentralManagerStatePoweredOff");
                break;
                
            default:
                break;
        }
    }
    
    
    
}
//扫描到设备会进入方法
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"扫描连接外设：%@ %@",peripheral.name,RSSI);
    [central connectPeripheral:peripheral options:nil];
    if ([peripheral.name hasSuffix:@"MI"]) {
        thePerpher = peripheral;
        [central stopScan];
        [central connectPeripheral:peripheral options:nil];
        self.title = @"发现小米手环，开始连接...";
        self.resultTextV.text = [NSString stringWithFormat:@"发现手环：%@\n名称：%@\n",peripheral.identifier.UUIDString,peripheral.name];
    }
    
    
}
#pragma mark 设备扫描与连接的代理
//连接到Peripherals-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    self.title = @"连接成功，扫描信息...";
    NSLog(@"连接外设成功！%@",peripheral.name);
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    NSLog(@"开始扫描外设服务 %@...",peripheral.name);
    
}
//连接外设失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接到外设 失败！%@ %@",[peripheral name],[error localizedDescription]);
    [self.activeID stopAnimating];
    self.title = @"连接失败";
    self.connectBtn.enabled = YES;
    
}

//扫描到服务
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error)
    {
        NSLog(@"扫描外设服务出错：%@-> %@", peripheral.name, [error localizedDescription]);
        self.title = @"find services error.";
        [self.activeID stopAnimating];
        self.connectBtn.enabled = YES;
        
        return;
    }
    NSLog(@"扫描到外设服务：%@ -> %@",peripheral.name,peripheral.services);
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
    NSLog(@"开始扫描外设服务的特征 %@...",peripheral.name);
    
}
//扫描到特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"扫描外设的特征失败！%@->%@-> %@",peripheral.name,service.UUID, [error localizedDescription]);
        self.title = @"find characteristics error.";
        [self.activeID stopAnimating];
        self.connectBtn.enabled = YES;
        return;
    }
    
    NSLog(@"扫描到外设服务特征有：%@->%@->%@",peripheral.name,service.UUID,service.characteristics);
    //获取Characteristic的值
    for (CBCharacteristic *characteristic in service.characteristics){
        {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            //步数
            if ([characteristic.UUID.UUIDString isEqualToString:STEP])
            {
                [peripheral readValueForCharacteristic:characteristic];
            }
            
            //电池电量
            else if ([characteristic.UUID.UUIDString isEqualToString:BUTERY])
            {
                [peripheral readValueForCharacteristic:characteristic];
            }
            
            else if ([characteristic.UUID.UUIDString isEqualToString:SHAKE])
            {
                //震动
                theSakeCC = characteristic;
            }
            
            //设备信息
            else if ([characteristic.UUID.UUIDString isEqualToString:DEVICE])
            {
                [peripheral readValueForCharacteristic:characteristic];
            }
            
            
            
        }
    }
    
    
}


#pragma mark 设备信息处理
//扫描到具体的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error) {
        NSLog(@"扫描外设的特征失败！%@-> %@",peripheral.name, [error localizedDescription]);
        self.title = @"find value error.";
        return;
    }
    NSLog(@"%@ %@",characteristic.UUID.UUIDString,characteristic.value);
    if ([characteristic.UUID.UUIDString isEqualToString:STEP]) {
        Byte *steBytes = (Byte *)characteristic.value.bytes;  
        int steps = TCcbytesValueToInt(steBytes);
        NSLog(@"步数：%d",steps);
        self.resultTextV.text = [NSString stringWithFormat:@"%@步数：%d\n",self.resultTextV.text,steps];
    }
    else if ([characteristic.UUID.UUIDString isEqualToString:BUTERY])
    {
        Byte *bufferBytes = (Byte *)characteristic.value.bytes;
        int buterys = TCcbytesValueToInt(bufferBytes)&0xff;
        NSLog(@"电池：%d%%",buterys);
        self.resultTextV.text = [NSString stringWithFormat:@"%@电量：%d%%\n",self.resultTextV.text,buterys];
        
    }
    else if ([characteristic.UUID.UUIDString isEqualToString:DEVICE])
    {
        Byte *infoByts = (Byte *)characteristic.value.bytes;
        //这里解析infoByts得到设备信息
        
    }
    
    
    [self.activeID stopAnimating];
    self.connectBtn.enabled = YES;
    self.title = @"信息扫描完成";

    
}


//与外设断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"与外设备断开连接 %@: %@", [peripheral name], [error localizedDescription]);
    self.title = @"连接已断开";
    self.connectBtn.enabled = YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
