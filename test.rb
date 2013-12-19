#encoding:utf-8
require './unionpay'

param = {}
param['transType']             = UnionPay::Conf::CONSUME;                         #交易类型，CONSUME or PRE_AUTH
param['orderAmount']           = 11000;                                          #交易金额
param['orderNumber']           = Time.now.strftime('%Y%m%d%H%M%S')               #订单号，必须唯一
param['customerIp']            = '127.0.0.1'
param['frontEndUrl']           = "http://www.example.com/sdk/utf8/front_notify.php"    #前台回调URL
param['backEndUrl']            = "http://www.example.com/sdk/utf8/back_notify.php"     #后台回调URL

# 可填空字段
#   param['commodityUrl']          = "http://www.example.com/product?name=商品"   #商品URL
#   param['commodityName']         = '商品名称'         # 商品名称
#   param['commodityUnitPrice']   = 11000;        //商品单价
#   param['commodityQuantity']    = 1;            //商品数量
#

# 其余可填空的参数可以不填写
t s
UnionPay.mer_id = '105550149170027'
UnionPay.mer_abbr = '商户名称'         # '104110548991233'
UnionPay.security_key = '88888888'    #'W38UCQOW83URMOQWI3URXMOQIUEXRIQJQXR'


puts UnionPay::Service.front_pay(param).form{"<input type='submit' />"}