//
//  InterfaceController.m
//  Z8Remote WatchKit Extension
//
//  Created by Quinn Ebert on 2015-06-16.
//  Copyright (c) 2015 Quinn Ebert Networked Technology manufactured for Quinn Ebert. All rights reserved.
//

#import "InterfaceController.h"


@interface InterfaceController()

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [self full_update];
    
    self.tmr = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(update_tick:) userInfo:nil repeats:YES];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)slider_update:(float)value {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://192.168.1.8:8888/endpoint/?volume=%i", (int) value]];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
    
    [self full_update];
}

- (void)update_tick:(NSTimer *)timer {
    [self full_update]; 
}

- (void)full_update {
    NSURL *url = [NSURL URLWithString:@"http://192.168.1.8:8888/endpoint/"];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil] options:0 error:nil];
    [self.lblSource setText:[@"  " stringByAppendingString:[dic valueForKey:@"source"]]];
    [self.lblVolume setText:[@"  " stringByAppendingString:[dic valueForKey:@"volume"]]];
    [self.slider setValue:[[dic valueForKey:@"volume"] floatValue]];
}

@end



