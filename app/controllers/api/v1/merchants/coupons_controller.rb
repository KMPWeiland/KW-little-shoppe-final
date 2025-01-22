class Api::V1::Merchants::CouponsController < ApplicationController
  rescue_from StandardError do |e|
    render json: ErrorSerializer.format_errors([e.message]), 
           status: :unprocessable_entity
  end
  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: ErrorSerializer.format_not_found(e), status: :not_found
  end
  

  
  def index
    merchant = Merchant.find(params[:merchant_id])
    coupons = merchant.coupons  
    coupons = coupons.filter_by_active(params[:active]) if params[:active].present?
       
    # if params[:active].present?
    #   coupons = coupons.filter_by_active(params[:active])
    # end
  
    render json: CouponSerializer.new(coupons)

  # rescue ActiveRecord::RecordNotFound
  #     render json: { error: 'Coupon not found' }, status: :not_found
  end

  def create 
    merchant = Merchant.find(params[:merchant_id])
    coupon = merchant.coupons.new(coupon_params)

    if coupon.save
      render json: CouponSerializer.new(coupon), status: :created
    else
      render json: { error: coupon.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def update
    merchant = Merchant.find(params[:merchant_id])
    coupon = merchant.coupons.find(params[:id])

    if coupon.toggle_active_status(merchant)
      render json: CouponSerializer.new(coupon)
    else
      render json: { errors: coupon.errors.full_messages}, 
      status: :unprocessable_entity
    end

    
    # new_active_status = !coupon.active

    # if new_active_status && coupon.more_than_five_active_coupons?(merchant)
    #   coupon.errors.add(:base, "This merchant already has 5 active coupons.")
    #   render json: { errors: coupon.errors.full_messages }, status: :unprocessable_entity
    # else
    #   coupon.update!(active: new_active_status)
    #   render json: coupon
    # end
    # rescue ActiveRecord::RecordNotFound => e
    # render json: { error: "Coupon not found" }, status: :not_found
    # rescue StandardError => e
    # render json: { error: e.message }, status: :unprocessable_entity
  end

  def show
    merchant = Merchant.find(params[:merchant_id])
    coupon = merchant.coupons.find(params[:id])

      # usage_count = coupon.invoices.count 

    render json: CouponSerializer.new(coupon), status: :ok 
    # rescue ActiveRecord::RecordNotFound
    #   render json: { error: 'Coupon not found' }, status: :not_found
  end

  private

  def coupon_params
    params.require(:coupon).permit(:full_name, :code, :percent_off, :dollar_off, :active)
  end

end

