//
//  ViewController.m
//  WXPayTest
//
//  Created by Jerry Bao on 2/19/16.
//  Copyright © 2016 JerryInc. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)votePayAction:(id)sender {
#warning 填写微信支付服务端的接口信息
    NSString *URLString = [NSString stringWithFormat:@"http://yourserver/api"];
    NSDictionary *parameters = @{@"money": @"0.01"};

    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
//    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [manager POST:URLString parameters:parameters constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@", responseObject);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (responseObject[@"code"] == 0) {
            NSData *data = [responseObject[@"data"][@"parameters"] dataUsingEncoding:NSUTF8StringEncoding];
            NSString *res = [self jumpToBizPay:data];
            if( ![@"" isEqual:res] ){
                UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"支付失败" message:res delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                
                [alter show];
            }
        } else {
            UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"支付失败" message:responseObject delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            
            [alter show];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@", error.description);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"支付失败" message:@"网络错误" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alter show];
    }];
}

- (NSString *)jumpToBizPay:(NSData *)data {
    
    NSError *error = nil;
    if (data != nil) {
        NSMutableDictionary *dict = NULL;
        //IOS5自带解析类NSJSONSerialization从response中解析出数据放到字典中
        dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
        
        if(dict != nil){
            NSMutableString *retcode = [dict objectForKey:@"retcode"];
            if (retcode.intValue == 0){
                NSMutableString *stamp  = [dict objectForKey:@"timestamp"];
                
                //调起微信支付
                PayReq* req             = [[PayReq alloc] init];
                req.partnerId           = [dict objectForKey:@"partnerid"];
                req.prepayId            = [dict objectForKey:@"prepayid"];
                req.nonceStr            = [dict objectForKey:@"noncestr"];
                req.timeStamp           = stamp.intValue;
                req.package             = [dict objectForKey:@"package"];
                req.sign                = [dict objectForKey:@"sign"];
                [WXApi sendReq:req];
                //日志输出
                NSLog(@"appid=%@\npartid=%@\nprepayid=%@\nnoncestr=%@\ntimestamp=%ld\npackage=%@\nsign=%@",[dict objectForKey:@"appid"],req.partnerId,req.prepayId,req.nonceStr,(long)req.timeStamp,req.package,req.sign );
                return @"";
            }else{
                return [dict objectForKey:@"retmsg"];
            }
        }else{
            return @"服务器返回错误，未获取到json对象";
        }
    }else{
        return @"服务器返回错误";
    }
}

@end
