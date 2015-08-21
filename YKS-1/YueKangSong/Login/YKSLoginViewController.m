//
//  YKSLoginViewController.m
//  YueKangSong
//
//  Created by gongliang on 15/5/15.
//  Copyright (c) 2015年 YKS. All rights reserved.
//

#import "YKSLoginViewController.h"
#import "GZBaseRequest.h"
#import "YKSTools.h"
#import "YKSUserModel.h"

@interface YKSLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UITextField *codeTextField;
@property (weak, nonatomic) IBOutlet UIButton *codeButton;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSInteger time;

@end

@implementation YKSLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.phoneTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_timer invalidate];
    _timer = nil;
}

#pragma mark - custom
- (void)senderShow:(NSTimer *)timer {
    [_codeButton setTitle:[NSString stringWithFormat:@"%zds", _time]
                 forState:UIControlStateNormal];
    if (_time <= 0.0) {
        [timer invalidate];
        timer = nil;
        [_codeButton setTitle:@"重新获取验证码"
                     forState:UIControlStateNormal];
    }
    _time --;
}

#pragma mark - IBOutlets
- (IBAction)verifyCodeAction:(UIButton *)sender {
    if (IS_EMPTY_STRING(_phoneTextField.text)) {
        [self showToastMessage:@"手机号不能为空"];
        return;
    }
    if (![YKSTools mobilePhoneFormatter:_phoneTextField.text]) {
        [self showToastMessage:@"手机格式不正确"];
        return;
    }
    
    if ([sender.titleLabel.text isEqualToString:@"获取验证码"] ||
        [sender.titleLabel.text isEqualToString:@"重新获取验证码"]) {
        [sender setBackgroundImage:[UIImage imageNamed:@"verifyCode_selected"] forState:UIControlStateNormal];
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                  target:self
                                                selector:@selector(senderShow:)
                                                userInfo:nil
                                                 repeats:YES];
        _time = 60;
        [_timer fire];
        [GZBaseRequest verifyCodeByMobilephone:_phoneTextField.text
                                      callback:^(id responseObject, NSError *error) {
                                          if (error) {
                                              [self showToastMessage:@"网络加载失败"];
                                              return ;
                                          }
                                          if (ServerSuccess(responseObject)) {
                                              [self showToastMessage:@"验证码已发送至手机"];
                                              [self.codeTextField becomeFirstResponder];
                                          } else {
                                              [self showToastMessage:responseObject[@"msg"]];
                                          }
                                      }];
    }
}

- (IBAction)loginAction:(id)sender {
    if (IS_EMPTY_STRING(_codeTextField.text)) {
        [self showToastMessage:@"验证码不能为空"];
        return;
    }
    if (IS_EMPTY_STRING(_phoneTextField.text)) {
        [self showToastMessage:@"手机号不能为空"];
        return;
    }
    if (![YKSTools mobilePhoneFormatter:_phoneTextField.text]) {
        [self showToastMessage:@"手机格式不正确"];
        return;
    }
    [self showProgress];
    [GZBaseRequest loginByMobilephone:_phoneTextField.text
                             password:_codeTextField.text
                             callback:^(id responseObject, NSError *error) {
                                 [self hideProgress];
                                 if (error) {
                                     [self showToastMessage:@"网络加载失败"];
                                     return ;   
                                 }
                                 if (ServerSuccess(responseObject)) {
                                     NSLog(@"responseObject = %@", responseObject);
                                     [self showToastMessage:@"登录成功"];
                                     [YKSUserModel loginSuccess:@{@"phone": _phoneTextField.text}];
                                     [self.navigationController popViewControllerAnimated:YES];
                                 } else {
                                     [self showToastMessage:responseObject[@"msg"]];
                                 }
    }];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
