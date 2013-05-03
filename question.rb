require_relative 'questions_database'
require_relative 'save'
require_relative 'model'

class Question < Model
  #include Saveable

  TABLE_NAME = "questions"

  def self.table_name
    TABLE_NAME
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
end
