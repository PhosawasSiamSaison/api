# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendMail, type: :model do
  let(:contractor) { FactoryBot.create(:contractor) }

  before do
    FactoryBot.create(:business_day)
  end

  it 'send_online_apply_one_time_passcode' do
    email = 'test@test.com'
    passcode = '123456'
    applicant_name = 'tester1'

    SendMail.send_online_apply_one_time_passcode(email, passcode, applicant_name)

    mail_spool = MailSpool.first
    expect(mail_spool.mail_type).to eq 'online_apply_one_time_passcode_mail'
    expect(mail_spool.contractor_users.count).to eq 0
  end

  it 'approve_contractor' do
    SendMail.approve_contractor(contractor)

    mail_spool = MailSpool.first
    expect(mail_spool.mail_type).to eq 'approve_contractor'
    expect(mail_spool.contractor).to eq contractor
    expect(mail_spool.contractor_users.count).to eq 0
  end

  it 'reject_contractor' do
    SendMail.reject_contractor(contractor)

    mail_spool = MailSpool.first
    expect(mail_spool.mail_type).to eq 'reject_contractor'
    expect(mail_spool.contractor).to eq contractor
    expect(mail_spool.contractor_users.count).to eq 0
  end

  it 'scoring_results_notification_to_ss_staffs' do
    JvService::Application.config.ss_staffs_email_address = 'test@test.com'

    approval = true

    SendMail.scoring_results_notification_to_ss_staffs(contractor, approval)

    mail_spool = MailSpool.first
    expect(mail_spool.mail_type).to eq 'scoring_results_to_staff'
    expect(mail_spool.contractor).to eq nil
    expect(mail_spool.contractor_users.count).to eq 0
  end

  it 'pdpa_agree' do
    contractor_user = FactoryBot.create(:contractor_user, contractor: contractor, email: 'test@test.com')

    SendMail.pdpa_agree(contractor_user)

    mail_spool = MailSpool.first
    expect(mail_spool.mail_type).to eq 'pdpa_agree'
    expect(mail_spool.contractor).to eq contractor
    expect(mail_spool.contractor_users.first).to eq contractor_user
  end

  it 'online_apply_complete' do
    SendMail.online_apply_complete(contractor)

    mail_spool = MailSpool.first
    expect(mail_spool.mail_type).to eq 'online_apply_complete'
    expect(mail_spool.contractor).to eq contractor
    expect(mail_spool.contractor_users.count).to eq 0
  end

  it 'receive_payment' do
    contractor_user = FactoryBot.create(:contractor_user, contractor: contractor, email: 'test@test.com')

    payment_ymd = '20221031'
    payment_amount = 100

    SendMail.receive_payment(contractor, payment_ymd, payment_amount)

    mail_spool = MailSpool.first
    expect(mail_spool.mail_type).to eq 'receive_payment'
    expect(mail_spool.contractor).to eq contractor
    expect(mail_spool.contractor_users.count).to eq 1
  end

  it 'exceeded_payment' do
    contractor_user = FactoryBot.create(:contractor_user, contractor: contractor, email: 'test@test.com')

    receive_amount_history = FactoryBot.create(:receive_amount_history, contractor: contractor)
    FactoryBot.create(:receive_amount_detail, contractor: contractor, receive_amount_history: receive_amount_history)

    SendMail.exceeded_payment(contractor, receive_amount_history)

    mail_spool = MailSpool.first
    expect(mail_spool.mail_type).to eq 'exceeded_payment'
    expect(mail_spool.contractor).to eq nil
    expect(mail_spool.contractor_users.count).to eq 0
  end
end
