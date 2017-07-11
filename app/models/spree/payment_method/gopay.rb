module Spree
  class PaymentMethod::Gopay < PaymentMethod
    def payment_profiles_supported?
      false
    end

    def source_required?
      false
    end

    def auto_capture?
      false
    end

    # No user actions supported
    def actions
      []
    end

    def capture(amount, response_code, gateway_options)
      gopay_order = SpreeGopayIntegration::Gopayapi.get_payment_info(response_code)
      ActiveMerchant::Billing::Response.new(gopay_order["state"] == "PAID", gopay_order, {}, {})
    end

    def request_payment(order, continue_url, notify_url)
      items_hash = order.line_items.collect do |item|
        {
          name: "#{item.name} - #{item.quantity}x",
          amount: (item.quantity * item.price * 100).to_i
        }
      end

      shipment_cost = order.shipments.to_a.sum(&:discounted_cost)

      items_hash << {
        name: Spree.t(:shipping_total),
        amount: (shipment_cost * 100).to_i
      } if shipment_cost > 0

      items_hash << {
        name: Spree.t(:tax),
        amount: (order.additional_tax_total * 100).to_i
      } if order.additional_tax_total > 0

      adjustment = ( (order.total * 100) - items_hash.map{|i| i[:amount]}.sum ) * -1

      items_hash << {
        name: Spree.t(:adjustment),
        amount: adjustment.to_i
      } if adjustment > 0

      payment = SpreeGopayIntegration::Gopayapi.create_payment({
          target: {
            type: "ACCOUNT",
            goid: SpreeGopayIntegration.configuration.goid
          },
          payer: {
            contact: {
              email: order.email,
              first_name: order.bill_address.firstname,
              last_name: order.bill_address.lastname,
              phone_number: order.bill_address.phone,
              street: order.bill_address.address1,
              city: order.bill_address.city,
              postal_code: order.bill_address.zipcode,
              country_code: order.bill_address.country.iso3
            }
          },
          amount: (order.total * 100).to_i,
          currency: order.currency,
          order_number: order.number,
          order_description: Store.current.name,
          items: items_hash,
          callback: {
            return_url: continue_url,
            notification_url: notify_url
          },
          lang: I18n.locale
        })

      return payment 
    end

    def cancel(response)
      spree_payment = Spree::Payment.where(response_code: response).first
      refund = SpreeGopayIntegration::Gopayapi.refund_payment(spree_payment.response_code, (spree_payment.amount * 100).to_i)

      if refund["result"] == "FINISHED"
        ActiveMerchant::Billing::Response.new(true, 'Refund Successful', refund.to_hash)
      else
        ActiveMerchant::Billing::Response.new(false, refund["errors"].collect{ |e| e["message"] }.join(' '), refund.to_hash)
      end
    end
  end
end
