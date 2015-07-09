//
//  ViewController.m
//  BLEFlashlight
//
//  Created by Don Coleman on 7/7/15.
//  Copyright (c) 2015 Don Coleman. All rights reserved.
//

#import "ViewController.h"
#import "LEDService.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;

@property (strong, nonatomic) CBMutableCharacteristic   *switchCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic   *dimmerCharacteristic;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Peripheral Methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Opt out from any other state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Bluetooth State != CBPeripheralManagerStatePoweredOn. Bailing out.");
        return;
    }
    
    // We're in CBPeripheralManagerStatePoweredOn state...
    NSLog(@"peripheralManager powered on.");
    
    // Build the service
    
    _switchCharacteristic = [[CBMutableCharacteristic alloc]
                             initWithType:[CBUUID UUIDWithString:SWITCH_CHARACTERISTIC_UUID]
                             properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead
                             value:nil
                             permissions:CBAttributePermissionsWriteable | CBAttributePermissionsReadable];
    
    CBMutableDescriptor *descriptor = [[CBMutableDescriptor alloc]
                                       initWithType: [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString]
                                       value:@"Switch"];
    
    _switchCharacteristic.descriptors = @[descriptor];
    
    _dimmerCharacteristic = [[CBMutableCharacteristic alloc]
                             initWithType:[CBUUID UUIDWithString:DIMMER_CHARACTERISTIC_UUID]
                             properties: CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite
                             value:nil
                             permissions:CBAttributePermissionsWriteable | CBAttributePermissionsReadable];
    
    descriptor = [[CBMutableDescriptor alloc]
                  initWithType: [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString]
                  value:@"Dimmer"];
    
    _dimmerCharacteristic.descriptors = @[descriptor];
    
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:LED_SERVICE_UUID] primary:YES];
    service.characteristics = @[_switchCharacteristic, _dimmerCharacteristic];
    
    [_peripheralManager addService:service];
    [_peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey : @[service.UUID]}];
    
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    NSLog(@"Added service %@", [service UUID]);
    if (error) {
        NSLog(@"There was an error adding service");
        NSLog(@"%@", error);
    }
}

- (void) peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog(@"Started advertising");
    if (error) {
        NSLog(@"There was an error advertising");
        NSLog(@"%@", error);
    }
    
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    NSLog(@"Received read request for %@", [request characteristic]);
    
    // TODO real code should check offsets and handle errors
    if ([request.characteristic.UUID isEqual:_switchCharacteristic.UUID]) {
        
        request.value = [_switchCharacteristic.value
                         subdataWithRange:NSMakeRange(request.offset,
                                                      _switchCharacteristic.value.length - request.offset)];
        
    } else if ([request.characteristic.UUID isEqual:_dimmerCharacteristic.UUID]) {
        request.value = _dimmerCharacteristic.value;

    }
    
    [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"Received %lu write request(s)", (unsigned long)[requests count]);
    
    // TODO real code needs to handle multiple requests (but only send one result)
    CBATTRequest *request = [requests firstObject];

    if ([request.characteristic.UUID isEqual:_switchCharacteristic.UUID]) {
        
        NSData *value = [request value];
        UInt8 bytes[1];
        [value getBytes:&bytes length:sizeof(bytes)];
        
        if (bytes[0] == 0x0) {
            [self light:NO];
        } else {
            [self light:YES];
        }
        
        _switchCharacteristic.value = request.value;
        [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        
    } else if ([request.characteristic.UUID isEqual:_dimmerCharacteristic.UUID]) {
            
        NSData *value = [request value];
        UInt8 bytes[1];
        [value getBytes:&bytes length:sizeof(bytes)];

        UInt8 brightness = bytes[0];
        if (brightness == 0) {
            [self light:FALSE];
        } else {
            [self setBrightness:brightness];
        }
        
        _dimmerCharacteristic.value = request.value;
        [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed from characteristic");
}


- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
}

#pragma mark - light

- (void) light: (bool) on {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (on) {
                [device setTorchMode:AVCaptureTorchModeOn];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
            }
            [device unlockForConfiguration];
            
        }
    }
}

- (void) setBrightness: (UInt8) level {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            float levelAsFloat = level/255.0;
            NSError *error = nil;
            [device setTorchModeOnWithLevel:levelAsFloat error:&error];
            [device unlockForConfiguration];
            
        }
    }
}

@end
