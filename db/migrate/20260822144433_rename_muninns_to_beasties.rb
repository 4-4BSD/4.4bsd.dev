# frozen_string_literal: true

class RenameMuninnsToBeasties < ActiveRecord::Migration[8.0]
  def change
    rename_table :muninns, :beasties
  end
end