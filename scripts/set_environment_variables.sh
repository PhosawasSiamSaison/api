#!/bin/bash
function set_parameter {
  SSM_PARAM_NAME=$1
  SSM_VALUE=`aws ssm get-parameters --name "${SSM_PARAM_NAME}" --query 'Parameters[*].Value' --output text`
  [ "$(eval echo "$"$1)" == "" ] && echo "export ${SSM_PARAM_NAME}=${SSM_VALUE}" >> ~/.bash_profile
}
# echo "export RAILS_ENV=staging" >> ~/.bashrc
set_parameter "JV_DB_HOST"
set_parameter "JV_DB_NAME"
set_parameter "JV_DB_PASS"
set_parameter "JV_DB_POOL"
set_parameter "JV_DB_USER"
set_parameter "JV_THAIBULK_API_KEY"
set_parameter "JV_THAIBULK_API_SECRET"
set_parameter "MAIL_PASSWORD"
set_parameter "MAIL_PASSWORD_PDPA"
set_parameter "MAIL_USER_NAME"
set_parameter "MAIL_USER_NAME_PDPA"
set_parameter "MASK_MAIL_ADDRESS"
set_parameter "MASK_MAIL_PASSWORD"
set_parameter "RACK_ENV"
set_parameter "RAILS_ENV"
set_parameter "SECRET_KEY_BASE"
set_parameter "MASK_MOBILE_NUMBER"
