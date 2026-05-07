class AssumptionsController < ApplicationController
  def update
    @assumption = Assumption
      .joins(assumption_matrix: :strategy_product)
      .where(strategy_products: { user_id: current_user.id })
      .find(params[:id])

    if @assumption.update(assumption_params)
      render turbo_stream: [
        turbo_stream.update(
          "assumption_#{@assumption.id}_confidence",
          partial: "assumptions/confidence_rating",
          locals:  { assumption: @assumption }
        ),
        turbo_stream.update(
          "assumption_#{@assumption.id}_gap",
          partial: "assumptions/confidence_gap",
          locals:  { assumption: @assumption }
        )
      ]
    else
      head :unprocessable_entity
    end
  end

  private

  def assumption_params
    params.require(:assumption).permit(:confidence_user)
  end
end
