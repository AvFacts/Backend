class CreateJWTDenylists < ActiveRecord::Migration[6.0]
  def change
    create_table :jwt_denylist do |t|
      t.string :jti, null: false
      t.timestamps
    end

    add_index :jwt_denylist, :jti, unique: true
    add_index :jwt_denylist, :created_at
  end
end
