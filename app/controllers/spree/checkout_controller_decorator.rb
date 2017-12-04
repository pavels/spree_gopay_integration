Spree::CheckoutController.class_eval do

  before_action :gopay_hook, only: :update, if: proc { params[:state].eql?('payment') }

  private

  def pay_with_gopay(payment_method)
    payment = payment_method.request_payment(@order, gopay_continue_url, gopay_notify_url)

    if payment["state"] != "CREATED"
      raise "Failed to create gopay order."
    end

    redirect_to payment["gw_url"]
  rescue StandardError => e
    gopay_error(e)
  end

  def gopay_error(e = nil)
    @order.errors[:base] << "GoPay error #{e.try(:message)}"
    render :edit
  end

  def gopay_hook
    return unless params[:order] && params[:order][:payments_attributes]
    payment_method = Spree::PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
    if payment_method.kind_of?(Spree::PaymentMethod::Gopay)
      if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
        pay_with_gopay(payment_method)
      end
    end    
  end

end
