class CreateRecipes < ActiveRecord::Migration[7.1]
  def change
    create_table :recipes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :choice
      t.integer :guests
      t.string :diet
      t.string :age_range
      t.string :cuisine
      t.string :duration
      t.string :difficulty
      t.text :equipments
      t.string :ingredient1
      t.string :ingredient2
      t.string :ingredient3
      t.string :ingredient4
      t.string :excluded1
      t.string :excluded2
      t.string :excluded3
      t.string :excluded4
      t.text :content

      t.timestamps
    end
  end
end
