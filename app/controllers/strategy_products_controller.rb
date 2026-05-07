class StrategyProductsController < ApplicationController
  before_action :set_strategy_product, only: %i[show edit update destroy]

  def index
    @strategy_products = current_user.strategy_products.order(created_at: :desc)
  end

  def show
  end

  def new
    @strategy_product = current_user.strategy_products.build
  end

  def create
    @strategy_product = current_user.strategy_products.build(strategy_product_params)
    if @strategy_product.save
      redirect_to @strategy_product
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @strategy_product.update(strategy_product_params)
      redirect_to @strategy_product
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @strategy_product.destroy
    redirect_to strategy_products_path
  end

  private

  def set_strategy_product
    @strategy_product = current_user.strategy_products.find(params[:id])
  end

  def strategy_product_params
    params.require(:strategy_product).permit(:name, :target_customer, :strategy, :primary_goal)
  end
end
