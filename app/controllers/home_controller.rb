class HomeController < ShopifyApp::AuthenticatedController
  def index
    @products = ShopifyAPI::Product.find(:all, params: { limit: 10 })
    @wishlist = WishlistItem.getUniqueProductsByStore(params[:shop])
    puts @wishlist
  end
end
