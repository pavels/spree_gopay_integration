module SpreeGopayIntegration  
  class Gopayapi
    require 'uri'

    class << self

      def create_payment(payment_hash)
        call_gopay("payments/payment", payment_hash)
      end

      def get_payment_info(payment_id)
        call_gopay("payments/payment/#{payment_id}")
      end

      def refund_payment(payment_id, amount)
        call_gopay("payments/payment/#{payment_id}/refund", {amount: amount})
      end

      private
      def gopay_uri_base
        uri = ""
        if SpreeGopayIntegration.configuration.environment.to_sym == :test
          uri = "https://gw.sandbox.gopay.com/api"
        else
          uri = "https://gate.gopay.cz/api"
        end
        return uri
      end

      def get_auth_token
        uri = gopay_uri_base
        uri = URI.parse("#{uri}/oauth2/token")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri.request_uri)
        request.basic_auth(SpreeGopayIntegration.configuration.client_id, SpreeGopayIntegration.configuration.client_secret)
        request.set_form_data({"grant_type" => "client_credentials", "scope" => "payment-all"})

        response = http.request(request)

        response_data = JSON.parse(response.body)

        return response_data
      end

      def call_gopay (target, data = nil)
        uri = gopay_uri_base
        uri = URI.parse("#{uri}/#{target}")

        token = get_auth_token

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = nil

        if data.nil?
          request = Net::HTTP::Get.new(uri.request_uri)
        else
          request = Net::HTTP::Post.new(uri.request_uri)
          request["Content-Type"] = "application/json"
          request.body = data.to_json          
        end
        
        request['Authorization'] = "Bearer #{token["access_token"]}"        
        
        response = http.request(request)
        response_data = JSON.parse(response.body)

        return response_data
      end

    end
  end
end