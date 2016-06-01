require '../unionpay'

UnionPay.environment  = :production    ## 测试环境， :pre_production  #预上线环境， 默认 # 线上环境
UnionPay.mer_id       = ENV['UNION_PAY_MER_ID']
UnionPay.cert_id      = ENV['UNION_PAY_CERT_ID']
UnionPay.private_key  = File.read File.join('config', 'certs', 'unionpay.pem')
UnionPay.cer          = File.read File.join('config', 'certs', "unionpay.cer")
UnionPay.front_url    = "http://www.example.com/sdk/utf8/front_notify.php"
UnionPay.back_url     = "http://www.example.com/sdk/utf8/front_notify.php"