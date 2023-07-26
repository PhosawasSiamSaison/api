# frozen_string_literal: true

class CommonController < ApplicationController
  before_action :auth_user, except: :account_link_image

  def check_auth
    # エラーにならなければOK
    render json: { success: true }
  end

  def business_ymd
    render json: {
      success: true,
      business_ymd: BusinessDay.today_ymd
    }
  end

  def types
    response = { success: true }

    if params[:all].present?
      I18n.t('enum').map {|model_sym, enums|
        enums.each {|enum_sym, enum|
          key = "#{model_sym.to_s}.#{enum_sym.to_s}"

          response[key] = enum.map {|key, value|
            {
              code: key,
              label: value
            }
          }
        }
      }

      return render json: response
    end

    # 複数
    if params[:types].present?
      response = { success: true }

      params[:types].each do |type|
        # モデル名とenum名を取得
        model_str, enum_str = type.split('.')
        # モデル化
        model = model_str.classify.constantize

        response[type] = model.labels(enum_str)
      end

      return render json: response
    end


    # 単体
    enum_path = params[:type]

    # モデル名とenum名を取得
    model_str, enum_str = enum_path.split('.')
    # モデル化
    model = model_str.classify.constantize

    render json: { success: true, types: model.labels(enum_str) }
  end

  # LINEから呼ばれるアカウント連携のテンプレートメッセージの画像
  def account_link_image
    send_file('lib/images/banner-Line.jpg')
  end

  # เพื่อการพัฒนา
  def proc_business_day
    to_ymd = params[:to_ymd].presence || BusinessDay.tomorrow_ymd

    Batch::Daily.exec(to_ymd: to_ymd)

    render json: { success: true }
  end
end
