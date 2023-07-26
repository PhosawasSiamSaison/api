class Task9994 < ActiveRecord::Migration[5.2]
  def change
    add_reference :installments, :contractor, foreign_key: true, after: :id
    add_reference :installment_histories, :contractor, foreign_key: true, after: :id
    add_reference :installment_histories, :payment, foreign_key: true, after: :installment_id
    add_reference :installment_histories, :order, foreign_key: true, after: :contractor_id
  end
end
