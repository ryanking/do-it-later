ActiveRecord::Schema.define(:version => 0) do
  create_table :things, :force => true do |t|
    t.column :name, :string
    t.column :thinginess, :integer
  end
end
