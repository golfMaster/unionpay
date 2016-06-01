require File.dirname(__FILE__) + '/unionpay/conf'
require File.dirname(__FILE__) + '/unionpay/service'
require File.dirname(__FILE__) + '/unionpay/version'
require File.dirname(__FILE__) + '/unionpay/utils'

module UnionPay
  class << self
    attr_accessor :mer_id, :cert_id, :private_key, :cer, :environment, :front_url, :back_url, :app_pay_url

    def verify_public_key_path= v
      UnionPay.public_key=OpenSSL::X509::Certificate.new(File.read v).public_key
    end

    def sign_private_key_path= v
      UnionPay.private_key
    end

    def environment= e
      case e
      ## 测试环境
      when :development
        self.front_pay_url = "https://101.231.204.80:5000/gateway/api/appTransReq.do"
        self.back_pay_url = "https://101.231.204.80:5000/gateway/api/backTransReq.do"
        self.query_url = "https://101.231.204.80:5000/gateway/api/queryTrans.do"
      ## 预上线环境
      when :pre_production
        self.front_pay_url = "http://www.epay.lxdns.com/UpopWeb/api/Pay.action"
        self.back_pay_url = "http://www.epay.lxdns.com/UpopWeb/api/BSPay.action"
        self.query_url = "http://www.epay.lxdns.com/UpopWeb/api/Query.action"
      ## 线上环境
      else
        self.front_pay_url = "https://gateway.95516.com/gateway/api/frontTransReq.do"
        self.back_pay_url = "https://gateway.95516.com/gateway/api/backTransReq.do"
        self.query_url = "https://gateway.95516.com/gateway/api/queryTrans.do"
        self.app_pay_url = "https://gateway.95516.com/gateway/api/appTransReq.do"
      end
    end
  end
  self.environment= :production
end
