class AddChatHistoryToDisclaimers < ActiveRecord::Migration[8.0]
  def change
    add_column :disclaimers, :chat_history, :jsonb, default: [], null: false

 
  end
end
