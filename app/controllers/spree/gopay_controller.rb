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
        payment_success(order, id, gopay_order["state"] == "PAID")
        session[:order_id] = nil

        redirect_to order_path(order)
      else
        flash[:error] = Spree.t(:payment_has_been_cancelled)
        redirect_to checkout_path
      end
    end

    private

    def payment_success(order, id, complete_payment = false)
      order.with_lock do
        payment_method = Spree::PaymentMethod.where(type: "Spree::PaymentMethod::Gopay").first
        payments = order.payments.reload.where(payment_method: payment_method)
        payment = payments.last
        
        if !payment.present?
          payment = payments.create!({
            amount: order.total,
            payment_method: Spree::PaymentMethod.where(type: "Spree::PaymentMethod::Gopay").first
          })
        end
        
        until order.state == "complete"
          if order.next!
            order.update_with_updater!
          end
        end

        payment.update!({response_code: id})

        if complete_payment
          payment.complete!
        else
          payment.pend!
        end
      end
    end  

  end
end