# frozen_string_literal: true

class AddOwnerColumnToPuffies < ActiveRecord::Migration[8.0]
  def change
    add_column :puffies, :owner, :string
  end
end
