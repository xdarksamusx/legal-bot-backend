class CreateDisclaimers < ActiveRecord::Migration[8.0]
  def change
    create_table :disclaimers do |t|
      t.timestamps
    end
  end
end
