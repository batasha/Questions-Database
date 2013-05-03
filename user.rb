require_relative 'questions_database'
require_relative 'save'

class User < Model
  include Saveable

  TABLE_NAME = "users"

  def table_name
    TABLE_NAME
  end

  def self.find_by_id(id)
    query = <<-SQL
      SELECT *
        FROM users
       WHERE id = ?
    SQL

    User.new(QuestionsDatabase.instance.execute(query, id).first)

  end

  def self.find_by_name(fname, lname)
    query = <<-SQL
      SELECT *
        FROM users
       WHERE fname = ?
         AND lname = ?
       LIMIT 1
    SQL

    User.new(QuestionsDatabase.instance.execute(query, fname, lname).first)
  end

  attr_reader :id
  attr_accessor :fname, :lname

  def initialize(options = {})
    options.each { |col, value| instance_variable_set("@" + col, value) }
  end

  def authored_questions
    Question.find_by_author_id(id)
  end

  def authored_replies
    Reply.find_by_user_id(id)
  end

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(id)
  end

  def average_karma
    query = <<-SQL
      SELECT AVG(num_likes)
        FROM (
              SELECT COUNT(ql.id) AS num_likes
                FROM question_likes ql
                JOIN questions q
                  ON ql.question_id = q.id
               WHERE q.author_id = ?
            GROUP BY q.id
            )
    SQL

    QuestionsDatabase.instance.execute(query, id).first.values.first
  end
end
