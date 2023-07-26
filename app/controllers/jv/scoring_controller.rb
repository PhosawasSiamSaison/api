# frozen_string_literal: true

class Jv::ScoringController < ApplicationController
  before_action :auth_user

  # Actual Score
  def current_eligibility
    contractor = Contractor.find(params[:contractor_id])

    eligibility = {
      limit_amount: contractor.credit_limit_amount,
      class_type: contractor.class_type_label,
    }

    render json: { success: true, eligibility: eligibility }
  end

  # Scoring
  def execute_scoring
    # スコアリングの実行
    error, scoring_result = Scoring.new(params[:contractor_id]).exec

    if error
      render json: { success: false, error: error }
    else
      render json: { success: true, scoring_result: scoring_result_format(scoring_result) }
    end
  end

  def scoring_result
    contractor = Contractor.find(params[:contractor_id])

    scoring_result = contractor.scoring_results.order(created_at: :desc).first

    scoring_result = ScoringResult.new unless scoring_result

    render json: {
      success: true,
      scoring_result: scoring_result_format(scoring_result)
    }
  end

  # Comment
  def comments
    contractor = Contractor.find(params[:contractor_id])

    comments = contractor.scoring_comments.includes(:create_user)
    .order(created_at: :DESC).map do |scoring_comment|
      {
        id: scoring_comment.id,
        comment: scoring_comment.comment,
        create_user_name: scoring_comment.create_user_name,
        created_at: scoring_comment.created_at
      }
    end

    render json: { success: true, comments: comments }
  end

  def create_comment
    contractor = Contractor.find(params[:contractor_id])

    scoring_comment = contractor.scoring_comments.new(
      comment: params[:comment],
      create_user: login_user
    )

    if scoring_comment.save
      render json: { success: true }
    else
      render json: { success: false, errors: scoring_comment.error_messages }
    end
  end

  private

  def scoring_result_format(scoring_result)
    {
      basic_info: {
        years_in_business: {
          value: scoring_result.years_in_business,
          score: scoring_result.years_in_business_score,
        },
        register_capital: {
          value: scoring_result.register_capital,
          score: scoring_result.register_capital_score,
        },
        shareholders_equity: {
          value: scoring_result.shareholders_equity,
          score: scoring_result.shareholders_equity_score,
        },
        total_revenue: {
          value: scoring_result.total_revenue,
          score: scoring_result.total_revenue_score,
        },
        net_revenue: {
          value: scoring_result.net_revenue,
          score: scoring_result.net_revenue_score,
        },
        current_ratio: {
          value: scoring_result.current_ratio,
          score: scoring_result.current_ratio_score,
        },
        de_ratio: {
          value: scoring_result.de_ratio,
          score: scoring_result.de_ratio_score,
        },
      },

      total_score: scoring_result.total_score,

      class_type: scoring_result.class_type_label,
      credit_limit_amount: scoring_result.limit_amount&.to_f,

      created_at: scoring_result.created_at
    }
  end

  def transaction_information_format(transaction_information)
    transactions = transaction_information[:transactions].map {|transaction|
      {
        year:                 transaction[:year],
        peak_amount:          transaction[:peak_amount].to_f,
        avg_per_month_amount: transaction[:avg_per_month_amount].to_f,
        avg_overdue:          transaction[:avg_overdue].to_f,
      }
    }

    projects = transaction_information[:projects].map {|project|
      {
        score:            project[:score],
        project_name:     project[:project_name],
        project_value:    project[:project_value].to_f,
        project_type:     project[:project_type],
        project_progress: project[:project_progress].to_f,
      }
    }

    score_infomation = transaction_information[:score_infomation]
    formatted_score_infomation = {
      class:                 score_infomation[:class],
      score:                 score_infomation[:score].to_f,
      no_of_on_hand:         score_infomation[:no_of_on_hand].to_f,
      valuer_and_type:       score_infomation[:valuer_and_type].to_f,
      contract_per_site:     score_infomation[:contract_per_site].to_f,
      no_of_work_be_on_time: score_infomation[:no_of_work_be_on_time].to_f,
    }

    formatted_transaction_information = {
      dealer_code:      transaction_information[:dealer_code],
      credit_term:      transaction_information[:credit_term].to_f,
      credit_limit:     transaction_information[:credit_limit].to_f,
      transactions:     transactions,
      projects:         projects,
      score_infomation: formatted_score_infomation,
      dealer_name:      transaction_information[:dealer_name],
    }
  end

  def avg_dealer
    {
      id: 'all',
      dealer_code: 'all',
      dealer_name: "All(Avg)",
    }
  end
end