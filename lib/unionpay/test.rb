require 'restclient'
Module OpenSSL
    Module SSL
        VERIFY_PEER=VERIFY_NONE
    end
end
params={
name: "hello"
}
url="https://101.231.204.80:5000/gateway/api/appTransReq.do"
p stClient.post(url,params)
