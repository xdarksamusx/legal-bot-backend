class ChangeMessageToJsonInDisclaimers < ActiveRecord::Migration[8.0]
  def change
    remove_column :disclaimers, :message, :string 
    add_column :disclaimers, :message, :jsonb, default: {}, null: false
  end
end
