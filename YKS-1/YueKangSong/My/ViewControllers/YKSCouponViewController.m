//
//  YKSCouponViewController.m
//  YueKangSong
//
//  Created by gongliang on 15/5/17.
//  Copyright (c) 2015年 YKS. All rights reserved.
//

#import "YKSCouponViewController.h"
#import "GZBaseRequest.h"
#import "YKSCouponListCell.h"
#import "YKSTools.h"
#import <MJRefresh/MJRefresh.h>

@interface YKSCouponViewController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) NSArray *datas;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;

@end

@implementation YKSCouponViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.tableFooterView.backgroundColor = self.tableView.backgroundColor;
    _textField.delegate = self;
    [YKSTools insertEmptyImage:@"other_empty" text:@"暂无优惠劵" view:self.view];
    _confirmButton.backgroundColor = kNavigationBar_back_color;
    _confirmButton.layer.masksToBounds = YES;
    _confirmButton.layer.cornerRadius = 5.0f;
    _confirmButton.backgroundColor = [UIColor lightGrayColor];
    
    [self requestDataByPage:1];
    __weak YKSCouponViewController *bself = self;
    [self.tableView addLegendHeaderWithRefreshingBlock:^{
        [bself requestDataByPage:1];
    }];
    // Do any additional setup after loading the view.
}

#pragma mark - custom
- (void)requestDataByPage:(NSInteger)page {
    [GZBaseRequest couponList:page
                     callback:^(id responseObject, NSError *error) {
                         if (page == 1) {
                             if (self.tableView.header.isRefreshing) {
                                 [self.tableView.header endRefreshing];
                             }
                         }
                         if (error) {
                             [self showToastMessage:@"网络加载失败"];
                             return ;
                         }
                         if (ServerSuccess(responseObject)) {
                             _datas = responseObject[@"data"][@"couponlist"];
                         } else {
                             [self showToastMessage:responseObject[@"msg"]];
                         }
                         
                         if (_datas.count > 0) {
                             self.tableView.hidden = NO;
                             [self.tableView reloadData];
                         } else {
                             self.tableView.hidden = YES;
                         }
                         NSLog(@"优惠劵列表 = %@", responseObject);
                     }];
}

#pragma mark - IBOutlets
- (IBAction)confirmAction:(id)sender {
    [self.view endEditing:YES];
    _confirmButton.backgroundColor = [UIColor lightGrayColor];

    if (IS_EMPTY_STRING(_textField.text)) {
        [self showToastMessage:@"请输入优惠劵编号"];
        return;
    }
    [GZBaseRequest convertCouponBByCode:_textField.text
                               callback:^(id responseObject, NSError *error) {
                                   NSLog(@"responseObject = %@", responseObject);
                                   if (error) {
                                       [self showToastMessage:@"网络加载失败"];
                                       return ;
                                   }
                                   if (ServerSuccess(responseObject)) {
                                       [self showToastMessage:@"兑换成功"];
                                       _textField.text = @"";
                                       [self requestDataByPage:1];
                                   } else {
                                       [self showToastMessage:responseObject[@"msg"]];
                                   }
                                   
    }];
}

#pragma mark - UITextField
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _confirmButton.backgroundColor = kNavigationBar_back_color;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    _confirmButton.backgroundColor = [UIColor lightGrayColor];
    return YES;
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YKSCouponListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"couponCell" forIndexPath:indexPath];
    NSDictionary *dic = _datas[indexPath.row];
    cell.priceLabel.attributedText = [YKSTools priceString:[dic[@"faceprice"] floatValue]
                                                 smallSize:17.0f
                                                 largeSize:35.0f];
    cell.nameLabel.text = dic[@"condition"];
    cell.timeLabel.text = [NSString stringWithFormat:@"有效期：%@", [YKSTools formatterDateStamp:[dic[@"etime"] integerValue]]];
    if ([dic[@"status"] integerValue] == 0) {
        [cell.topImageView setImage:[UIImage imageNamed:@"coupon_top2"]];
        cell.nameLabel.textColor = cell.timeLabel.textColor = cell.priceLabel.textColor = [UIColor lightGrayColor];
    } else {
        [cell.topImageView setImage:[UIImage imageNamed:@"coupon_top1"]];
        cell.nameLabel.textColor = cell.timeLabel.textColor = cell.priceLabel.textColor = [UIColor darkGrayColor];
        cell.priceLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([_datas[indexPath.row][@"status"] integerValue] == 0) {
        [self showToastMessage:@"无效的优惠劵"];
        return ;
    }
    if ([_datas[indexPath.row][@"is_used"] integerValue] == 1) {
        [self showToastMessage:@"优惠劵已使用"];
        return ;
    }
    NSString *fileLimit = _datas[indexPath.row][@"fileLimit"];
    if (!IS_EMPTY_STRING(fileLimit) && [fileLimit floatValue] > _totalPirce) {
        [self showToastMessage:@"未满足优惠劵使用条件"];
        return ;
    }
    if (_callback) {
        _callback(_datas[indexPath.row]);
        [self.navigationController popViewControllerAnimated:YES];
    }
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
