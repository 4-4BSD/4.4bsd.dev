# frozen_string_literal: true

class AddDeletedAtToPuffies < ActiveRecord::Migration[8.0]
  def change
    add_column :puffies, :deleted_at, :datetime
    add_index :puffies, :deleted_at
  end
end