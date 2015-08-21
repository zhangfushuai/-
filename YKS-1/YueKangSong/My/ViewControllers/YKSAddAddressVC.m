//
//  YKSAddAddressVC.m
//  YueKangSong
//
//  Created by gongliang on 15/5/17.
//  Copyright (c) 2015年 YKS. All rights reserved.
//

#import "YKSAddAddressVC.h"
#import "GZBaseRequest.h"
#import "YKSAddressTextField.h"
#import "YKSAreaManager.h"
#import "YKSSearchView.h"
#import "YKSSearchStreetVC.h"

@interface YKSAddAddressVC () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *phoneField;
@property (weak, nonatomic) IBOutlet YKSAddressTextField *addressField;
@property (weak, nonatomic) IBOutlet UITextField *streetField; //街道
@property (weak, nonatomic) IBOutlet UITextField *detailAddressField;
@property (strong, nonatomic) NSDictionary *areaInfo;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (strong, nonatomic) YKSSearchView *searchView;
@property (weak, nonatomic) IBOutlet UITableViewCell *cell;
@property (strong, nonatomic) NSString *lastSearchKey;
@property (strong, nonatomic) NSDictionary *streetDic;

@end

@implementation YKSAddAddressVC

- (void)viewDidLoad {
    [super viewDidLoad];

    _streetField.placeholder = @"请输入小区、楼宇等地址关键字";
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(gotoSearchAddress)];
    _streetField.enabled = NO;
    [_streetField.superview addGestureRecognizer:tap];
    
    _detailAddressField.placeholder = @"请输入楼号、门牌号等详细地址";
    
//    _searchView = [[YKSSearchView alloc] initWithFrame:CGRectMake(0, 212, 280, 220)];
//    _searchView.backgroundColor = [UIColor yellowColor];
//    self.searchView.hidden = YES;
//    __weak YKSAddAddressVC *bself = self;
//    _searchView.callback = ^(NSDictionary *dic) {
//        bself.streetField.text = dic[@"name"];
//        [bself.view endEditing:YES];
//    };
//    [self.view addSubview:_searchView];
    
    [_streetField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    if (!_addressInfo) {
        self.tableView.tableFooterView = nil;
    } else {
        self.tableView.tableFooterView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 80);
        _nameField.text = _addressInfo[@"express_username"];
        _phoneField.text = _addressInfo[@"express_mobilephone"];
        _streetField.text = _addressInfo[@"community"];
        _detailAddressField.text = _addressInfo[@"express_detail_address"];
    }
    
    if (_isCurrentLocation) {
        self.tableView.tableFooterView = nil;
        _nameField.text = @"";
        _phoneField.text = @"";
        _streetField.text = _addressInfo[@"express_detail_address"];
        _detailAddressField.text = @"";
//        _addressField.text = @"";
    }
    
    
    [YKSAreaManager getBeijingAreaInfo:^(NSDictionary *areaInfo) {
        NSArray *datas = areaInfo[@"county"][[areaInfo[@"city"] firstObject][@"code"]];
        //_addressField.datas = datas;
        _areaInfo = areaInfo;
        if (_addressInfo) {
            if (_addressInfo[@"district"]) {
                //_addressField.text = _addressInfo[@"district"];
                _nameField.text = @"";
            }
            [datas enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if (_addressInfo[@"county"] ) {
                    if ([obj[@"code"] integerValue] == [_addressInfo[@"county"] integerValue]) {
                        //_addressField.text = obj[@"name"];
                        *stop = YES;
                    }
                }
                if (_isCurrentLocation){
                    if ([_addressInfo[@"district"] isEqualToString:obj[@"name"]]) {
                        _addressInfo[@"county"] = obj[@"code"];
                    }
                }
                
            }];
        }
    }];
    
}

#pragma mark - 
- (void)gotoSearchAddress {
    [self performSegueWithIdentifier:@"gotoYKSSearchStreetVC" sender:nil];
}

#pragma mark - IBOutlets
- (IBAction)confirm:(id)sender {
    [self.view endEditing:YES];
    if (IS_EMPTY_STRING(_nameField.text)) {
        [self showToastMessage:@"请填写收货人"];
        return ;
    }
    if (IS_EMPTY_STRING(_phoneField.text)) {
        [self showToastMessage:@"请填写手机号"];
        return;
    }
    if (![YKSTools mobilePhoneFormatter:_phoneField.text]) {
        [self showToastMessage:@"手机格式不正确"];
        return;
    }
//    if (IS_EMPTY_STRING(_addressField.text)) {
//        [self showToastMessage:@"请选择地区"];
//        return ;
//    }
    
    if (IS_EMPTY_STRING(_streetField.text)) {
        [self showToastMessage:@"请填写街道"];
        return;
    }
    if (IS_EMPTY_STRING(_detailAddressField.text)) {
        [self showToastMessage:@"请填写详细地址"];
        return;
    }
    
    NSString *areaCode = [NSString stringWithFormat:@"%@,%@,%@", _areaInfo[@"province"][@"code"], [_areaInfo[@"city"] firstObject][@"code"], @"110105"];
    NSString *latLng = [NSString stringWithFormat:@"%@,%@", _streetDic[@"location"][@"lat"], _streetDic[@"location"][@"lng"]];
    NSString *detailAddress = [NSString stringWithFormat:@"%@%@%@", _streetDic[@"address"], _streetDic[@"name"], _detailAddressField.text];
    
    if (!_addressInfo || _isCurrentLocation) {
        [GZBaseRequest addAddressExpressArea:areaCode
                                   community:_streetField.text
                             communityLatLng:latLng
                               detailAddress:detailAddress
                                    contacts:_nameField.text
                                   telePhone:_phoneField.text
                                    callback:^(id responseObject, NSError *error) {
                                        [self hideProgress];
                                        if (error) {
                                            [self showToastMessage:@"网络加载失败"];
                                            return ;
                                        }
                                        if (ServerSuccess(responseObject)) {
                                            [self.navigationController showToastMessage:@"添加成功"];
                                            
                                            if (_callback) {
                                                _callback();
                                            }
                                            [self.navigationController popViewControllerAnimated:YES];
                                            NSLog(@"添加成功收货地址 = %@", responseObject);
                                        } else {
                                            [self showToastMessage:responseObject[@"msg"]];
                                        }
                                    }];
    } else {
        [GZBaseRequest editAddressById:_addressInfo[@"id"]
                           expressArea:areaCode
                             community:_streetField.text
                       communityLatLng:latLng
                         detailAddress:detailAddress
                              contacts:_nameField.text
                             telePhone:_phoneField.text
                              callback:^(id responseObject, NSError *error) {
                                  [self hideProgress];
                                  if (error) {
                                      [self showToastMessage:@"网络加载失败"];
                                      return ;
                                  }
                                  if (ServerSuccess(responseObject)) {
                                      [self.navigationController showToastMessage:@"更新成功"];
                                      [self.navigationController popViewControllerAnimated:YES];
                                      NSLog(@"更改收货地址成功 = %@", responseObject);
                                  } else {
                                      [self showToastMessage:responseObject[@"msg"]];
                                  }
                              }];
    }
}

- (IBAction)deleteAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"确定删除"
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"取消", @"确定", nil];
    [alertView show];
    [alertView callBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self showProgress];
            [GZBaseRequest deleteAddressById:_addressInfo[@"id"]
                                    callback:^(id responseObject, NSError *error) {
                                        [self hideProgress];
                                        if (error) {
                                            [self showToastMessage:@"网络加载失败"];
                                            return ;
                                        }
                                        if (ServerSuccess(responseObject)) {
                                            [self.navigationController showToastMessage:@"删除成功"];
                                            [self.navigationController popViewControllerAnimated:YES];
                                            NSLog(@"删除收货地址成功 = %@", responseObject);
                                        } else {
                                            [self showToastMessage:responseObject[@"msg"]];
                                        }
                                    }];
        }
    }];
}

- (IBAction)tapAction:(id)sender {
    NSLog(@"self.streetField.isFirstResponder = %d", self.streetField.isFirstResponder);
    if (!self.streetField.isFirstResponder) {
        self.searchView.hidden = YES;
    }
    [self.view endEditing:YES];
}

- (void)textFieldDidChange:(UITextField *)textField {
    NSString *street = textField.text;
    if (![_lastSearchKey isEqualToString:textField.text]) {
        NSLog(@"text = %@", textField.text);
        _lastSearchKey = textField.text;
        if (street.length > 0) {
            [[GZHTTPClient shareClient] GET:BaiduMapPlaceApi
                                 parameters:@{@"region": @"北京",
                                              @"query": _lastSearchKey,
                                              @"ak": BaiduMapAK,
                                              @"output": @"json"}
                                    success:^(NSURLSessionDataTask *task, id responseObject) {
                                        if (responseObject && [responseObject[@"status"] integerValue] == 0) {
                                            _searchView.hidden = NO;
                                            _searchView.searchDatas = responseObject[@"results"];
                                            [_searchView.tableView reloadData];
                                        }
                                        NSLog(@"responseObject %@", responseObject);
                                    }
                                    failure:^(NSURLSessionDataTask *task, NSError *error) {
                                        NSLog(@"error = %@", error);
                                    }];
        } else {
            _searchView.hidden = YES;
        }
    }
    
}


#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
    });
    
    return YES;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:self.searchView] || [touch.view isDescendantOfView:self.tableView]) {
        return NO;
    }
    return YES;
}


 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if ([segue.identifier isEqualToString:@"gotoYKSSearchStreetVC"]) {
         YKSSearchStreetVC *vc = segue.destinationViewController;
         vc.hidesBottomBarWhenPushed = YES;
//         YKSSearchStreetVC *vc = (YKSSearchStreetVC *)[navigationController topViewController];
         vc.callback = ^(NSDictionary *street){
             _streetDic = street;
             _streetField.text = _streetDic[@"name"];
         };
     }
 }

@end
