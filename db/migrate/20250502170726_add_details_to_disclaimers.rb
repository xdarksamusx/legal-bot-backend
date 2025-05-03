class AddDetailsToDisclaimers < ActiveRecord::Migration[8.0]
  def change
    add_column :disclaimers, :statement, :string
    add_column :disclaimers, :tone, :string
    add_column :disclaimers, :topic, :string
  end
end
