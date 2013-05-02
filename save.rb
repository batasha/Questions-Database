module Saveable

  def save
    if id.nil?
      insert(self.class::TABLE_NAME)
    else
      update(self.class::TABLE_NAME)
    end
  end

  private

  def insert(table_name)
    attrs = instance_variables_hash
    attrs.delete(:id)
    cols = attrs.keys.map { |var| "'#{var.to_s}'" }.join(", ")
    values = attrs.keys.map { |var| ":#{var.to_s}"}.join(", ")
    query = <<-SQL
      INSERT INTO #{table_name} (#{cols})
           VALUES (#{values})
    SQL

    QuestionsDatabase.instance.execute(query, attrs)
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update(table_name)
    attrs = instance_variables_hash

    updates = attrs.keys.map {|var| "'#{var}' = :#{var}" }.join(", ")
    query = <<-SQL
      UPDATE #{table_name}
         SET #{updates}
       WHERE id = :id
    SQL

    QuestionsDatabase.instance.execute(query, attrs)
  end
end