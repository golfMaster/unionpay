require 'minitest'
require "minitest/autorun"
require 'test_helper'

class UnionPay::ServiceTest < Minitest::Test
  
  def app_pay
    now = Time.now.strftime('%Y%m%d%H%M%S')
    UnionPay::Service.app_pay({'orderId' => now, 'txnTime' => now, 'txnAmt' => 100})
  end

  def front_pay
    now = Time.now.strftime('%Y%m%d%H%M%S')
    UnionPay::Service.app_pay({'orderId' => now, 'txnTime' => now, 'txnAmt' => 100})
  end

  def back_pay
    now = Time.now.strftime('%Y%m%d%H%M%S')
    UnionPay::Service.back_pay({'orderId' => now, 'origQryId' => now, 'txnAmt' => 100})
  end

  def test_generate_form
    assert_not_nil generate_form.form(target: '_blank', id: 'form'){"<input type='submit' />"}
  end

  def test_front_pay_generate_form_with_different_environment
    UnionPay.environment = :development
    dev_form = generate_form.form(target: '_blank', id: 'form'){"<input type='submit' />"}
    UnionPay.environment = :pre_production
    pro_form = generate_form.form(target: '_blank', id: 'form'){"<input type='submit' />"}
    assert dev_form != pro_form
  end

  def test_back_pay_service
    dev_form = generate_back_pay_service
    assert_not_nil dev_form.post
  end
  def test_response
    test = {
      "charset" => "UTF-8", "cupReserved" => "", "exchangeDate" => "",
      "exchangeRate" => "", "merAbbr" => "银联商城（公司）", "merId" => "105550149170027",
      "orderAmount" => "9300", "orderCurrency" => "156", "orderNumber" => "D201312240006",
      "qid" => "201312241123141054552", "respCode" => "00", "respMsg" => "Success!",
      "respTime" => "20131224112352", "settleAmount" => "9300", "settleCurrency" => "156",
      "settleDate" => "1224", "traceNumber" => "105455", "traceTime" => "1224112314",
      "transType" => "01", "version" => "1.0.0", "signMethod" => "MD5",
      "signature" => "5b19db55d07290c739de97cb117ce884",
    #  "controller" => "front_money_payment_records", "action" => "unionpay_notify"
    }
    assert UnionPay::Service.response(test).args['respCode'] == UnionPay::RESP_SUCCESS
  end

  def test_query
    assert_raise_message 'Bad signature returned!' do
      param = {}
      param['transType'] = UnionPay::CONSUME
      param['orderNumber'] = "20111108150703852"
      param['orderTime'] = "20111108150703"
      UnionPay.environment = :production
      query = UnionPay::Service.query(param)
      res = query.post
      UnionPay::Service.response res.body
    end
  end

end
