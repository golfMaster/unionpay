#encoding:utf-8
require 'open-uri'
require 'digest'
require 'base64'
require 'rack'
require 'net/http'
require 'rest-client'
require 'openssl'
module UnionPay
  RESP_SUCCESS  = '00' #返回成功
  QUERY_SUCCESS = '0' #查询成功
  QUERY_FAIL    = '1'
  QUERY_WAIT    = '2'
  QUERY_INVALID = '3'
  class Service
    attr_accessor :args, :api_url
    
    #app预支付
    def self.app_pay(param)
      new.instance_eval do
        param['txnTime']          ||= Time.now.strftime('%Y%m%d%H%M%S')         #交易时间, YYYYmmhhddHHMMSS
        param['currencyCode']     ||= UnionPay::CURRENCY_CNY                    #交易币种，CURRENCY_CNY=>人民币
        param['txnType']          ||= UnionPay::CONSUME
        param['txnSubType']       ||= '01'
        param['bizType']          ||= '000201'
        param['channelType']      ||= '08'
        param['accessType']       ||= '0'
        param['certId']           ||= UnionPay.cert_id  
        param['frontUrl']         ||= UnionPay.front_url
        param['backUrl']          ||= UnionPay.back_url  
        param['merId']            ||= UnionPay.mer_id
        
        trans_type = param['txnType']
        if [UnionPay::CONSUME, UnionPay::PRE_AUTH].include? trans_type
          @api_url = UnionPay.app_pay_url
          self.args = PayParamsEmpty.merge(PayParams).merge(param)
          @param_check = UnionPay::PayParamsCheck
        else
          # 前台交易仅支持 消费 和 预授权
          raise("Bad trans_type for front_pay. Use back_pay instead")
        end

        request = service.post
        
        if request.response.success?
          {time: param['txnTime'], tn: Hash[*request.response.body.split("&").map{|a| a.gsub("==", "@@").split("=")}.flatten]['tn']}
        else
          return {time: param['txnTime'], tn: ""}
        end
      end
    end

    #预支付
    def self.front_pay(param)
      new.instance_eval do
        param['txnTime']          ||= Time.now.strftime('%Y%m%d%H%M%S')         #交易时间, YYYYmmhhddHHMMSS
        param['currencyCode']     ||= UnionPay::CURRENCY_CNY                    #交易币种，CURRENCY_CNY=>人民币
        param['txnType']          ||= UnionPay::CONSUME
        param['txnSubType']       ||= '01'
        param['bizType']          ||= '000201'
        param['channelType']      ||= '07'
        param['accessType']       ||= '0'
        param['certId']           ||= UnionPay.cert_id  
        param['frontUrl']         ||= UnionPay.front_url
        param['backUrl']          ||= UnionPay.back_url  
        param['merId']            ||= UnionPay.mer_id

        trans_type = param['txnType']
        
        if [UnionPay::CONSUME, UnionPay::PRE_AUTH].include? trans_type
          @api_url = UnionPay.front_pay_url
          self.args = PayParamsEmpty.merge(PayParams).merge(param)
          @param_check = UnionPay::PayParamsCheck
        else
          # 前台交易仅支持 消费 和 预授权
          raise("Bad trans_type for front_pay. Use back_pay instead")
        end
        
        request = service.post
        
        if request.response.success?
          {time: param['txnTime'], tn: Hash[*request.response.body.split("&").map{|a| a.gsub("==", "@@").split("=")}.flatten]['tn']}
        else
          return {time: param['txnTime'], tn: ""}
        end
      end
    end

    #退款
    def self.back_pay(param)
      new.instance_eval do
        param['txnTime']          ||= Time.now.strftime('%Y%m%d%H%M%S')         #交易时间, YYYYmmhhddHHMMSS
        param['currencyCode']     ||= UnionPay::CURRENCY_CNY                    #交易币种，CURRENCY_CNY=>人民币
        param['txnType']          ||= UnionPay::REFUND
        param['certId']           ||= UnionPay.cert_id    
        param['frontUrl']         ||= UnionPay.front_url
        param['backUrl']          ||= UnionPay.back_url  
        param['merId']            ||= UnionPay.mer_id
        
        
        @api_url = UnionPay.back_pay_url
        self.args = PayParamsEmpty.merge(PayParams).merge(param)
        @param_check = UnionPay::BackParamsCheck
        trans_type = param['txnType']
        if [UnionPay::CONSUME, UnionPay::PRE_AUTH].include? trans_type
          if !self.args['cardNumber'] && !self.args['pan']
            raise('consume OR pre_auth transactions need cardNumber!')
          end
        else
          raise('origQryId is not provided') if UnionPay.empty? self.args['origQryId']
        end
        
        request = service.post
        return Hash[*request.response.body.split("&").map{|a| a.gsub("==", "@@").split("=")}.flatten]
      end
    end
    

    #订单查询
    def self.query(param)
      new.instance_eval do
        param['bizType']          ||= '000201'  #业务类型——查询
        param['certId']           ||= UnionPay.cert_id  
        param['txnType']          ||= UnionPay::QUERY
        param['merId']            ||= UnionPay.mer_id
    
        @api_url = UnionPay.query_url
        if UnionPay.empty?(param['merId'])
          raise('merId can\'t be both empty')
        end
        
        self.args = PayParamsEmpty.merge(QueryParams).merge(param)
    
        @param_check = UnionPay::QueryParamsCheck

        request = service.post
        
        if request.response.success?
          code = Hash[*request.response.body.split("&").map{|a| a.gsub("==", "@@").split("=")}.flatten]['origRespCode']
        elsif request.response.timed_out?
          code = "got a time out"
        elsif request.response.code == 0
          code = request.response.return_message
        else
          code = request.response.code.to_s
        end
      end
    end
    

    #银联支付验签
    def self.verify params
      public_key = get_public_key_by_cert_id params['certId']
      return false if public_key.nil?

      signature_str = params['signature']
      p = params.reject{|k, v| k == "signature"}.sort.map{|key, value| "#{key}=#{value}" }.join('&')
      signature = Base64.decode64(signature_str)
      data = Digest::SHA1.hexdigest(p)
      digest = OpenSSL::Digest::SHA1.new
      public_key.verify digest, signature, data
    end
    
    # 银联支付 根据证书id返回公钥
    def self.get_public_key_by_cert_id cert_id
    	certificate = OpenSSL::X509::Certificate.new(UnionPay.cer) #读取cer文件
    	certificate.serial.to_s == cert_id ? certificate.public_key : nil #php 返回的直接是cer文件 UnionPay.cer
    end

    #解析response
    def self.response(param)
      new.instance_eval do
        if param.is_a? String
          param = Rack::Utils.parse_nested_query param
        end
        if param['respCode'] != "00"
          return false
        end
        if !param['signature'] || !param['signMethod']
          return false
        end
        sig=param.delete("signature").gsub(' ','+')
        sign_str = param.sort.map do |k,v|
          "#{k}=#{v}&"
        end.join.chop
        digest = OpenSSL::Digest::SHA1.new
        if !UnionPay.public_key.verify digest, Base64.decode64(sig), Digest::SHA1.hexdigest(sign_str)
          return false
        end
        param
      end
    end

    #生成签名
    def self.sign(param)
      data = Digest::SHA1.hexdigest(param.sort.map{|key, value| "#{key}=#{value}" }.join('&'))
      sign = Base64.encode64(OpenSSL::PKey::RSA.new(UnionPay.private_key).sign('sha1', data.force_encoding("utf-8"))).gsub("\n", "")
      return sign
    end

    #生成表单
    def form(options={})
      attrs = options.map { |k, v| "#{k}='#{v}'" }.join(' ')
      html = [
        "<form #{attrs} action='#{@api_url}' method='post'>"
      ]
      args.each do |k, v|
        html << "<input type='hidden' name='#{k}' value='#{v}' />"
      end
      if block_given?
        html << yield
      end
      html << "</form>"
      html.join
    end

    #post提交
    def post
      request = Typhoeus::Request.new(@api_url, method: :post, params: self.args, ssl_verifypeer: false, headers: {'Content-Type' =>'application/x-www-form-urlencoded'} )
      request.run
      return request
    end

    def [](key)
      self.args[key]
    end


    private
    def service
      if self.args['commodityUrl']
        self.args['commodityUrl'] = URI::encode(self.args['commodityUrl'])
      end

      arr_reserved = []
      UnionPay::MerParamsReserved.each do |k|
        arr_reserved << "#{k}=#{self.args.delete k}" if self.args.has_key? k
      end

      @param_check.each do |k|
        raise("KEY [#{k}] not set in params given") unless self.args.has_key? k
      end

      # signature
      self.args['signature']  = Service.sign(self.args)
      self
    end
  end
end
