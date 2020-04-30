class CreateHistoryRecords < ActiveRecord::Migration[6.0]
  def change
    create_table :history_records do |t|
      t.json :request_dump

      t.timestamps
    end
  end
end
