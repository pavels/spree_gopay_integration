module Spree
  class GopayController < Spree::BaseController
    protect_from_forgery except: [:notify, :continue]

    def notify
      id = params[:id]

      gopay_order = SpreeGopayIntegration::Gopayapi.get_payment_info(id)
      order = Spree::Order.friendly.find(gopay_order["order_number"])
      
      if gopay_order["state"] == "PAID"
        payment_success(order,id,true)
      end
      
      render text: "OK"
    end

    def continue
      id = params[:id]

      gopay_order = SpreeGopayIntegration::Gopayapi.get_payment_info(id)
      order = Spree::Order.friendly.find(gopay_order["order_number"])

      if(gopay_order["state"] == "PAYMENT_METHOD_CHOSEN" || gopay_order["state"] == "PAID")
        payment_success(order, id)
        session[:order_id] = nil

        redirect_to order_path(order)
      else
        redirect_to checkout_path
      end
    end

    private

      def payment_success(order, id, complete_payment = false)
        order.with_lock do

          if order.payments.count > 0            
            if complete_payment
              order.payments.last.complete!
              order.update!
            end

            return
          end

          payment_method = Spree::PaymentMethod.where(type: "Spree::PaymentMethod::Gopay").first
          
          payment = order.payments.build(
            payment_method_id: payment_method.id,
            amount: order.total,
            state: 'checkout'
          )

          payment.response_code = id

          payment.save
          order.next

          payment.pend!

          if complete_payment
            payment.complete!
          end

          order.update!
        end
      end  

  end
end