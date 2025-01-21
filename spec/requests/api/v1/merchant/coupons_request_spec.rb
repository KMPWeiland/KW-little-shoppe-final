require "rails_helper"

RSpec.describe "Merchant Coupons API", type: :request do
    
  describe "Index -- GET /api/v1/merchants/:merchant_id/coupons" do
    it "returns all of a merchant's coupons" do
      merchant = create(:merchant)
  
      coupon1 = create(:coupon, merchant: merchant, full_name: "Spring Sale", code: "SPRING10")    
      coupon2 = create(:coupon, merchant: merchant, full_name: "A Spring Sale", code: "SPRING11")
      coupon3 = create(:coupon, merchant: merchant, full_name: "The Spring Sale", code: "SPRING12")

      get "/api/v1/merchants/#{merchant.id}/coupons"
      

      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_successful
      expect(json[:data].count).to eq(3)
      expect(json[:data][0][:attributes][:full_name]).to eq(coupon1.full_name)
      expect(json[:data][0][:id]).to eq(coupon1.id.to_s)
      expect(json[:data][1][:id]).to eq(coupon2.id.to_s)
      expect(json[:data][2][:id]).to eq(coupon3.id.to_s)
    end

    it "should filter all of a merchants coupons for active coupons" do
      merchant = create(:merchant)
      4.times { create(:coupon, merchant: merchant, active: true) }
      9.times { create(:coupon, merchant: merchant, active: false) }
      
      get "/api/v1/merchants/#{merchant.id}/coupons?active=true"      

      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_successful
      expect(json[:data].count).to eq(4)
      expect(json[:data][0][:attributes][:active]).to eq(true)
      expect(json[:data][1][:attributes][:active]).to eq(true)
      expect(json[:data][2][:attributes][:active]).to eq(true)
      expect(json[:data][3][:attributes][:active]).to eq(true)
    end

    it "should filter all of a merchants coupons for inactive coupons" do
      merchant = create(:merchant)
      4.times { create(:coupon, merchant: merchant, active: true) }
      9.times { create(:coupon, merchant: merchant, active: false) }
      
      get "/api/v1/merchants/#{merchant.id}/coupons?active=false"      

      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_successful
      expect(json[:data].count).to eq(9)
      expect(json[:data][4][:attributes][:active]).to eq(false)
      expect(json[:data][5][:attributes][:active]).to eq(false)
      expect(json[:data][6][:attributes][:active]).to eq(false)
    end
  end

  describe "Create a Coupon -- POST /api/v1/merchants/:merchant_id/coupons" do
    it "should create a coupon when all fields are provided" do
      merchant = create(:merchant)
      coupon_attributes = attributes_for(:coupon, full_name: "Spring Sale", code: "SPRING10")

      post "/api/v1/merchants/#{merchant.id}/coupons", params: { coupon: coupon_attributes }
  
      json = JSON.parse(response.body, symbolize_names: true)
  
      expect(response).to have_http_status(:created)
      expect(json[:data][:attributes][:full_name]).to eq("Spring Sale")
      expect(json[:data][:attributes][:code]).to eq("SPRING10")
    end

    it "should return an error if coupon code has already been taken" do
      merchant = create(:merchant)
      coupon1 = create(:coupon, merchant: merchant, full_name: "A Spring Sale", code: "SPRING10")
      coupon_attributes = attributes_for(:coupon, full_name: "Spring Sale", code: "SPRING10")      

      post "/api/v1/merchants/#{merchant.id}/coupons", params: { coupon: coupon_attributes }
  
      json = JSON.parse(response.body, symbolize_names: true)
  
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json[:error]).to eq("Code has already been taken")
    end

    it "should return an error if Merchant already has 5 active coupons" do
      merchant = create(:merchant)
      create_list(:coupon, 5, merchant_id: merchant.id, active: true)

      coupon6_attributes = attributes_for(:coupon, merchant: merchant, full_name: "A Mega-Spring Sale", code: "SPRING15")

      post "/api/v1/merchants/#{merchant.id}/coupons", params: { coupon: coupon6_attributes }
  
      json = JSON.parse(response.body, symbolize_names: true)
  
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json[:error]).to eq("This merchant already has 5 active coupons.")
    end

    it "should return an error if values exist for both discount types" do
      merchant = create(:merchant)
      coupon_attributes = attributes_for(:coupon, merchant: merchant, full_name: "A Mega-Spring Sale", code: "SPRING15", percent_off: 10, dollar_off: 12)

      post "/api/v1/merchants/#{merchant.id}/coupons", params: { coupon: coupon_attributes }
  
      json = JSON.parse(response.body, symbolize_names: true)
  
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json[:error]).to eq("only one discount type (percent or dollar off) can be specified at a time.")
    end
  end

  describe "Update a Coupon -- PATCH /api/v1/merchants/:merchant_id/coupon" do
    let(:merchant) { create(:merchant) }
    it "activates an inactive coupon" do
      coupon = create(:coupon, merchant: merchant, full_name: "Spring Sale", code: "SPRING10", active: false) 

      patch "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}", params:{ active: true}

      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_successful
      expect(json[:active]).to eq(true)
    end

    it "inactivates an active coupon" do
      coupon = create(:coupon, merchant: merchant, full_name: "Spring Sale", code: "SPRING10", active: true) 

      patch "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}", params:{ active: false}

      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_successful
      expect(json[:active]).to eq(false)
    end

    it "returns an error when the merchant already has 5 active coupons" do
      5.times { create(:coupon, merchant: merchant, active: true) }
      inactive_coupon = create(:coupon, merchant: merchant, active: false)
  
      patch "/api/v1/merchants/#{merchant.id}/coupons/#{inactive_coupon.id}", params:{ active: true}

      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to_not be_successful
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json[:errors][0]).to eq("This merchant already has 5 active coupons.")
    end

    it "returns an error if the coupon cannot be found" do
      coupon = create(:coupon, merchant: merchant, full_name: "Spring Sale", code: "SPRING10", active: true) 

      patch "/api/v1/merchants/#{merchant.id}/coupons/9999999999"
      
      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to_not be_successful
      expect(response).to have_http_status(:not_found)
      expect(json[:error]).to eq("Coupon not found")
    end
  end

  describe "Show a Coupon -- GET /api/v1/merchants/:merchant_id/coupons/:id" do
    it "returns merchant's coupon by coupon id" do
      merchant = create(:merchant)
      coupon = create(:coupon, merchant: merchant, full_name: "Spring Sale", code: "SPRING10")

      get "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}"

      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_successful
      expect(json[:data][:id]).to eq(coupon.id.to_s)
      expect(json[:data][:type]).to eq("coupon")
      expect(json[:data][:attributes][:full_name]).to eq("Spring Sale")
      expect(json[:data][:attributes][:code]).to eq("SPRING10")
      expect(json[:data][:attributes][:merchant_id]).to eq(merchant.id)
      expect(json[:data][:attributes][:usage_count]).to eq(coupon.invoices.count)
    end
  
    it "returns a 404 error if the coupon does not exist for the given merchant" do
      merchant = create(:merchant)
        
      get "/api/v1/merchants/#{merchant.id}/coupons/99999"

      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:not_found)
      expect(json[:error]).to eq("Coupon not found")
    end

    it "returns a 404 error if the merchant does not exist" do
      get "/api/v1/merchants/99999/coupons/1" 
      json = JSON.parse(response.body, symbolize_names: true) 
      
      expect(response).to have_http_status(:not_found) 
      expect(json[:error]).to eq("Coupon not found")
    end

    # it 'includes the correct usage_count' do
    #   merchant = create(:merchant)
    #   coupon = create(:coupon)
    #   customer = create(:customer)
  
    #   invoice1 = create(:invoice, customer_id: customer.id, merchant_id: merchant.id, coupon_id: coupon.id, status: "packaged")
    #   invoice2 = create(:invoice, customer_id: customer.id, merchant_id: merchant.id, coupon_id: coupon.id, status: "packaged")
  
    #   serialized = CouponSerializer.new(coupon).serializable_hash
  
    #   attributes = serialized[:data][:attributes]
  
    #   expect(attributes[:usage_count]).to eq(2)
    # end 
  end
  
end