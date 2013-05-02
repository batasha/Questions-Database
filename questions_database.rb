require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('quoro.db')

    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
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

    User.new(p QuestionsDatabase.instance.execute(query, fname, lname).first)
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

  def save
    if id.nil?
      insert
    else
      update
    end
  end

  private

  def insert
    query = <<-SQL
      INSERT INTO users ('fname', 'lname') VALUES (:fname, :lname)
    SQL

    QuestionsDatabase.instance.execute(query, {fname: fname, lname: lname})
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    query = <<-SQL
      UPDATE users
         SET 'fname' = :fname,'lname' = :lname
       WHERE id = :id
    SQL

    QuestionsDatabase.instance.execute(query, {fname: fname, lname: lname, id: id})
  end
end

class Question
  def self.find_by_id(id)
    query = <<-SQL
      SELECT *
        FROM questions
       WHERE id = ?
    SQL

    Question.new(QuestionsDatabase.instance.execute(query, id).first)

  end

  def self.find_by_title(title)
    query = <<-SQL
      SELECT *
        FROM questions
       WHERE title = ?
       LIMIT 1
    SQL

    Question.new(QuestionsDatabase.instance.execute(query, title).first)
  end

  def self.find_by_author_id(target_id)
    query = <<-SQL
      SELECT *
        FROM questions
       WHERE author_id = ?
    SQL

    QuestionsDatabase.instance.execute(query, target_id).map do |result|
      Question.new(result)
    end
  end

  def self.most_followed(n)
    QuestionFollower.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  attr_reader :id, :author_id
  attr_accessor :title, :body

  def initialize(options = {})
    options.each { |col, value| instance_variable_set("@" + col, value) }
  end

  def author
    User.find_by_id(author_id)
  end

  def replies
    Reply.find_by_question_id(id)
  end

  def followers
    QuestionFollower.followers_for_question_id(id)
  end

  def likers
    QuestionLike.likers_for_question_id(id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(id)
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end

  private

  def insert
    query = <<-SQL
      INSERT INTO questions ('title', 'body', 'author_id')
           VALUES (:title, :body, :author_id)
    SQL

    values = {title: title, body: body, author_id: author_id}
    QuestionsDatabase.instance.execute(query, values)
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    query = <<-SQL
      UPDATE questions
         SET 'title' = :title, 'body' = :body, 'author_id' = :author_id
       WHERE id = :id
    SQL

    values = {title: title, body: body, author_id: author_id, id: id}
    QuestionsDatabase.instance.execute(query, values)
  end
end

class Reply
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

  def save
    if id.nil?
      insert
    else
      update
    end
  end

  private

  def insert
    query = <<-SQL
      INSERT INTO replies ('body', 'subject_id', 'author_id', 'parent_id')
           VALUES (:body, :subject_id, :author_id, :parent_id)
    SQL

    values = {body: body, subject_id: subject_id, author_id: author_id, parent_id: parent_id}
    QuestionsDatabase.instance.execute(query, values)
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    query = <<-SQL
      UPDATE replies
         SET 'body' = :body, 'subject_id' = :subject_id,
             'author_id' = :author_id, 'parent_id' = :parent_id
       WHERE id = :id
    SQL

    values = {body: body, subject_id: subject_id, author_id: author_id,
              parent_id: parent_id, id: id}
    QuestionsDatabase.instance.execute(query, values)
  end
end

class QuestionFollower
  def self.followers_for_question_id(question_id)
    query = <<-SQL
      SELECT u.*
        FROM question_followers qf
        JOIN questions q
          ON qf.question_id = q.id
        JOIN users u
          ON qf.user_id = u.id
       WHERE q.id = ?
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
        JOIN users u
          ON qf.user_id = u.id
       WHERE u.id = ?
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
        JOIN questions q
          ON ql.question_id = q.id
        JOIN users u
          ON ql.user_id = u.id
       WHERE q.id = ?
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
        JOIN users u
          ON ql.user_id = u.id
       WHERE u.id = ?
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