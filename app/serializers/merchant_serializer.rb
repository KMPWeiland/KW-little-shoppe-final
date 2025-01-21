class MerchantSerializer
  include JSONAPI::Serializer
  attributes :name

  attribute :item_count, if: Proc.new { |merchant, params|
    params && params[:count] == true
  } do |merchant|
    merchant.item_count
  end

  attribute :coupons_count do |merchant|
    merchant.coupons.count
  end

  attribute :invoice_coupon_count do |merchant|
    merchant.invoices.joins(:coupon).where(coupons: {active: true}).count    
  end
end
