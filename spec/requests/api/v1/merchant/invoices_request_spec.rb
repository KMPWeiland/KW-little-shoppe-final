require "rails_helper"

RSpec.describe "Merchant invoices endpoints" do
  before :each do
    @merchant2 = Merchant.create!(name: "Merchant")
    @merchant1 = Merchant.create!(name: "Merchant Again")
    @merchant3 = Merchant.create!(name: "Another Merchant")

    @customer1 = Customer.create!(first_name: "Papa", last_name: "Gino")
    @customer2 = Customer.create!(first_name: "Jimmy", last_name: "John")
    @customer3 = Customer.create!(first_name: "Jack", last_name: "Fey")

    @coupon1 = Coupon.create(merchant: @merchant1, code: "UNIQUECODE")

    @invoice1 = Invoice.create!(customer: @customer1, merchant: @merchant1, status: "packaged")
    Invoice.create!(customer: @customer1, merchant: @merchant1, status: "shipped")
    Invoice.create!(customer: @customer1, merchant: @merchant1, status: "shipped")
    Invoice.create!(customer: @customer1, merchant: @merchant1, status: "shipped")
    @invoice2 = Invoice.create!(customer: @customer1, merchant: @merchant2, status: "shipped")

    @invoice3 = Invoice.create!(customer: @customer3, merchant: @merchant3, status: "shipped", coupon_id: @coupon1.id)
    @invoice4 = Invoice.create!(customer: @customer3, merchant: @merchant3, status: "shipped", coupon_id: nil)
  end

  it "should return all invoices for a given merchant based on status param" do
    get "/api/v1/merchants/#{@merchant1.id}/invoices?status=packaged"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(1)
    expect(json[:data][0][:id]).to eq(@invoice1.id.to_s)
    expect(json[:data][0][:type]).to eq("invoice")
    expect(json[:data][0][:attributes][:customer_id]).to eq(@customer1.id)
    expect(json[:data][0][:attributes][:merchant_id]).to eq(@merchant1.id)
    expect(json[:data][0][:attributes][:status]).to eq("packaged")
  end

  it "should get multiple invoices if they exist for a given merchant and status param" do
    get "/api/v1/merchants/#{@merchant1.id}/invoices?status=shipped"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(3)
  end

  it "should only get invoices for merchant given" do
    get "/api/v1/merchants/#{@merchant2.id}/invoices?status=shipped"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(1)
    expect(json[:data][0][:id]).to eq(@invoice2.id.to_s)
  end

  it "should only get invoices for merchant given and include coupon_id if used" do
    get "/api/v1/merchants/#{@merchant3.id}/invoices?status=shipped"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(2)
    expect(json[:data][0][:coupon_id]).to eq(@coupon1.id)
    expect(json[:data][1][:coupon_id]).to eq(nil)
  end

  it "should return 404 and error message when merchant is not found" do
    get "/api/v1/merchants/100000/customers"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to have_http_status(:not_found)
    expect(json[:message]).to eq("Your query could not be completed")
    expect(json[:errors]).to be_a Array
    expect(json[:errors].first).to eq("Couldn't find Merchant with 'id'=100000")
  end
end