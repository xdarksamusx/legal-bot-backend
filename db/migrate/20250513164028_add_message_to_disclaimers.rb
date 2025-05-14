class AddMessageToDisclaimers < ActiveRecord::Migration[8.0]
  def change
    add_column :disclaimers, :message, :string
  end
end
