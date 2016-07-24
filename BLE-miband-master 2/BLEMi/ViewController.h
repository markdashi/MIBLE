//
//  ViewController.h
//  blueToothTestDemo
//
//  Created by apple on 8/7/16.
//  Copyright © 2016年 mark. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreBluetooth/CoreBluetooth.h>

#define STEP @"FF06"
#define BUTERY @"FF0C"
#define SHAKE @"2A06"
#define DEVICE @"FF01"

@interface ViewController : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBCentralManager *theManager;
    CBPeripheral *thePerpher;
    CBCharacteristic *theSakeCC;
}



@end

