Spree::CheckoutController.class_eval do

  before_filter :pay_with_gopay, only: :update

  private

  def pay_with_gopay
    return unless params[:state] == 'payment'

    pm_id = params[:order][:payments_attributes].first[:payment_method_id]
    payment_method = Spree::PaymentMethod.find(pm_id)

    if payment_method && payment_method.kind_of?(Spree::PaymentMethod::Gopay)
      items_hash = @order.line_items.collect do |item|
        {
          name: "#{item.name} - #{item.quantity}x",
          amount: (item.quantity * item.price * 100).to_i
        }
      end

      shipment_cost = @order.shipments.to_a.sum(&:discounted_cost)

      items_hash << {
        name: Spree.t(:shipping_total),
        amount: (shipment_cost * 100).to_i
      } if shipment_cost > 0

      items_hash << {
        name: Spree.t(:tax),
        amount: (@order.additional_tax_total * 100).to_i
      } if @order.additional_tax_total > 0

      order = SpreeGopayIntegration::Gopayapi.create_payment({
          target: {
            type: "ACCOUNT",
            goid: SpreeGopayIntegration.configuration.goid
          },
          payer: {
            contact: {
              email: @order.email,
              first_name: @order.bill_address.firstname,
              last_name: @order.bill_address.lastname,
              phone_number: @order.bill_address.phone,
              street: @order.bill_address.address1,
              city: @order.bill_address.city,
              postal_code: @order.bill_address.zipcode,
              country_code: @order.bill_address.country.iso
            }
          },
          amount: (@order.total * 100).to_i,
          currency: @order.currency,
          order_number: @order.number,
          order_description: @current_store.name,
          items: items_hash,
          callback: {
            return_url: gopay_continue_url,
            notification_url: gopay_notify_url
          },
          lang: I18n.locale
        })

      if order["state"] != "CREATED"
        raise "Failed to create gopay order."
      end

      redirect_to order["gw_url"]
    end

  rescue StandardError => e
    gopay_error(e)
  end

  def gopay_error(e = nil)
    @order.errors[:base] << "GoPay error #{e.try(:message)}"
    render :edit
  end

end
