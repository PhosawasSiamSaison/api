# frozen_string_literal: true
# == Schema Information
#
# Table name: business_days
#
#  id                   :bigint(8)        not null, primary key
#  business_ymd         :string(8)        not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

require 'rails_helper'

RSpec.describe BusinessDay, type: :model do
  before do
    FactoryBot.create(:system_setting)
  end

  describe '#update_next_day' do
    before do
      FactoryBot.create(:business_day, business_ymd: '20190101')
    end

    it '日付が 20190102 に更新されること' do
      # 日次バッチを実行
      BusinessDay.update_next_day

      expect(BusinessDay.today_ymd).to eq '20190102'
    end
  end

  describe '#closing_day?' do
    let(:business_day) { FactoryBot.create(:business_day) }

    it '20190101 は締め日ではないこと' do
      business_day.update!(business_ymd: '20190101')
      expect(BusinessDay.closing_day?).to eq false
    end

    it '20190114 は締め日ではないこと' do
      business_day.update!(business_ymd: '20190114')
      expect(BusinessDay.closing_day?).to eq false
    end

    it '20190115 は締め日であること' do
      business_day.update!(business_ymd: '20190115')
      expect(BusinessDay.closing_day?).to eq true
    end

    it '20190131 は締め日であること' do
      business_day.update!(business_ymd: '20190131')
      expect(BusinessDay.closing_day?).to eq true
    end

    it '20190228 は締め日であること' do
      business_day.update!(business_ymd: '20190228')
      expect(BusinessDay.closing_day?).to eq true
    end
  end

  describe '#day_after_tomorrow_ymd' do
    before do
      FactoryBot.create(:business_day, business_ymd: '20190228')
    end

    it '2日後のymdが取得できること' do
      expect(BusinessDay.day_after_tomorrow_ymd).to eq '20190302'
    end
  end

  describe '#today_is' do
    before do
      FactoryBot.create(:business_day, business_ymd: '20190228')
    end

    it '正しいこと' do
      expect(BusinessDay.today_is(27)).to eq false
      expect(BusinessDay.today_is(28)).to eq true
      expect(BusinessDay.today_is(29)).to eq false

      BusinessDay.update!(business_ymd: '20190102')
      expect(BusinessDay.today_is(1)).to eq false
      expect(BusinessDay.today_is(2)).to eq true
      expect(BusinessDay.today_is(3)).to eq false
    end
  end

  describe '#three_business_days_ago' do
    it '正しいこと' do
      # チケット(9789)のサンプル
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200615'))).to eq Date.parse('20200610')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200331'))).to eq Date.parse('20200326')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200115'))).to eq Date.parse('20200110')

      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200430'))).to eq Date.parse('20200427')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200131'))).to eq Date.parse('20200128')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200229'))).to eq Date.parse('20200226')

      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200531'))).to eq Date.parse('20200527')

      # 未来日(全曜日を網羅)
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200630'))).to eq Date.parse('20200625')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200715'))).to eq Date.parse('20200710')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200731'))).to eq Date.parse('20200728')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200815'))).to eq Date.parse('20200812')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200831'))).to eq Date.parse('20200826')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200915'))).to eq Date.parse('20200910')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20200930'))).to eq Date.parse('20200925')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20201015'))).to eq Date.parse('20201012')
      expect(BusinessDay.new.three_business_days_ago(Date.parse('20201115'))).to eq Date.parse('20201111')
    end
  end

  describe '#three_business_days_later' do
    it '正しいこと' do
      # 全ての曜日
      expect(BusinessDay.new.three_business_days_later(Date.parse('20211101'))).to eq Date.parse('20211104')
      expect(BusinessDay.new.three_business_days_later(Date.parse('20211102'))).to eq Date.parse('20211105')
      expect(BusinessDay.new.three_business_days_later(Date.parse('20211103'))).to eq Date.parse('20211108')
      expect(BusinessDay.new.three_business_days_later(Date.parse('20211104'))).to eq Date.parse('20211109')
      expect(BusinessDay.new.three_business_days_later(Date.parse('20211105'))).to eq Date.parse('20211110')
      expect(BusinessDay.new.three_business_days_later(Date.parse('20211106'))).to eq Date.parse('20211110')
      expect(BusinessDay.new.three_business_days_later(Date.parse('20211107'))).to eq Date.parse('20211110')
    end
  end

  describe '#prev_due_ymd' do
    before do
      FactoryBot.create(:business_day, business_ymd: '')
    end

    it '正しいこと' do
      BusinessDay.update!(business_ymd: '20210601')
      expect(BusinessDay.prev_due_ymd()).to eq '20210531'

      BusinessDay.update!(business_ymd: '20210615')
      expect(BusinessDay.prev_due_ymd()).to eq '20210531'

      BusinessDay.update!(business_ymd: '20210616')
      expect(BusinessDay.prev_due_ymd()).to eq '20210615'

      BusinessDay.update!(business_ymd: '20210630')
      expect(BusinessDay.prev_due_ymd()).to eq '20210615'
    end
  end

  describe '#in_enable_payment' do
    it '可能判定' do
      # 月末 DueDate
      expect(BusinessDay.create(business_ymd: '20220701').in_enable_payment('20220731')).to eq true
      expect(BusinessDay.create(business_ymd: '20220731').in_enable_payment('20220731')).to eq true

      # 15日 DueDate
      expect(BusinessDay.create(business_ymd: '20220716').in_enable_payment('20220815')).to eq true
      expect(BusinessDay.create(business_ymd: '20220815').in_enable_payment('20220815')).to eq true
    end

    it '不可能判定' do
      # 月末 DueDate
      expect(BusinessDay.create(business_ymd: '20220630').in_enable_payment('20220731')).to eq false

      # 15日 DueDate
      expect(BusinessDay.create(business_ymd: '20220715').in_enable_payment('20220815')).to eq false

      # 年越しの判定
      expect(BusinessDay.create(business_ymd: '20221220').in_enable_payment('20230130')).to eq false
    end
  end

  describe '#allowed_to_input_date?(purchase_ymd)' do
    it '可能判定' do
      # 月が同じ
      expect(BusinessDay.create(business_ymd: '20220701').allowed_to_input_date?('20220701')).to eq true
      expect(BusinessDay.create(business_ymd: '20220731').allowed_to_input_date?('20220701')).to eq true

      # 先月の日が今日の日以上
      expect(BusinessDay.create(business_ymd: '20220715').allowed_to_input_date?('20220615')).to eq true
      expect(BusinessDay.create(business_ymd: '20220715').allowed_to_input_date?('20220630')).to eq true

      # 年を跨いでいる
      expect(BusinessDay.create(business_ymd: '20220115').allowed_to_input_date?('20211215')).to eq true
    end

    it '不可能判定' do
      # ２ヶ月前
      expect(BusinessDay.create(business_ymd: '20220715').allowed_to_input_date?('20220515')).to eq false

      # 先月だが日が古い
      expect(BusinessDay.create(business_ymd: '20220715').allowed_to_input_date?('20220614')).to eq false
      expect(BusinessDay.create(business_ymd: '20220731').allowed_to_input_date?('20220630')).to eq false

      # 同じ月だが年違い
      expect(BusinessDay.create(business_ymd: '20220715').allowed_to_input_date?('20210715')).to eq false
      expect(BusinessDay.create(business_ymd: '20220715').allowed_to_input_date?('20210615')).to eq false

      # 業務日より先
      expect(BusinessDay.create(business_ymd: '20220715').allowed_to_input_date?('20220716')).to eq false
    end
  end
end
