require 'singleton'
require 'sqlite3'

# class Object
#   def instance_variables_hash
#     Hash[instance_variables.map { |name| [name.to_s[1..-1].to_sym, instance_variable_get(name)] }]
#   end
# end

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('quoro.db')

    self.results_as_hash = true
    self.type_translation = true
  end
end


class QuestionFollower
  def self.followers_for_question_id(question_id)
    query = <<-SQL
      SELECT u.*
        FROM question_followers qf
        JOIN users u
          ON qf.user_id = u.id
       WHERE qf.question_id = ?
    SQL

    QuestionsDatabase.instance.execute(query, question_id).map do |result|
      User.new(result)
    end
  end

  def self.followed_questions_for_user_id(user_id)
    query = <<-SQL
      SELECT q.*
        FROM question_followers qf
        JOIN questions q
          ON qf.question_id = q.id
       WHERE qf.user_id = ?
    SQL

    QuestionsDatabase.instance.execute(query, user_id).map do |result|
      Question.new(result)
    end
  end

  def self.most_followed_questions(n)
    query = <<-SQL
        SELECT q.*
          FROM question_followers qf
          JOIN questions q
            ON qf.question_id = q.id
      GROUP BY q.id
      ORDER BY COUNT(qf.id) DESC
         LIMIT ?
    SQL

    QuestionsDatabase.instance.execute(query, n).map do |result|
      Question.new(result)
    end
  end
end

class QuestionLike
  def self.likers_for_question_id(question_id)
    query = <<-SQL
      SELECT u.*
        FROM question_likes ql
        JOIN users u
          ON ql.user_id = u.id
       WHERE ql.question_id = ?
    SQL

    QuestionsDatabase.instance.execute(query, question_id).map do |result|
      User.new(result)
    end
  end

  def self.num_likes_for_question_id(question_id)
    query = <<-SQL
      SELECT COUNT(user_id)
        FROM question_likes
       WHERE question_id = ?
    SQL

    QuestionsDatabase.instance.execute(query, question_id).first.values.first
  end

  def self.liked_questions_for_user_id(user_id)
    query = <<-SQL
      SELECT q.*
        FROM question_likes ql
        JOIN questions q
          ON ql.question_id = q.id
       WHERE ql.user_id = ?
    SQL

    QuestionsDatabase.instance.execute(query, user_id).map do |result|
      Question.new(result)
    end
  end

  def self.most_liked_questions(n)
    query = <<-SQL
        SELECT q.*
          FROM question_likes ql
          JOIN questions q
            ON ql.question_id = q.id
      GROUP BY q.id
      ORDER BY COUNT(ql.id) DESC
         LIMIT ?
    SQL

    QuestionsDatabase.instance.execute(query, n).map do |result|
      Question.new(result)
    end
  end
end