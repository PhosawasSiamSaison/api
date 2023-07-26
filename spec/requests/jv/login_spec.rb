require 'swagger_helper'

RSpec.describe 'jv/login', type: :request do

  path '/api/jv/login/login' do

    post('login login') do
      response(200, 'successful') do
        consumes 'application/json'        
        parameter in: :body, schema: {          
        type: :object,          
        properties: {            
          user_name: { type: :string },            
          password: { type: :string }          
        }
        }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
