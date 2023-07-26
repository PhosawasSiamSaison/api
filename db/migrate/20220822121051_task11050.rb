class Task11050 < ActiveRecord::Migration[5.2]
  def up
    create_table :global_available_settings do |t|
      t.integer :contractor_type, limit: 2, null: false
      t.integer :category, limit: 2, null: false
      t.integer :dealer_type, limit: 2, null: false
      t.references :product, null: false
      t.boolean :available, null: false

      t.references :create_user, foreign_key: { to_table: :jv_users }, null: true, class: JvUser
      t.references :update_user, foreign_key: { to_table: :jv_users }, null: true, class: JvUser

      t.integer :deleted, limit: 1, default: 0
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0, null: false
    end

    add_index :global_available_settings, [:contractor_type, :category, :dealer_type, :product_id], unique: true, name: "ix_1"

    GlobalAvailableSetting.insert_category_data(insert_data)

    add_index :products, :product_key, unique: true
  end

  def down
    remove_index :products, :product_key

    drop_table :global_available_settings
  end

  private
    def insert_data
      {
        normal:     category_data(:normal),
        sub_dealer: category_data(:sub_dealer),
        individual: category_data(:individual),
        government: category_data(:government)
      }
    end

    def category_data(contractor_type)
      {
        purchase: {
          cbm:          { 1 => true,  4 =>  true, 5 => false, 2 =>  true, 3 =>  true, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          global_house: { 1 => true,  4 =>  true, 5 => false, 2 =>  true, 3 =>  true, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          transformer:  { 1 => true,  4 =>  true, 5 => false, 2 =>  true, 3 =>  true, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          cpac:         { 1 => true,  4 => false, 5 => false, 2 => false, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          q_mix:        { 1 => true,  4 => false, 5 => false, 2 => false, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          solution:     { 1 => true,  4 => false, 5 => false, 2 => false, 3 => false, 6 =>  true, 7 =>  true, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          b2b:          { 1 => true,  4 => false, 5 => false, 2 => false, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          nam:          { 1 => true,  4 =>  true, 5 => false, 2 =>  true, 3 =>  true, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          bigth:        { 1 => true,  4 =>  true, 5 => false, 2 =>  true, 3 =>  true, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          permsin:      { 1 => false, 4 => false, 5 => false, 2 => false, 3 => false, 6 => false, 7 => false, 8 =>  true, 11=>true,  9 => false, 10 => false, 12 => false },
          scgp:         { 1 => true,  4 => false, 5 => false, 2 => false, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 =>  true, 10 =>  true, 12 => false },
          rakmao:       { 1 => true,  4 => true,  5 => false, 2 =>  true, 3 => true,  6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          cotto:        { 1 => true,  4 => true,  5 => false, 2 =>  true, 3 => true,  6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
        },
        switch: {
          cbm:          { 1 => false, 4 =>  true, 5 => false, 2 =>  true, 3 =>  true, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          global_house: { 1 => false, 4 =>  true, 5 => false, 2 =>  true, 3 =>  true, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          transformer:  { 1 => false, 4 =>  true, 5 => false, 2 =>  true, 3 =>  true, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          cpac:         { 1 => false, 4 =>  true, 5 => false, 2 =>  true, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          q_mix:        { 1 => false, 4 =>  true, 5 => false, 2 =>  true, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          solution:     { 1 => false, 4 =>  true, 5 => false, 2 =>  true, 3 => false, 6 =>  true, 7 =>  true, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          b2b:          { 1 => false, 4 =>  true, 5 => false, 2 =>  true, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          nam:          { 1 => false, 4 =>  true, 5 => false, 2 =>  true, 3 =>  true, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          bigth:        { 1 => false, 4 => false, 5 => false, 2 => false, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          permsin:      { 1 => false, 4 => false, 5 => false, 2 => false, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          scgp:         { 1 => false, 4 => false, 5 => false, 2 => false, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          rakmao:       { 1 => false, 4 => false, 5 => false, 2 => false, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
          cotto:        { 1 => false, 4 => false, 5 => false, 2 => false, 3 => false, 6 => false, 7 => false, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false },
        },
        cashback: {
          cbm:          true,
          global_house: true,
          transformer:  true,
          cpac:        false,
          q_mix:       false,
          solution:    false,
          b2b:         false,
          nam:         false,
          bigth:       false,
          permsin:     false,
          scgp:        false,
          rakmao:      false,
          cotto:       false,
        }
      }
    end
end
