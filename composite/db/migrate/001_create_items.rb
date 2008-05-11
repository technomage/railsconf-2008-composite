class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :items do |t|
      t.string :part
      t.integer :qty
      t.float :price
      t.timestamps
    end
  end

  def self.down
    drop_table :items
  end
end
