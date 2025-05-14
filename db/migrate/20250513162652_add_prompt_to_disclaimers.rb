class AddPromptToDisclaimers < ActiveRecord::Migration[8.0]
  def change
    add_column :disclaimers, :prompt, :string
  end
end
