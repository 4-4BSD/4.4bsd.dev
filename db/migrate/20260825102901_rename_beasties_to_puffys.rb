# frozen_string_literal: true

class RenameBeastiesToPuffys < ActiveRecord::Migration[8.0]
  def change
    rename_table :beasties, :puffys
  end
end