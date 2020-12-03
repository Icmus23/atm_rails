class CreateAtms < ActiveRecord::Migration[6.0]
  def change
    create_table :atms do |t|
      t.json :banknotes, default: {}
      t.integer :total, default: 0

      t.timestamps
    end
  end
end
