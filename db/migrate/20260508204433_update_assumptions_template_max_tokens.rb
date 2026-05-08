class UpdateAssumptionsTemplateMaxTokens < ActiveRecord::Migration[8.1]
  def up
    AiTemplate.find_by(name: "adaptableproduct_assumptions_v1")
              &.update!(max_output_tokens: 8192)
  end

  def down
    AiTemplate.find_by(name: "adaptableproduct_assumptions_v1")
              &.update!(max_output_tokens: 2500)
  end
end
