class ChangeUserIdToBeNullableInDisclaimers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :disclaimers, :user_id, true

  end
end
