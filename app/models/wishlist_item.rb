class WishlistItem < ApplicationRecord
	validates :email, :domain_name, :name, :productid, :price, presence: true
	validates_uniqueness_of :email, :scope => [:domain_name, :productid]

	after_commit :maybe_notify_merchant

	class << self
		def getUniqueProductsByStore(domainName)
			items = WishlistItem.where(domain_name: domainName).map(&:productid).uniq
			results = {}
			items.each do |item|
				count = WishlistItem.where(productid: item).count
				averageWishPrices = WishlistItem.where(productid:item).average(:price)
				results[item] = {
					'count': count,
					'averageWishPrices': averageWishPrices
				}
			end
			results
		end
	end

	private
	def maybe_notify_merchant
		# Notify merchant if at least X people have requested the price to be changed
		subscribers_for_product = WishlistItem.where(domain_name: self.domain_name, productid: self.productid)
		if subscribers_for_product.count > 5
			average_price = subscribers_for_product.average(:price)
			count = subscribers_for_product.count
			shop_info = Shop.where(shopify_domain: self.domain_name).first
			session = ShopifyAPI::Session.new(shop_info.shopify_domain, shop_info.shopify_token)
			ShopifyAPI::Base.activate_session(session)
			shop = ShopifyAPI::Shop.current
			product = ShopifyAPI::Product.find(self.productid)
			MerchantMailer.email(shop, product, count, average_price).deliver_now
		end
	end
end
