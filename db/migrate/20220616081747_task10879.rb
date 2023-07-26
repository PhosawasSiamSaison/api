class Task10879 < ActiveRecord::Migration[5.2]
  def up
    add_column :dealers, :for_individual_rate, :decimal, precision: 5, scale: 2, default: 1.5,
      null: false, after: :for_sub_dealer_rate, comment: 'for Transaction Fee'

    add_column :contractors, :contractor_type, :integer, limit: 1,
      null: false, default: 1, after: :tax_id

    Contractor.all.each do |contractor|
      if contractor.sub_dealer
        contractor.sub_dealer!
      elsif contractor.tax_id.slice(0,2) == '10'
        contractor.government!
      end
    end

    remove_column :contractors, :sub_dealer, :boolean
  end

  def down
    add_column :contractors, :sub_dealer, :boolean, null: false, default: false, after: :tax_id

    Contractor.all.each do |contractor|
      if contractor.sub_dealer?
        contractor.update!(sub_dealer: true)
      end
    end

    remove_column :contractors, :contractor_type
    remove_column :dealers, :for_individual_rate
  end
end
