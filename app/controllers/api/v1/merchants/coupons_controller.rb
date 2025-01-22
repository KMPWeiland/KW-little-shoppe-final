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

    render json: CouponSerializer.new(coupons)
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
  end

  def show
    merchant = Merchant.find(params[:merchant_id])
    coupon = merchant.coupons.find(params[:id])

    render json: CouponSerializer.new(coupon), status: :ok 
  end

  private

  def coupon_params
    params.require(:coupon).permit(:full_name, :code, :percent_off, :dollar_off, :active)
  end

end

