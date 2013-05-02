require_relative 'questions_database'
require_relative 'save'

class Reply
  include Saveable

  TABLE_NAME = "replies"

  def self.find_by_id(id)
    query = <<-SQL
      SELECT *
        FROM replies
       WHERE id = ?
    SQL

    Reply.new(QuestionsDatabase.instance.execute(query, id).first)
  end

  def self.find_by_question_id(target_id)
    query = <<-SQL
      SELECT *
        FROM replies
       WHERE subject_id = ?
    SQL

    QuestionsDatabase.instance.execute(query, target_id).map do |result|
      Reply.new(result)
    end
  end

  def self.find_by_user_id(target_id)
    query = <<-SQL
      SELECT *
        FROM replies
       WHERE author_id = ?
    SQL

    QuestionsDatabase.instance.execute(query, target_id).map do |result|
      Reply.new(result)
    end
  end

  attr_reader :id, :author_id, :subject_id, :parent_id
  attr_accessor :body

  def initialize(options = {})
    options.each { |col, value| instance_variable_set("@" + col, value) }
  end

  def author
    User.find_by_id(author_id)
  end

  def question
    Reply.find_by_question_id(subject_id)
  end

  def parent_reply
    Reply.find_by_id(parent_id)
  end

  def child_replies
    query = <<-SQL
      SELECT *
        FROM replies
       WHERE parent_id = ?
    SQL

    QuestionsDatabase.instance.execute(query, id).map do |result|
      Reply.new(result)
    end
  end
end
