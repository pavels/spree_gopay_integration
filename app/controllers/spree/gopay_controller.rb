module Spree
  class GopayController < Spree::BaseController
    protect_from_forgery except: [:notify, :continue]

    def notify
      id = params[:id]

      gopay_order = SpreeGopayIntegration::Gopayapi.get_payment_info(id)

      order = Spree::Order.friendly.find(gopay_order["order_number"])
      payment = order.payments.last

      if gopay_order["state"] == "PAID"
          payment_success(order,id)
          payment.complete!         
      end
      
      render text: "OK"
    end

    def return
      id = params[:id]

      gopay_order = SpreeGopayIntegration::Gopayapi.get_payment_info(id)

      order = Spree::Order.friendly.find(gopay_order["order_number"])

      if(gopay_order["state"] == "PAYMENT_METHOD_CHOSEN" || gopay_order["state"] == "PAID")
        payment_success(order, id)
        redirect_to order_path(order)
        return
      end

      redirect_to checkout_path
    end

    private

      def payment_success(order, id)

        return if order.payments.count > 0

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

      end   
  end
end