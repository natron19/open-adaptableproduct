class AssumptionMatricesController < ApplicationController
  before_action :set_strategy_product

  rate_limit to: 10, within: 1.minute, only: :create, by: -> { current_user.id }

  def show
    @matrix = @strategy_product.assumption_matrices.find(params[:id])
  end

  def create
    raw = GeminiService.generate(
      template:  "adaptableproduct_assumptions_v1",
      variables: {
        product_name:    @strategy_product.name,
        target_customer: @strategy_product.target_customer,
        strategy:        @strategy_product.strategy,
        primary_goal:    @strategy_product.primary_goal
      }
    )

    @matrix = @strategy_product.assumption_matrices.create!(
      status:       "pending",
      gemini_raw:   raw,
      generated_at: Time.current
    )

    entries = parse_assumptions!(raw)

    entries.each_with_index do |entry, i|
      @matrix.assumptions.create!(
        statement:     entry["statement"],
        confidence_ai: entry["confidence_ai"].to_i,
        risk:          entry["risk"],
        category:      entry["category"],
        experiment:    entry["experiment"],
        position:      i + 1
      )
    end

    @matrix.update!(status: "completed")
    redirect_to strategy_product_assumption_matrix_path(@strategy_product, @matrix)

  rescue ParseError => e
    @matrix.update!(status: "failed", gemini_raw: e.raw)
    redirect_to strategy_product_path(@strategy_product)

  rescue GeminiService::BudgetExceededError
    render partial: "shared/ai_error", locals: { error_type: :budget_exceeded }

  rescue GeminiService::GatekeeperError
    render partial: "shared/ai_error", locals: { error_type: :gatekeeper_blocked }

  rescue GeminiService::TimeoutError
    render partial: "shared/ai_error", locals: { error_type: :timeout }

  rescue GeminiService::GeminiError
    render partial: "shared/ai_error", locals: { error_type: :error }
  end

  private

  def set_strategy_product
    @strategy_product = current_user.strategy_products.find(params[:strategy_product_id])
  end

  ParseError = Class.new(StandardError) do
    attr_reader :raw
    def initialize(msg, raw:)
      super(msg)
      @raw = raw
    end
  end

  def parse_assumptions!(raw)
    stripped = raw.gsub(/\A```json\s*|\s*```\z/, "").strip
    parsed   = JSON.parse(stripped)
    entries  = parsed["assumptions"]

    unless entries.is_a?(Array) && entries.size.between?(8, 12)
      raise ParseError.new("Expected 8-12 assumptions, got #{entries&.size}", raw: raw)
    end

    valid_risks      = Assumption::RISKS
    valid_categories = Assumption::CATEGORIES
    required_keys    = %w[statement confidence_ai risk category experiment]

    entries.each do |entry|
      missing = required_keys - entry.keys
      raise ParseError.new("Missing keys: #{missing.join(', ')}", raw: raw) if missing.any?

      unless (1..5).cover?(entry["confidence_ai"].to_i)
        raise ParseError.new("confidence_ai out of range: #{entry['confidence_ai']}", raw: raw)
      end
      unless valid_risks.include?(entry["risk"])
        raise ParseError.new("Invalid risk: #{entry['risk']}", raw: raw)
      end
      unless valid_categories.include?(entry["category"])
        raise ParseError.new("Invalid category: #{entry['category']}", raw: raw)
      end
    end

    entries
  rescue JSON::ParserError => e
    raise ParseError.new("JSON parse failed: #{e.message}", raw: raw)
  end
end
